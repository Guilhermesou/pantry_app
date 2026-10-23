import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../design.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';

String todayLabel(DateTime date) {
  const days = [
    'segunda',
    'terça',
    'quarta',
    'quinta',
    'sexta',
    'sábado',
    'domingo',
  ];
  const months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  return '${days[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
}

String attentionHeadline(int count, bool empty) {
  if (empty) return 'Sua casa,\nno seu ritmo.';
  if (count == 0) return 'Tudo no seu lugar.';
  if (count == 1) return 'Uma coisa pede atenção.';
  const words = {2: 'Duas', 3: 'Três', 4: 'Quatro', 5: 'Cinco'};
  return '${words[count] ?? count} coisas pedem atenção.';
}

String _lowDetail(Product p) {
  final closed = '${p.closed} ${p.closed == 1 ? 'fechado' : 'fechados'}';
  final opened = p.opened.isEmpty
      ? ''
      : '${levelNames[(p.opened.first * 4).round()]} no ${p.opened.length > 1 ? '1º aberto' : 'aberto'}';
  return '${[if (opened.isNotEmpty) opened, if (p.closed > 0 || opened.isEmpty) closed].join(' + ')} · mínimo ${p.minimum.toStringAsFixed(0)}';
}

class TodayContent extends StatelessWidget {
  const TodayContent({
    super.key,
    required this.store,
    required this.onList,
    required this.onAdd,
    required this.onProduct,
    required this.onLevel,
    required this.onSuggestion,
  });
  final PantryStore store;
  final VoidCallback onList;
  final void Function(BuildContext) onAdd;
  final void Function(BuildContext, Product) onProduct;
  final void Function(BuildContext, Product, int) onLevel;
  final Future<void> Function(Product) onSuggestion;
  @override
  Widget build(BuildContext context) {
    final data = store.data;
    final low = data.products.where((p) => p.low).toList();
    final due =
        data.products
            .where((p) => p.needsExpiryAttention(DateTime.now()))
            .toList()
          ..sort((a, b) => a.nearestExpiry!.compareTo(b.nearestExpiry!));
    final pending =
        low.where((p) => !data.list.any((e) => e.productId == p.id)).length +
        due.length;
    final opened = [
      for (final p in data.products)
        for (var i = 0; i < p.opened.length; i++) (p, i),
    ];
    return ListView(
      key: const PageStorageKey('today-scroll'),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      children: [
        AnimatedSize(
          duration: motionTime(context, 380),
          alignment: Alignment.topLeft,
          child: AnimatedSwitcher(
            duration: motionTime(context, 240),
            child: Align(
              key: ValueKey(attentionHeadline(pending, data.products.isEmpty)),
              alignment: Alignment.centerLeft,
              child: Editorial(
                attentionHeadline(pending, data.products.isEmpty),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (data.products.isEmpty)
          EmptyState(
            icon: CupertinoIcons.cube_box,
            title: 'Vamos conhecer sua casa.',
            message:
                'Cadastre o que você já tem.\nAs sugestões aparecem no seu ritmo.',
            action: Builder(
              builder: (anchor) => FilledButton(
                onPressed: () => onAdd(anchor),
                child: const Text('Adicionar meu primeiro produto'),
              ),
            ),
          ),
        for (final p in low)
          AnimatedSize(
            key: ValueKey('low-${p.id}'),
            duration: motionTime(context, 450),
            curve: Curves.easeInOutCubicEmphasized,
            alignment: Alignment.topCenter,
            child: data.list.any((e) => e.productId == p.id)
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AttentionCard(
                      product: p,
                      tag: p.available == 0 ? 'ACABOU' : 'ACABANDO',
                      detail: _lowDetail(p),
                      icon: CupertinoIcons.arrow_down_right,
                      actionLabel: 'Pôr na lista',
                      actionIcon: CupertinoIcons.add,
                      onAction: store.busy ? null : () => onSuggestion(p),
                      onProduct: (anchor) => onProduct(anchor, p),
                    ),
                  ),
          ),
        for (final p in due)
          Padding(
            key: ValueKey('expiry-${p.id}'),
            padding: const EdgeInsets.only(bottom: 12),
            child: _AttentionCard(
              product: p,
              tag: expiryLabel(p.nearestExpiry!, DateTime.now()).toUpperCase(),
              detail: '${p.location} · ${displayDate(p.nearestExpiry!)}',
              icon: CupertinoIcons.calendar,
              actionLabel: 'Conferir',
              actionIcon: CupertinoIcons.eye,
              onAction: null,
              onProduct: (anchor) => onProduct(anchor, p),
              opensProduct: true,
            ),
          ),
        if (pending == 0 && data.products.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.checkmark_circle, color: green, size: 19),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Nada pendente por aqui. Você decide quando repor.',
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        TouchSurface(
          label: 'Abrir lista da próxima compra',
          onTap: onList,
          child: Surface(
            color: ink,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('PRÓXIMA COMPRA', color: Color(0xFFB4C9BA)),
                      const SizedBox(height: 16),
                      AnimatedMoney(
                        value: data.planned,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 31,
                          letterSpacing: -1,
                          color: paper,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        data.budget == 0
                            ? 'Sem orçamento definido'
                            : data.planned > data.budget
                            ? '${money(data.planned - data.budget)} acima do orçamento'
                            : 'de ${money(data.budget)} · ${money(data.budget - data.planned)} de margem',
                        style: const TextStyle(
                          color: Color(0xFFB4C9BA),
                          fontSize: 12,
                        ),
                      ),
                      if (data.list.any(
                        (e) => e.priority != Priority.later && e.price == 0,
                      ))
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Estimativa parcial · há itens sem preço',
                            style: TextStyle(
                              color: Color(0xFFB4C9BA),
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                BumpOnChange(
                  value: data.list.length,
                  child: Container(
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: mint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${data.list.length}',
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          data.list.length == 1 ? 'item' : 'itens',
                          style: const TextStyle(color: green, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (opened.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            children: [
              Eyebrow('ABERTOS AGORA'),
              Text(
                'toque para ajustar',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 13),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (p, i) in opened)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Builder(
                      builder: (anchor) => TouchSurface(
                        key: ValueKey('jar-${p.id}-$i'),
                        onTap: store.busy ? null : () => onLevel(anchor, p, i),
                        label: 'Ajustar ${p.name}, embalagem ${i + 1}',
                        child: Container(
                          width: 112,
                          padding: const EdgeInsets.fromLTRB(9, 14, 9, 13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Column(
                            children: [
                              LiquidLevel(
                                key: ValueKey('${p.id}-$i'),
                                level: p.opened[i],
                                size: 64,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                p.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                levelNames[(p.opened[i] * 4).round()],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: muted,
                                ),
                              ),
                              if (p.opened.length > 1)
                                Text(
                                  'Aberta ${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.product,
    required this.tag,
    required this.detail,
    required this.icon,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    required this.onProduct,
    this.opensProduct = false,
  });
  final Product product;
  final String tag, detail, actionLabel;
  final IconData icon, actionIcon;
  final VoidCallback? onAction;
  final void Function(BuildContext) onProduct;
  final bool opensProduct;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          MediaQuery.textScalerOf(context).scale(1) > 1.2 ||
          constraints.maxWidth < 310;
      final information = Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: orange, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(detail, style: const TextStyle(color: muted, fontSize: 11)),
          ],
        ),
      );
      Widget action(BuildContext anchor) => FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const StadiumBorder(),
        ),
        onPressed: opensProduct ? () => onProduct(anchor) : onAction,
        icon: Icon(actionIcon, size: 15),
        label: Text(actionLabel, style: const TextStyle(fontSize: 12)),
      );
      return Builder(
        builder: (anchor) => TouchSurface(
          onTap: () => onProduct(anchor),
          child: Surface(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    ProductArt(product: product, size: compact ? 48 : 54),
                    const SizedBox(width: 12),
                    information,
                    if (!compact) ...[const SizedBox(width: 8), action(anchor)],
                  ],
                ),
                if (compact)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: action(anchor),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
