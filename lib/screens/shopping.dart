import 'package:flutter/material.dart';
import '../design.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';
import '../symbols.dart';

const _priorityDots = {
  Priority.essential: success,
  Priority.flexible: warning,
  Priority.later: faint,
};

class ShoppingContent extends StatelessWidget {
  const ShoppingContent({
    super.key,
    required this.store,
    required this.header,
    required this.onEdit,
    required this.onToggle,
    required this.onBudget,
  });
  final PantryStore store;
  final Widget header;
  final void Function(ShoppingItem) onEdit;
  final Future<void> Function(ShoppingItem) onToggle;
  final VoidCallback onBudget;
  @override
  Widget build(BuildContext context) {
    final data = store.data;
    final carting = data.list.any((e) => e.checked);
    return ListView(
      key: const PageStorageKey('shopping-scroll'),
      padding: tabPadding(context, extra: carting ? 64 : 0),
      children: [
        header,
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 2, 20, 0),
          child: Headline('Sua próxima compra.'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: TouchSurface(
            onTap: onBudget,
            label: 'Editar orçamento da compra',
            child: _PlannedBudget(data: data),
          ),
        ),
        for (final priority in Priority.values)
          if (data.list.any((e) => e.priority == priority)) ...[
            _GroupHeader(
              priority: priority,
              count: data.list.where((e) => e.priority == priority).length,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _Group(
                items: data.list.where((e) => e.priority == priority).toList(),
                data: data,
                busy: store.busy,
                onToggle: onToggle,
                onEdit: onEdit,
              ),
            ),
          ],
        if (data.list.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: EmptyState(
              title: 'Uma lista leve.',
              message: 'Use o + ou toque em “Pôr na lista” no Hoje.',
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
          child: Text(
            data.list.isEmpty
                ? 'Marcar não mexe no estoque. Só ao guardar a compra.'
                : 'Marcar não mexe no estoque. Só ao guardar a compra.\nToque e segure um item para editar.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: faint),
          ),
        ),
      ],
    );
  }
}

class _PlannedBudget extends StatelessWidget {
  const _PlannedBudget({required this.data});
  final AppData data;
  @override
  Widget build(BuildContext context) {
    final over = data.budget > 0 && data.planned > data.budget;
    final missing = data.list
        .where((e) => e.priority != Priority.later && e.price == 0)
        .length;
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Planejado',
                  style: TextStyle(fontSize: 14, color: muted),
                ),
              ),
              Tag(
                data.budget == 0 ? 'Definir' : money(data.budget),
                icon: Symbols.edit,
                size: 12,
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedMoney(
            value: data.planned,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 12),
          BudgetTrack(
            planned: data.planned,
            cart: data.cart,
            budget: data.budget,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  data.budget == 0
                      ? 'Toque para definir um orçamento'
                      : over
                      ? '${money(data.planned - data.budget)} acima'
                      : '${money(data.budget - data.planned)} de margem',
                  style: TextStyle(
                    fontSize: 12,
                    color: over ? dangerInk : muted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${data.list.length} ${data.list.length == 1 ? 'item' : 'itens'}',
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
          if (missing > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Estimativa parcial · $missing ${missing == 1 ? 'item sem preço' : 'itens sem preço'}',
                style: const TextStyle(fontSize: 11, color: faint),
              ),
            ),
        ],
      ),
    );
  }
}

/// Planned spending over the budget; with [cart], the marked items are layered on top.
class BudgetTrack extends StatelessWidget {
  const BudgetTrack({
    super.key,
    required this.planned,
    required this.budget,
    this.cart,
  });
  final double planned, budget;
  final double? cart;
  @override
  Widget build(BuildContext context) {
    final over = budget > 0 && planned > budget;
    Widget bar(double value, Color color) => Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: budget <= 0 ? 0 : (value / budget).clamp(0, 1)),
        duration: motionTime(context, 450),
        curve: Curves.ease,
        builder: (_, width, _) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: zinc200)),
            bar(
              planned,
              cart == null
                  ? (over ? danger : primary)
                  : (over ? const Color(0xFFFAA0BF) : const Color(0xFF99C7FB)),
            ),
            if (cart != null) bar(cart!, primary),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.priority, required this.count});
  final Priority priority;
  final int count;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
    child: Row(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 26),
          padding: const EdgeInsets.fromLTRB(8, 2, 10, 2),
          decoration: BoxDecoration(
            border: Border.all(color: zinc200, width: 2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _priorityDots[priority],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                priority.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          priority == Priority.later
              ? 'fora do total'
              : '$count ${count == 1 ? 'item' : 'itens'}',
          style: const TextStyle(fontSize: 12, color: muted),
        ),
      ],
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group({
    required this.items,
    required this.data,
    required this.busy,
    required this.onToggle,
    required this.onEdit,
  });
  final List<ShoppingItem> items;
  final AppData data;
  final bool busy;
  final Future<void> Function(ShoppingItem) onToggle;
  final void Function(ShoppingItem) onEdit;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: shadowMedium,
    ),
    child: Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          for (final (i, item) in items.indexed)
            _ShoppingRow(
              key: ValueKey(item.id),
              item: item,
              product: data.product(item.productId),
              last: i == items.length - 1,
              onToggle: busy ? null : () => onToggle(item),
              onEdit: () => onEdit(item),
            ),
        ],
      ),
    ),
  );
}

class _ShoppingRow extends StatelessWidget {
  const _ShoppingRow({
    super.key,
    required this.item,
    required this.product,
    required this.last,
    required this.onToggle,
    required this.onEdit,
  });
  final ShoppingItem item;
  final Product? product;
  final bool last;
  final VoidCallback? onToggle;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final checked = item.checked, later = item.priority == Priority.later;
    final details = [
      '${item.quantity} ${item.quantity == 1 ? 'unidade' : 'unidades'}',
      if (product != null && product!.pack.isNotEmpty) product!.pack,
      if (item.price > 0) '${money(item.price)} cada',
      if (item.expiry != null) 'validade ${displayDate(item.expiry!)}',
    ].join(' · ');
    return Semantics(
      checked: checked,
      label: 'No carrinho: ${item.name}',
      onLongPressHint: 'Editar',
      child: InkWell(
        onTap: onToggle,
        onLongPress: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 16, 0),
          child: Row(
            children: [
              AnimatedContainer(
                key: ValueKey('cart-${item.id}'),
                duration: motionTime(context, 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: checked ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: checked ? primary : zinc300,
                    width: 2,
                  ),
                ),
                child: AnimatedOpacity(
                  opacity: checked ? 1 : 0,
                  duration: motionTime(context, 200),
                  child: const Icon(
                    Symbols.check,
                    size: 15,
                    weight: 600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 60),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: last ? Colors.transparent : zinc100,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: motionTime(context, 200),
                              style: DefaultTextStyle.of(context).style
                                  .copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: checked ? faint : fg,
                                    decoration: checked
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    decorationColor: faint,
                                  ),
                              child: Text(item.name),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              details,
                              style: const TextStyle(
                                fontSize: 12,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedDefaultTextStyle(
                        duration: motionTime(context, 200),
                        style: DefaultTextStyle.of(context).style.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: checked || later ? faint : fg,
                        ),
                        child: Text(
                          item.price == 0 ? 'Sem preço' : money(item.total),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
