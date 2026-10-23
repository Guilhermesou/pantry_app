import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa/main.dart';
import 'package:despensa/models.dart';
import 'package:despensa/store.dart';
import 'store_test.dart' show MemoryRepository;

void main() {
  Future<PantryStore> launch(
    WidgetTester tester, {
    AppData? data,
    Size size = const Size(393, 852),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = PantryStore(MemoryRepository(), data ?? AppData.example());
    await tester.pumpWidget(PantryApp(store: store));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('onboarding starts empty without injecting demo products', (
    tester,
  ) async {
    final store = await launch(tester, data: AppData());
    await tester.scrollUntilVisible(find.text('Começar minha despensa'), 200);
    await tester.tap(find.text('Começar minha despensa'));
    await tester.pumpAndSettle();
    expect(store.data.onboarded, true);
    expect(store.data.products, isEmpty);
    expect(find.text('Uma lista leve.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'stock opens fluid detail, opens package and updates partial level',
    (tester) async {
      final store = await launch(tester);
      await tester.tap(find.text('Estoque'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Arroz integral'));
      await tester.pump(const Duration(milliseconds: 280));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir embalagem'));
      await tester.pumpAndSettle();
      expect(store.data.product('rice')!.closed, 1);
      expect(store.data.product('rice')!.opened.length, 2);
      await tester.drag(find.byType(ListView).last, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('¼').first);
      await tester.pumpAndSettle();
      expect(store.data.product('rice')!.opened.first, .25);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('add item saves a generic list entry', (tester) async {
    final store = await launch(tester);
    await tester.tap(find.byTooltip('Adicionar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Um item na lista'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Feijão');
    await tester.tap(find.text('Adicionar à lista'));
    await tester.pumpAndSettle();
    expect(store.data.list.any((e) => e.name == 'Feijão'), isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('compact iPhone at larger text keeps navigation usable', (
    tester,
  ) async {
    await launch(tester, size: const Size(375, 667), textScale: 1.4);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Estoque'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();
    expect(find.text('Tudo começa agora.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
