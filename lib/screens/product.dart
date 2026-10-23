import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design.dart';
import '../illustration.dart';
import '../main.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';
import '../symbols.dart';
import '../toast.dart';
import 'editors.dart';
import 'lots.dart';

class ProductDetail extends StatelessWidget {
  const ProductDetail({super.key, required this.store, required this.id});
  final PantryStore store;
  final String id;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final p = store.data.product(id);
      if (p == null) {
        return const SheetScaffold(
          title: 'Produto removido.',
          child: SizedBox(),
        );
      }
      final inList = store.data.list.any((e) => e.productId == id);
      final now = DateTime.now();
      return SheetScaffold(
        leading: ProductArt(product: p),
        title: p.name,
        subtitle: [
          p.brand,
          p.pack,
          p.location,
        ].where((e) => e.isNotEmpty).join(' · '),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            50 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.closed} ${p.closed == 1 ? 'embalagem fechada' : 'embalagens fechadas'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Abriu uma? Vamos acompanhar sem medir.',
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'Abrir embalagem',
                    icon: Symbols.package2,
                    expand: true,
                    glow: true,
                    onPressed: p.closed == 0 || store.busy
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            choosePackage(context, store, id);
                          },
                  ),
                ],
              ),
            ),
            if (p.opened.isNotEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 24, 4, 8),
                child: SectionLabel('No olhômetro'),
              ),
            for (var i = 0; i < p.opened.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                child: _OpenedPackage(store: store, product: p, index: i),
              ),
            const SizedBox(height: 12),
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.low
                        ? 'Vale pensar na reposição.'
                        : 'Por aqui, está tudo certo.',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mínimo desejado: ${p.minimum.toStringAsFixed(0)} embalagens. Você escolhe quando comprar.',
                    style: const TextStyle(fontSize: 13, color: muted),
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: inList ? 'Já está na lista' : 'Pôr na lista',
                    icon: inList ? Symbols.check : Symbols.add,
                    tone: ButtonTone.soft,
                    height: 40,
                    onPressed: inList || store.busy
                        ? null
                        : () => perform(
                            context,
                            () => store.addSuggestion(id),
                            success: '${p.name} foi para a lista.',
                          ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 24, 4, 8),
              child: SectionLabel('Cadastro'),
            ),
            GroupedList(
              shadow: shadowSmall,
              children: [
                ListRow(
                  title: 'Lotes e validades',
                  value: p.nearestExpiry == null
                      ? 'Nenhuma anotada'
                      : expiryLabel(p.nearestExpiry!, now),
                  chevron: true,
                  onTap: () =>
                      pushPage(context, LotsPage(store: store, id: id)),
                ),
                ListRow(
                  title: 'Editar cadastro',
                  value: p.category,
                  chevron: true,
                  onTap: () => showSheet(
                    context,
                    ProductEditor(store: store, product: p),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Excluir produto',
              tone: ButtonTone.danger,
              height: 48,
              expand: true,
              onPressed: store.busy
                  ? null
                  : () async {
                      if (await confirm(
                            context,
                            'Excluir este produto?',
                            'O cadastro e seu saldo serão removidos. Itens na lista ficarão sem vínculo e o histórico será preservado.',
                            label: 'Excluir',
                          ) &&
                          context.mounted) {
                        final ok = await perform(
                          context,
                          () => store.removeProduct(id),
                        );
                        if (ok && context.mounted) Navigator.pop(context);
                      }
                    },
            ),
          ],
        ),
      );
    },
  );
}

class _OpenedPackage extends StatelessWidget {
  const _OpenedPackage({
    required this.store,
    required this.product,
    required this.index,
  });
  final PantryStore store;
  final Product product;
  final int index;
  @override
  Widget build(BuildContext context) {
    final p = product, i = index, level = p.opened[i];
    return Surface(
      child: Column(
        children: [
          Row(
            children: [
              PackageIllustration(product: p, level: level, width: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Embalagem aberta ${i + 1}',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      levelNames[(level * 4).round()],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'aprox. ${(level * 100).round()}%',
                      style: const TextStyle(fontSize: 12, color: faint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedPicker<int>(
            keyPrefix: 'level-$i',
            options: const [
              (1, '¼', null),
              (2, '½', null),
              (3, '¾', null),
              (4, 'Cheio', null),
            ],
            selected: (level * 4).round(),
            onSelected: store.busy
                ? null
                : (n) {
                    HapticFeedback.selectionClick();
                    perform(context, () => store.setLevel(p.id, i, n / 4));
                  },
          ),
          const SizedBox(height: 10),
          ExpiryField(
            value: p.lot(p.openedLotIds[i])?.expiry,
            enabled: !store.busy,
            onChanged: (value) => perform(
              context,
              () => store.assignOpenedExpiry(p.id, i, value),
            ),
          ),
          const SizedBox(height: 4),
          AppButton(
            label: 'Acabou esta embalagem',
            tone: ButtonTone.ghostDanger,
            height: 36,
            expand: true,
            onPressed: store.busy
                ? null
                : () async {
                    final previous = level, lotId = p.openedLotIds[i];
                    final ok = await perform(
                      context,
                      () => store.setLevel(p.id, i, 0),
                    );
                    if (ok && context.mounted) {
                      showToast(
                        context,
                        '${p.name}: embalagem finalizada.',
                        undo: () => perform(
                          context,
                          () => store.restoreOpened(p.id, previous, lotId),
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}
