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
import 'package:despensa/screens/quick_level.dart';
import 'store_test.dart' show MemoryRepository;

// Optional visual QA capture using system fonts, without bundling proprietary fonts.
void main() {
  testWidgets(
    'capture the real Flutter screens for visual review',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        final icons = FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(
            rootBundle.load(
              'packages/cupertino_icons/assets/CupertinoIcons.ttf',
            ),
          );
        await icons.load();
        final materialIcons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await materialIcons.load();
        for (final entry in {
          'Georgia': '/System/Library/Fonts/Supplemental/Georgia.ttf',
          '.SF Pro Text': '/System/Library/Fonts/SFNS.ttf',
        }.entries) {
          final bytes = await File(entry.value).readAsBytes();
          final loader = FontLoader(entry.key)
            ..addFont(Future.value(ByteData.sublistView(bytes)));
          await loader.load();
        }
      });
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

      await capture('01-boas-vindas');
      final designData = AppData.example();
      designData.list.removeWhere((item) => item.productId != null);
      designData.products.add(
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
              expiry: calendarDate(DateTime.now()).add(const Duration(days: 1)),
            ),
          ],
        ),
      );
      await store.replace(designData);
      await tester.pumpAndSettle();
      await capture('09-hoje');
      await store.addSuggestion('milk');
      await store.addSuggestion('coffee');
      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();
      await capture('02-lista');
      await store.change(
        (d) => d.list.firstWhere((e) => e.productId == 'milk').checked = true,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('Expandir carrinho')));
      await tester.pumpAndSettle();
      await capture('10-carrinho');
      await tester.tap(find.text('Estoque'));
      await tester.pumpAndSettle();
      await capture('03-estoque');
      await tester.tap(find.text('Arroz integral'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, -310));
      await tester.pumpAndSettle();
      await capture('04-controle-parcial');
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();
      await store.change((d) => d.receiptAliases['leit int'] = 'milk');
      final lines = [
        ReceiptLine(name: 'LEIT INT', quantity: 2, unitPrice: 5.49),
      ];
      ReceiptMatcher.prepare(lines, store.data);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptReview(
            store: store,
            lines: lines,
            fingerprint: 'preview-only',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture('05-cupom-lembrado');
      navigator.pop();
      await tester.pumpAndSettle();
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptAliasesPage(store: store),
        ),
      );
      await tester.pumpAndSettle();
      await capture('06-descricoes-lembradas');
      navigator.pop();
      await tester.pumpAndSettle();
      await store.assignExpiry(
        'milk',
        1,
        calendarDate(DateTime.now()).add(const Duration(days: 3)),
      );
      await store.assignOpenedExpiry(
        'milk',
        0,
        calendarDate(DateTime.now()).add(const Duration(days: 1)),
      );
      await tester.pumpAndSettle();
      await capture('07-avisos-validade');
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => LotsPage(store: store, id: 'milk'),
        ),
      );
      await tester.pumpAndSettle();
      await capture('08-lotes-validade');
      navigator.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Adicionar'));
      await tester.pumpAndSettle();
      await capture('11-atalhos');
      await tester.tap(find.byTooltip('Fechar atalhos'));
      await tester.pumpAndSettle();
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => QuickLevelPage(store: store, id: 'rice', index: 0),
        ),
      );
      await tester.pumpAndSettle();
      await capture('12-ajuste-rapido');
    },
    skip: !const bool.fromEnvironment('CAPTURE_UI'),
  );
}
