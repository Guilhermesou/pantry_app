import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa/design.dart';
import 'package:despensa/screens/home.dart';
import 'package:despensa/models.dart';
import 'package:despensa/store.dart';
import 'package:despensa/toast.dart';
import 'package:despensa/screens/product.dart';
import 'package:despensa/screens/lots.dart';
import 'package:despensa/screens/editors.dart';
import 'store_test.dart' show MemoryRepository;

void main() {
  Future<void> launch(
    WidgetTester tester,
    Widget page, {
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: pantryTheme(),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => ToastHost(child: child!),
        home: page,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'annotating a portion of existing stock does not add a purchase',
    (tester) async {
      final store = PantryStore(
        MemoryRepository(),
        AppData(
          products: [Product(id: 'p', name: 'Leite', closed: 5)],
        ),
      );
      await launch(tester, LotsPage(store: store, id: 'p'));
      await tester.tap(find.text('Anotar validade'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Diminuir Fechadas neste lote'));
      await tester.pump();
      await tester.tap(find.byTooltip('Diminuir Fechadas neste lote'));
      await tester.pump();
      await tester.tap(find.text('Anotar validade (opcional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('${DateTime.now().day}').last);
      await tester.tap(find.text('Anotar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar validade'));
      await tester.pumpAndSettle();
      expect(store.data.product('p')!.closed, 5);
      expect(store.data.product('p')!.activeLots.single.closed, 3);
      expect(store.data.product('p')!.undatedClosed, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'opening from a specific date uses the lot selected in the sheet',
    (tester) async {
      final first = DateTime(2026, 11, 2), second = DateTime(2026, 12, 3);
      final p = Product(
        id: 'p',
        name: 'Leite',
        closed: 4,
        lots: [
          StockLot(id: 'a', closed: 2, expiry: first),
          StockLot(id: 'b', closed: 2, expiry: second),
        ],
      );
      final store = PantryStore(MemoryRepository(), AppData(products: [p]));
      await launch(tester, ProductDetail(store: store, id: 'p'));
      await tester.tap(find.text('Abrir embalagem'));
      await tester.pumpAndSettle();
      expect(find.text('Qual você abriu?'), findsOneWidget);
      await tester.tap(find.text(displayDate(second)));
      await tester.pumpAndSettle();
      expect(store.data.product('p')!.openedLotIds, ['b']);
      expect(store.data.product('p')!.lot('a')!.closed, 2);
      expect(store.data.product('p')!.lot('b')!.closed, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('expiry reminder filters without removing expired stock', (
    tester,
  ) async {
    final now = DateTime.now();
    final expired = Product(
      id: 'old',
      name: 'Leite antigo',
      closed: 1,
      lots: [
        StockLot(
          id: 'old-lot',
          closed: 1,
          expiry: now.subtract(const Duration(days: 1)),
        ),
      ],
    );
    final fresh = Product(
      id: 'new',
      name: 'Arroz novo',
      closed: 1,
      lots: [
        StockLot(
          id: 'new-lot',
          closed: 1,
          expiry: now.add(const Duration(days: 30)),
        ),
      ],
    );
    final store = PantryStore(
      MemoryRepository(),
      AppData(onboarded: true, products: [expired, fresh]),
    );
    await launch(tester, PantryHome(store: store));
    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Validades'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Validades'));
    await tester.pumpAndSettle();
    expect(store.data.product('old')!.closed, 1);
    expect(find.text('Arroz novo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'lot editing remains usable with large text on a compact iPhone',
    (tester) async {
      final date = DateTime(2026, 12, 1);
      final store = PantryStore(
        MemoryRepository(),
        AppData(
          products: [
            Product(
              id: 'p',
              name: 'Leite integral',
              closed: 2,
              lots: [StockLot(id: 'a', closed: 2, expiry: date)],
            ),
          ],
        ),
      );
      await launch(
        tester,
        LotEditor(store: store, id: 'p', lotId: 'a'),
        scale: 1.4,
      );
      expect(find.text('Salvar validade'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'a product with no closed packages can register one already open',
    (tester) async {
      final store = PantryStore(
        MemoryRepository(),
        AppData(
          products: [Product(id: 'p', name: 'Achocolatado')],
        ),
      );
      await launch(tester, ProductDetail(store: store, id: 'p'));
      expect(find.text('Abrir embalagem'), findsNothing);
      await tester.tap(find.text('Registrar embalagem aberta'));
      await tester.pumpAndSettle();
      expect(store.data.product('p')!.opened, [1]);
      expect(store.data.product('p')!.closed, 0);
      await tester.tap(find.bySemanticsLabel(RegExp('Toque para baixar')));
      await tester.pumpAndSettle();
      expect(store.data.product('p')!.opened, [.75]);
      expect(find.text('Cerca de ¾'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('a new lot with another date is added from the lots page', (
    tester,
  ) async {
    final store = PantryStore(
      MemoryRepository(),
      AppData(
        products: [
          Product(id: 'p', name: 'Achocolatado', opened: [.5]),
        ],
      ),
    );
    await launch(tester, LotsPage(store: store, id: 'p'));
    expect(find.text('Embalagem aberta 1 · Metade'), findsOneWidget);
    await tester.tap(find.text('Adicionar embalagens com validade'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Aumentar Embalagens fechadas'));
    await tester.pump();
    await tester.tap(find.text('Anotar validade (opcional)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().day}').last);
    await tester.tap(find.text('Anotar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar ao estoque'));
    await tester.pumpAndSettle();
    final p = store.data.product('p')!;
    expect(p.closed, 2);
    expect(p.activeLots.single.closed, 2);
    expect(find.text('2 fechadas · 0 abertas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('a new product can start with two different expiry dates', (
    tester,
  ) async {
    final store = PantryStore(MemoryRepository(), AppData());
    await launch(tester, ProductEditor(store: store));
    await tester.enterText(find.byType(TextFormField).first, 'Achocolatado');
    for (final _ in [1, 2, 3]) {
      await tester.tap(find.byTooltip('Aumentar Embalagens fechadas'));
      await tester.pump();
    }
    Future<void> pickToday(String button) async {
      await tester.ensureVisible(find.text(button));
      // Keep the button clear of the sheet footer.
      await tester.drag(find.byType(ListView), const Offset(0, -160));
      await tester.pumpAndSettle();
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      await tester.tap(find.text('${DateTime.now().day}').last);
      await tester.tap(find.text('Anotar'));
      await tester.pumpAndSettle();
    }

    await pickToday('Anotar validade (opcional)');
    await tester.tap(find.byTooltip('Diminuir Com esta validade'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('1 sem validade anotada.'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await pickToday('Outra validade');
    await tester.scrollUntilVisible(
      find.text('Todas as fechadas têm validade.'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Salvar produto'));
    await tester.pumpAndSettle();
    final p = store.data.products.single;
    expect(p.closed, 3);
    expect(p.lots.map((lot) => lot.closed), [2, 1]);
    expect(tester.takeException(), isNull);
  });
}
