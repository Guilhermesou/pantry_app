import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa/design.dart';
import 'package:despensa/models.dart';
import 'package:despensa/services.dart';
import 'package:despensa/store.dart';
import 'package:despensa/screens/capture.dart';
import 'package:despensa/screens/settings.dart';
import 'store_test.dart' show MemoryRepository;

void main() {
  Future<void> launch(
    WidgetTester tester,
    Widget page, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: pantryTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => fluidPage(context, page),
                child: const Text('Abrir revisão'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir revisão'));
    await tester.pumpAndSettle();
  }

  testWidgets('uncertain suggestion requires a tap before linking to stock', (
    tester,
  ) async {
    final store = PantryStore(MemoryRepository(), AppData.example());
    final line = ReceiptLine(name: 'LEIT INT');
    ReceiptMatcher.prepare([line], store.data);
    await launch(
      tester,
      ReceiptReview(store: store, lines: [line], fingerprint: 'a'),
      textScale: 1.4,
    );
    expect(find.text('Pode ser este produto?'), findsOneWidget);
    expect(line.productId, isNull);
    await tester.drag(find.byType(ListView).last, const Offset(0, -450));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar este produto'));
    await tester.pumpAndSettle();
    expect(line.productId, 'milk');
    expect(store.data.receiptAliases, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'review keeps original description when edited and learns on confirmation',
    (tester) async {
      final store = PantryStore(
        MemoryRepository(),
        AppData.example()..receiptAliases['leit int'] = 'milk',
      );
      final line = ReceiptLine(name: 'LEIT INT');
      ReceiptMatcher.prepare([line], store.data);
      await launch(
        tester,
        ReceiptReview(store: store, lines: [line], fingerprint: 'a'),
      );
      expect(
        find.text('Você já associou esta descrição antes. Confira o vínculo.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextFormField).first,
        'Leite da compra',
      );
      expect(line.originalName, 'LEIT INT');
      await tester.tap(find.text('Confirmar entrada no estoque'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar compra'));
      await tester.pumpAndSettle();
      expect(store.data.product('milk')!.closed, 2);
      expect(store.data.receiptAliases, {'leit int': 'milk'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'forgetting an association is reversible and works with enlarged text',
    (tester) async {
      final store = PantryStore(
        MemoryRepository(),
        AppData.example()..receiptAliases['leit int'] = 'milk',
      );
      await launch(tester, ReceiptAliasesPage(store: store), textScale: 1.4);
      await tester.tap(find.byTooltip('Esquecer leit int'));
      await tester.pumpAndSettle();
      expect(store.data.receiptAliases, isEmpty);
      expect(store.data.product('milk')!.closed, 1);
      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();
      expect(store.data.receiptAliases, {'leit int': 'milk'});
      expect(tester.takeException(), isNull);
    },
  );
}
