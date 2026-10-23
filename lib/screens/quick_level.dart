import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design.dart';
import '../main.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';

class FinishedOpening {
  const FinishedOpening(this.level, this.lotId);
  final double level;
  final String? lotId;
}

Future<void> showQuickLevel(
  BuildContext context,
  PantryStore store,
  String id,
  int index, {
  Rect? origin,
}) async {
  final result = await fluidPage<FinishedOpening>(
    context,
    QuickLevelPage(store: store, id: id, index: index),
    origin: origin,
  );
  if (result != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Embalagem finalizada.'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => perform(
            context,
            () => store.restoreOpened(id, result.level, result.lotId),
          ),
        ),
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
        return const PanelScaffold(
          title: 'Tudo atualizado.',
          child: SizedBox(),
        );
      }
      final level = p.opened[index];
      final expiry = p.lot(p.openedLotIds[index])?.expiry;
      return PanelScaffold(
        title: 'Quanto ainda tem?',
        subtitle: '${p.name} · embalagem aberta ${index + 1}',
        footer: FilledButton.icon(
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
          icon: const Icon(CupertinoIcons.checkmark_alt, size: 18),
          label: const Text('Acabou esta embalagem'),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const Center(child: Eyebrow('NO OLHÔMETRO')),
            const SizedBox(height: 24),
            Center(child: LiquidLevel(level: level, size: 170)),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: motionTime(context, 180),
              child: Editorial(
                levelNames[(level * 4).round()],
                key: ValueKey(level),
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Escolha o nível mais próximo.\nSem pesar, sem medir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (value, label) in [
                  (1, '¼'),
                  (2, '½'),
                  (3, '¾'),
                  (4, 'Cheio'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: (level * 4).round() == value,
                    selectedColor: ink,
                    labelStyle: TextStyle(
                      color: (level * 4).round() == value ? paper : ink,
                    ),
                    showCheckmark: false,
                    onSelected: store.busy
                        ? null
                        : (_) {
                            HapticFeedback.selectionClick();
                            perform(
                              context,
                              () => store.setLevel(id, index, value / 4),
                            );
                          },
                  ),
              ],
            ),
            if (expiry != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
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
