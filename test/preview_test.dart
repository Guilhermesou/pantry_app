import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa/main.dart';
import 'package:despensa/models.dart';
import 'package:despensa/store.dart';
import 'package:despensa/services.dart';
import 'package:despensa/screens/capture.dart';
import 'package:despensa/screens/settings.dart';
import 'package:despensa/screens/lots.dart';
import 'store_test.dart' show MemoryRepository;

/// Loads the bundled Inter and Material Symbols so captures match the app.
Future<void> loadAppFonts() async {
  for (final (family, assets) in [
    (
      'Inter',
      [
        'assets/fonts/Inter-Regular.ttf',
        'assets/fonts/Inter-Medium.ttf',
        'assets/fonts/Inter-SemiBold.ttf',
        'assets/fonts/Inter-Bold.ttf',
      ],
    ),
    ('MaterialSymbolsRounded', ['assets/fonts/MaterialSymbolsRounded.ttf']),
    ('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']),
  ]) {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}

/// The sample household used by the design prototype.
AppData designData() {
  final today = calendarDate(DateTime.now());
  return AppData(
    onboarded: true,
    demo: true,
    budget: 600,
    products: [
      Product(
        id: 'rice',
        name: 'Arroz integral',
        brand: 'Tio João',
        pack: '1 kg',
        closed: 2,
        opened: [.5],
        minimum: 2,
        lastPrice: 8.9,
      ),
      Product(
        id: 'coffee',
        name: 'Café moído',
        pack: '250 g',
        opened: [.25],
        minimum: 1,
        lastPrice: 18.9,
      ),
      Product(
        id: 'milk',
        name: 'Leite integral',
        pack: '1 L',
        category: 'Bebidas',
        location: 'Geladeira',
        closed: 1,
        opened: [.25],
        minimum: 3,
        lastPrice: 5.49,
      ),
      Product(
        id: 'yogurt',
        name: 'Iogurte natural',
        pack: '170 g',
        location: 'Geladeira',
        closed: 2,
        lastPrice: 3.79,
        lots: [
          StockLot(
            id: 'yogurt-lot',
            closed: 2,
            expiry: today.add(const Duration(days: 1)),
          ),
        ],
      ),
      Product(
        id: 'soap',
        name: 'Sabonete',
        pack: '90 g',
        category: 'Higiene',
        location: 'Banheiro',
        closed: 3,
        minimum: 2,
        lastPrice: 3.2,
      ),
    ],
    list: [
      ShoppingItem(id: 'a', name: 'Papel toalha', quantity: 2, price: 6.49),
      ShoppingItem(
        id: 'b',
        name: 'Banana',
        price: 7.9,
        priority: Priority.flexible,
      ),
      ShoppingItem(
        id: 'c',
        name: 'Azeite extravirgem',
        price: 34.9,
        priority: Priority.later,
      ),
    ],
    events: [
      StockEvent(
        id: 'e1',
        title: 'Embalagem aberta',
        detail: 'Arroz integral',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      StockEvent(
        id: 'e2',
        title: 'Compra guardada',
        detail: '2× Arroz integral · 6× Leite integral · 1× Café moído',
        date: DateTime.now().subtract(const Duration(days: 4)),
        total: 69.64,
        kind: 'purchase',
      ),
      StockEvent(
        id: 'e3',
        title: 'Cupom importado',
        detail: '1× Banana · 2× Tomate · 1× Alface',
        date: DateTime.now().subtract(const Duration(days: 11)),
        total: 24.89,
        kind: 'purchase',
      ),
    ],
  );
}

void main() {
  testWidgets(
    'capture the real Flutter screens for visual review',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 54, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      await tester.runAsync(loadAppFonts);
      // The test binding draws shadows as solid shapes unless told otherwise.
      debugDisableShadows = false;
      final boundary = GlobalKey();
      final store = PantryStore(MemoryRepository(), AppData());
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: PantryApp(store: store),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        expect(tester.takeException(), isNull);
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        render.markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('docs/preview')
            ..createSync(recursive: true);
          await File(
            '${directory.path}/$name.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      Future<void> settle() async {
        // Let toasts expire so each capture shows a quiet screen.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }

      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      Future<void> pushed(String name, Widget page) async {
        navigator.push(MaterialPageRoute<void>(builder: (_) => page));
        await tester.pumpAndSettle();
        await capture(name);
        navigator.pop();
        await tester.pumpAndSettle();
      }

      await capture('01-boas-vindas');
      await store.replace(designData());
      await settle();
      await capture('09-hoje');
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      await capture('07-abertos-agora');
      await tester.tap(find.byKey(const ValueKey('nav-1')));
      await tester.pumpAndSettle();
      await capture('02-lista');
      await tester.tap(find.byKey(const ValueKey('cart-a')));
      await settle();
      await capture('10-carrinho');
      await tester.tap(find.byKey(const ValueKey('nav-2')));
      await tester.pumpAndSettle();
      await capture('03-estoque');
      await tester.tap(find.byKey(const ValueKey('stock-view-place')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Geladeira'));
      await tester.pumpAndSettle();
      await capture('14-estoque-por-lugar');
      await tester.tap(find.byKey(const ValueKey('stock-view-list')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arroz integral'));
      await tester.pumpAndSettle();
      await capture('04-produto');
      await tester.drag(find.byType(ListView).last, const Offset(0, -330));
      await tester.pumpAndSettle();
      await capture('20-produto-olhometro');
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Adicionar'));
      await tester.pumpAndSettle();
      await capture('11-atalhos');
      await tester.tap(find.byTooltip('Fechar atalhos'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mais'));
      await tester.pumpAndSettle();
      await capture('15-menu-mais');
      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();
      await capture('16-historico');
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mais'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notas e cupons'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compra da lista'));
      await tester.pumpAndSettle();
      await capture('17-notas-e-cupons');
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mais'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajustes e backup'));
      await tester.pumpAndSettle();
      await capture('18-ajustes');
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-0')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const ValueKey('jar-rice-0')));
      await tester.pumpAndSettle();
      await capture('12-ajuste-rapido');
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('jar-coffee-0')));
      await tester.pumpAndSettle();
      await capture('19-desfazer');
      await settle();
      await store.change((d) => d.receiptAliases['leit int'] = 'milk');
      final lines = [
        ReceiptLine(name: 'LEIT INT', quantity: 2, unitPrice: 5.49),
      ];
      ReceiptMatcher.prepare(lines, store.data);
      await pushed(
        '05-cupom-lembrado',
        ReceiptReview(store: store, lines: lines, fingerprint: 'preview-only'),
      );
      await pushed('06-descricoes-lembradas', ReceiptAliasesPage(store: store));
      await pushed('08-lotes-validade', LotsPage(store: store, id: 'yogurt'));
      debugDisableShadows = true;
    },
    skip: !const bool.fromEnvironment('CAPTURE_UI'),
  );
}
