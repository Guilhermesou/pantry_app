import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa/main.dart';
import 'package:despensa/models.dart';
import 'package:despensa/screens/editors.dart';
import 'package:despensa/store.dart';
import 'store_test.dart' show MemoryRepository;

void main() {
  late List<String> haptics;
  Future<PantryStore> launch(
    WidgetTester tester,
    AppData data, {
    bool reduced = false,
  }) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: reduced);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    haptics = [];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add('${call.arguments}'.split('.').last);
        }
        return null;
      },
    );
    final store = PantryStore(MemoryRepository(), data);
    await tester.pumpWidget(PantryApp(store: store));
    await tester.pumpAndSettle();
    return store;
  }

  final confetti = find.byWidgetPredicate(
    (w) =>
        w is CustomPaint &&
        w.painter.runtimeType.toString() == '_ConfettiPainter',
  );

  testWidgets('saving a purchase throws confetti once and cleans up', (
    tester,
  ) async {
    await launch(tester, AppData.example());
    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cart-l1')));
    await tester.pumpAndSettle();
    expect(haptics, contains('lightImpact'), reason: 'checking presses');
    await tester.tap(find.byKey(const ValueKey('checkout-bar')));
    await tester.pumpAndSettle();
    haptics.clear();
    await tester.tap(find.text('Guardar no estoque'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(confetti, findsOneWidget);
    expect(haptics, contains('lightImpact'));
    await tester.pumpAndSettle();
    expect(confetti, findsNothing, reason: 'the burst is finite');
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion keeps the haptic but skips the confetti', (
    tester,
  ) async {
    await launch(tester, AppData.example(), reduced: true);
    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cart-l1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checkout-bar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar no estoque'));
    await tester.pump();
    expect(confetti, findsNothing);
    expect(haptics, isNotEmpty);
    await tester.pumpAndSettle();
  });

  testWidgets('lowering an opened package floats a quarter label', (
    tester,
  ) async {
    final store = await launch(
      tester,
      AppData(
        onboarded: true,
        products: [
          Product(id: 'rice', name: 'Arroz', minimum: 0, opened: [.75]),
        ],
      ),
    );
    await tester.tap(find.byKey(const ValueKey('jar-rice-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('−¼'), findsOneWidget);
    expect(haptics.last, 'selectionClick');
    await tester.pumpAndSettle();
    expect(find.text('−¼'), findsNothing);
    expect(store.data.product('rice')!.opened, [.5]);
  });

  testWidgets('clearing the last pending card on Today celebrates', (
    tester,
  ) async {
    await launch(
      tester,
      AppData(
        onboarded: true,
        products: [Product(id: 'p', name: 'Café', minimum: 2)],
      ),
    );
    await tester.tap(find.text('Pôr na lista'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(confetti, findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Nada mais pedindo atenção por hoje.'), findsOneWidget);
  });

  testWidgets('a counter at its limit shakes no instead of changing', (
    tester,
  ) async {
    var value = 1;
    await launch(tester, AppData(onboarded: true));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Counter(
              label: 'Embalagens',
              value: value,
              min: 1,
              max: 2,
              onChanged: (n) => setState(() => value = n),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Diminuir Embalagens'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(value, 1);
    expect(haptics.last, 'heavyImpact');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Aumentar Embalagens'));
    await tester.pumpAndSettle();
    expect(value, 2);
    expect(haptics.last, 'selectionClick');
    expect(find.text('2'), findsOneWidget);
  });
}
