import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa/main.dart';
import 'package:despensa/models.dart';
import 'package:despensa/store.dart';
import 'store_test.dart' show MemoryRepository;

// Captures actual Flutter animation frames. No animation runs continuously in the app.
void main() {
  testWidgets(
    'record add shortcuts, liquid page reveal and reverse transition',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        for (final (name, asset) in [
          (
            'packages/cupertino_icons/CupertinoIcons',
            'packages/cupertino_icons/assets/CupertinoIcons.ttf',
          ),
          ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
        ]) {
          final loader = FontLoader(name)..addFont(rootBundle.load(asset));
          await loader.load();
        }
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
    },
    skip: !const bool.fromEnvironment('CAPTURE_MOTION'),
  );
}
