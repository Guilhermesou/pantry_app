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
      await store.replace(AppData.example());
      await tester.pumpAndSettle();
      await capture('02-lista');
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
    },
    skip: !const bool.fromEnvironment('CAPTURE_UI'),
  );
}
