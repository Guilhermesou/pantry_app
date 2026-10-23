import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa/main.dart';
import 'package:despensa/models.dart';
import 'package:despensa/store.dart';
import 'store_test.dart' show MemoryRepository;

void main() {
  Future<PantryStore> launch(
    WidgetTester tester,
    AppData data, {
    Size size = const Size(393, 852),
    double scale = 1,
    bool reduced = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: reduced);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final store = PantryStore(MemoryRepository(), data);
    await tester.pumpWidget(PantryApp(store: store));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('Today adds a low product to the list without changing stock', (
    tester,
  ) async {
    final store = await launch(
      tester,
      AppData(
        onboarded: true,
        budget: 100,
        products: [
          Product(
            id: 'milk',
            name: 'Leite',
            closed: 1,
            minimum: 3,
            lastPrice: 5,
          ),
        ],
      ),
    );
    expect(find.text('Uma coisa pede atenção.'), findsOneWidget);
    await tester.tap(find.text('Pôr na lista'));
    await tester.pumpAndSettle();
    expect(store.data.list.single.productId, 'milk');
    expect(store.data.list.single.quantity, 2);
    expect(store.data.product('milk')!.closed, 1);
    expect(find.text('Pôr na lista'), findsNothing);
    expect(find.text('Tudo no seu lugar.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'checking an expiry does not dismiss the warning or discard the lot',
    (tester) async {
      final expiry = calendarDate(DateTime.now()).add(const Duration(days: 1));
      final store = await launch(
        tester,
        AppData(
          onboarded: true,
          products: [
            Product(
              id: 'yog',
              name: 'Iogurte',
              closed: 2,
              lots: [StockLot(id: 'lot', closed: 2, expiry: expiry)],
            ),
          ],
        ),
      );
      await tester.tap(find.text('Conferir'));
      await tester.pumpAndSettle();
      expect(find.text('Lotes e validades'), findsOneWidget);
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();
      expect(find.text('Conferir'), findsOneWidget);
      expect(store.data.product('yog')!.closed, 2);
      expect(store.data.product('yog')!.activeLots.single.expiry, expiry);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'cart expands without covering items and checkout receives only marked purchases',
    (tester) async {
      final store = await launch(tester, AppData.example());
      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -240));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cart-l1')));
      await tester.pumpAndSettle();
      expect(store.data.product('milk')!.closed, 1);
      expect(store.data.list.first.checked, true);
      await tester.tap(find.bySemanticsLabel(RegExp('Expandir carrinho')));
      await tester.pumpAndSettle();
      expect(find.text('Concluir compra'), findsOneWidget);
      await tester.tap(find.text('Concluir compra'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar no estoque'));
      await tester.pumpAndSettle();
      expect(store.data.product('milk')!.closed, 7);
      expect(store.data.list.length, 2);
      expect(store.data.list.any((e) => e.id == 'l2'), true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'quick level opens without consuming, adjusts and can undo a finish with its lot',
    (tester) async {
      final expiry = calendarDate(DateTime.now()).add(const Duration(days: 30));
      final store = await launch(
        tester,
        AppData(
          onboarded: true,
          products: [
            Product(
              id: 'rice',
              name: 'Arroz',
              minimum: 0,
              opened: [.5],
              lots: [StockLot(id: 'lot', closed: 0, expiry: expiry)],
              openedLotIds: ['lot'],
            ),
          ],
        ),
      );
      await tester.tap(find.byKey(const ValueKey('jar-rice-0')));
      await tester.pumpAndSettle();
      expect(store.data.product('rice')!.opened, [.5]);
      await tester.tap(find.widgetWithText(ChoiceChip, '¼'));
      await tester.pumpAndSettle();
      expect(store.data.product('rice')!.opened, [.25]);
      await tester.tap(find.text('Acabou esta embalagem'));
      await tester.pumpAndSettle();
      expect(store.data.product('rice')!.opened, isEmpty);
      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();
      expect(store.data.product('rice')!.opened, [.25]);
      expect(store.data.product('rice')!.openedLotIds, ['lot']);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'add shortcuts close without changing data and open real capture screens',
    (tester) async {
      final store = await launch(tester, AppData(onboarded: true));
      await tester.tap(find.byTooltip('Adicionar'));
      await tester.pump(const Duration(milliseconds: 160));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fechar atalhos'));
      await tester.pumpAndSettle();
      expect(store.data.products, isEmpty);
      expect(store.data.list, isEmpty);
      await tester.tap(find.byTooltip('Adicionar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ler código de barras'));
      await tester.pumpAndSettle();
      expect(find.text('Buscar produto'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('large text preserves stock filters and compact cart access', (
    tester,
  ) async {
    await launch(
      tester,
      AppData.example(),
      size: const Size(375, 667),
      scale: 1.4,
    );
    await tester.tap(find.text('Estoque'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('stock-search')),
      'Sabonete',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('Expandir carrinho')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Estoque'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('stock-search')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      'Sabonete',
    );
    expect(find.text('Arroz integral'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'reduced motion still opens shortcuts and forms without waiting on a reveal',
    (tester) async {
      await launch(tester, AppData(onboarded: true), reduced: true);
      await tester.tap(find.byTooltip('Adicionar'));
      await tester.pump();
      expect(find.text('Um item na lista'), findsOneWidget);
      await tester.tap(find.text('Um item na lista'));
      await tester.pumpAndSettle();
      expect(find.text('Adicionar à lista'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'a failed purchase write keeps cart and stock intact in the new interface',
    (tester) async {
      final data = AppData.example();
      data.list.first.checked = true;
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = PantryStore(MemoryRepository()..fail = true, data);
      await tester.pumpWidget(PantryApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('Expandir carrinho')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Concluir compra'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar no estoque'));
      await tester.pumpAndSettle();
      expect(store.data.product('milk')!.closed, 1);
      expect(store.data.list.first.checked, true);
      expect(tester.takeException(), isNull);
    },
  );
}
