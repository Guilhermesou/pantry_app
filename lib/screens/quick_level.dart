import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design.dart';
import '../illustration.dart';
import '../main.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';
import '../toast.dart';

class FinishedOpening {
  const FinishedOpening(this.level, this.lotId);
  final double level;
  final String? lotId;
}

Future<void> showQuickLevel(
  BuildContext context,
  PantryStore store,
  String id,
  int index,
) async {
  final name = store.data.product(id)?.name ?? 'Produto';
  final result = await showSheet<FinishedOpening>(
    context,
    QuickLevelPage(store: store, id: id, index: index),
  );
  if (result != null && context.mounted) {
    showToast(
      context,
      '$name: embalagem finalizada.',
      undo: () => perform(
        context,
        () => store.restoreOpened(id, result.level, result.lotId),
      ),
    );
  }
}

class QuickLevelPage extends StatelessWidget {
  const QuickLevelPage({
    super.key,
    required this.store,
    required this.id,
    required this.index,
  });
  final PantryStore store;
  final String id;
  final int index;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final p = store.data.product(id);
      if (p == null || index >= p.opened.length) {
        return const SheetScaffold(
          title: 'Tudo atualizado.',
          child: SizedBox(),
        );
      }
      final level = p.opened[index];
      final expiry = p.lot(p.openedLotIds[index])?.expiry;
      return SheetScaffold(
        leading: ProductArt(product: p),
        title: 'Quanto ainda tem?',
        subtitle: '${p.name} · embalagem aberta ${index + 1}',
        footer: AppButton(
          label: 'Acabou esta embalagem',
          tone: ButtonTone.danger,
          height: 48,
          expand: true,
          onPressed: store.busy
              ? null
              : () async {
                  final previous = FinishedOpening(
                    level,
                    p.openedLotIds[index],
                  );
                  final ok = await perform(
                    context,
                    () => store.setLevel(id, index, 0),
                  );
                  if (ok && context.mounted) Navigator.pop(context, previous);
                },
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            const Center(child: SectionLabel('No olhômetro')),
            const SizedBox(height: 18),
            Center(
              child: PackageIllustration(product: p, level: level, width: 120),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: motionTime(context, 180),
              child: Text(
                levelNames[(level * 4).round()],
                key: ValueKey(level),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'aprox. ${(level * 100).round()}% · sem pesar, sem medir',
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            SegmentedPicker<int>(
              keyPrefix: 'quick-level',
              options: const [
                (1, '¼', null),
                (2, '½', null),
                (3, '¾', null),
                (4, 'Cheio', null),
              ],
              selected: (level * 4).round(),
              onSelected: store.busy
                  ? null
                  : (value) {
                      HapticFeedback.selectionClick();
                      perform(
                        context,
                        () => store.setLevel(id, index, value / 4),
                      );
                    },
            ),
            if (expiry != null)
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Text(
                  'Validade ${displayDate(expiry)} · ${expiryLabel(expiry, DateTime.now())}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ),
          ],
        ),
      );
    },
  );
}
