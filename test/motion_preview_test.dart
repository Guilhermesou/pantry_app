import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa/main.dart';
import 'package:despensa/models.dart';
import 'package:despensa/store.dart';
import 'preview_test.dart' show loadAppFonts;
import 'store_test.dart' show MemoryRepository;

// Captures actual Flutter animation frames. No animation runs continuously in the app.
void main() {
  testWidgets(
    'record add shortcuts, sheet reveal and reverse transition',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(loadAppFonts);
      debugDisableShadows = false;
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: PantryApp(
            store: PantryStore(MemoryRepository(), AppData.example()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      var number = 0;
      final frames = <Map<String, Object>>[];
      Future<void> capture(int hold) async {
        expect(tester.takeException(), isNull);
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        render.markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final directory = Directory('docs/motion')
            ..createSync(recursive: true);
          final name = 'frame-${(number++).toString().padLeft(3, '0')}.png';
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${directory.path}/$name',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
          frames.add({'file': name, 'duration': hold});
        });
      }

      await capture(400);
      await tester.tap(find.byTooltip('Adicionar'));
      await tester.pump();
      for (var i = 0; i < 11; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        await capture(40);
      }
      await tester.pump(const Duration(milliseconds: 200));
      await capture(300);
      await tester.tap(find.text('Um produto no estoque'));
      await tester.pump();
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        await capture(40);
      }
      await tester.pumpAndSettle();
      await capture(350);
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pump();
      for (var i = 0; i < 11; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        await capture(40);
      }
      await tester.pumpAndSettle();
      await capture(400);
      await tester.runAsync(
        () async =>
            File('docs/motion/manifest.json').writeAsString(jsonEncode(frames)),
      );
      debugDisableShadows = true;
    },
    skip: !const bool.fromEnvironment('CAPTURE_MOTION'),
  );
  testWidgets(
    'record micro-interactions: a level tap and the cleared-day confetti',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(loadAppFonts);
      debugDisableShadows = false;
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: PantryApp(
            store: PantryStore(
              MemoryRepository(),
              AppData(
                onboarded: true,
                budget: 300,
                products: [
                  Product(id: 'coffee', name: 'Café moído', minimum: 2),
                  Product(
                    id: 'milk',
                    name: 'Leite integral',
                    category: 'Bebidas',
                    minimum: 0,
                    opened: [.75],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      var number = 0;
      final frames = <Map<String, Object>>[];
      Future<void> capture(int hold) async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        render.markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final directory = Directory('docs/motion-micro')
            ..createSync(recursive: true);
          final name = 'frame-${(number++).toString().padLeft(3, '0')}.png';
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${directory.path}/$name',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
          frames.add({'file': name, 'duration': hold});
        });
      }

      await tester.ensureVisible(find.byKey(const ValueKey('jar-milk-0')));
      await tester.pumpAndSettle();
      await capture(500);
      await tester.tap(find.byKey(const ValueKey('jar-milk-0')));
      await tester.pump();
      for (var i = 0; i < 18; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        await capture(40);
      }
      await tester.pumpAndSettle();
      await capture(400);
      await tester.tap(find.text('Pôr na lista'));
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 45));
        await capture(45);
      }
      await tester.pumpAndSettle();
      await capture(900);
      await tester.runAsync(
        () async => File(
          'docs/motion-micro/manifest.json',
        ).writeAsString(jsonEncode(frames)),
      );
      debugDisableShadows = true;
    },
    skip: !const bool.fromEnvironment('CAPTURE_MOTION'),
  );
}
