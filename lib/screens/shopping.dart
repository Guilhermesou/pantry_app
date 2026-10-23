import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../design.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';

class ShoppingContent extends StatefulWidget {
  const ShoppingContent({
    super.key,
    required this.store,
    required this.onEdit,
    required this.onToggle,
    required this.onBudget,
    required this.onCheckout,
    required this.onAdd,
  });
  final PantryStore store;
  final void Function(BuildContext, ShoppingItem) onEdit;
  final Future<void> Function(ShoppingItem) onToggle;
  final void Function(BuildContext) onBudget, onAdd;
  final Future<void> Function() onCheckout;
  @override
  State<ShoppingContent> createState() => _ShoppingContentState();
}

class _ShoppingContentState extends State<ShoppingContent> {
  bool cartExpanded = false;
  @override
  Widget build(BuildContext context) {
    final data = widget.store.data;
    return LayoutBuilder(
      builder: (context, bounds) => Column(
        children: [
          Expanded(
            child: ListView(
              key: const PageStorageKey('shopping-scroll'),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(child: Editorial('Sua próxima\ncompra.')),
                    Text(
                      '${data.list.where((e) => e.checked).length} de ${data.list.length} itens',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Builder(
                  builder: (anchor) => TouchSurface(
                    onTap: () => widget.onBudget(anchor),
                    label: 'Editar orçamento da compra',
                    child: _PlannedBudget(data: data),
                  ),
                ),
                if (data.list.isEmpty)
                  EmptyState(
                    icon: CupertinoIcons.bag,
                    title: 'Uma lista leve.',
                    message:
                        'Adicione o que precisa agora.\nO que pode esperar também tem seu lugar.',
                    action: Builder(
                      builder: (anchor) => FilledButton(
                        onPressed: () => widget.onAdd(anchor),
                        child: const Text('Montar minha lista'),
                      ),
                    ),
                  ),
                for (final priority in Priority.values)
                  if (data.list.any((e) => e.priority == priority)) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: priority == Priority.essential
                                ? green
                                : priority == Priority.flexible
                                ? orange
                                : muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Eyebrow(priority.label)),
                        Text(
                          priority == Priority.later
                              ? 'fora do total'
                              : '${data.list.where((e) => e.priority == priority).length}',
                          style: const TextStyle(fontSize: 10, color: muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: ColoredBox(
                        color: Colors.white,
                        child: Column(
                          children: [
                            for (final item in data.list.where(
                              (e) => e.priority == priority,
                            ))
                              _ShoppingRow(
                                key: ValueKey(item.id),
                                item: item,
                                product: data.product(item.productId),
                                busy: widget.store.busy,
                                onToggle: () => widget.onToggle(item),
                                onEdit: (anchor) => widget.onEdit(anchor, item),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                if (data.list.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 18, 8, 0),
                    child: Text(
                      'Marcar não altera o estoque. Só ao guardar a compra.\nToque no nome para editar quantidade e preço.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: AnimatedSize(
              duration: motionTime(context, 420),
              curve: Curves.easeInOutCubicEmphasized,
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: bounds.maxHeight * .48),
                child: _CartPanel(
                  data: data,
                  expanded: cartExpanded,
                  busy: widget.store.busy,
                  onToggle: () => setState(() => cartExpanded = !cartExpanded),
                  onBudget: widget.onBudget,
                  onCheckout: () async {
                    await widget.onCheckout();
                    if (mounted &&
                        !widget.store.data.list.any((e) => e.checked)) {
                      setState(() => cartExpanded = false);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannedBudget extends StatelessWidget {
  const _PlannedBudget({required this.data});
  final AppData data;
  @override
  Widget build(BuildContext context) {
    final missing = data.list
        .where((e) => e.priority != Priority.later && e.price == 0)
        .length;
    return Surface(
      color: ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Eyebrow('PLANEJADO', color: Color(0xFFB4C9BA)),
              ),
              const Icon(
                CupertinoIcons.pencil,
                size: 15,
                color: Color(0xFFB4C9BA),
              ),
            ],
          ),
          const SizedBox(height: 13),
          AnimatedMoney(
            value: data.planned,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 33,
              color: paper,
              letterSpacing: -1,
            ),
          ),
          if (data.budget > 0) ...[
            const SizedBox(height: 17),
            BudgetTrack(
              planned: data.planned,
              cart: data.cart,
              budget: data.budget,
            ),
            const SizedBox(height: 10),
          ],
          Text(
            data.budget == 0
                ? 'Toque para definir um orçamento'
                : data.planned > data.budget
                ? '${money(data.planned - data.budget)} acima de ${money(data.budget)}'
                : '${money(data.budget - data.planned)} de margem · de ${money(data.budget)}',
            style: const TextStyle(color: Color(0xFFB4C9BA), fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            missing > 0
                ? 'Estimativa parcial · $missing ${missing == 1 ? 'item sem preço' : 'itens sem preço'}'
                : 'Estimativa com os preços informados',
            style: const TextStyle(color: Color(0xFFB4C9BA), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class BudgetTrack extends StatelessWidget {
  const BudgetTrack({
    super.key,
    required this.planned,
    required this.cart,
    required this.budget,
  });
  final double planned, cart, budget;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: SizedBox(
      width: double.infinity,
      height: 5,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.white12)),
          TweenAnimationBuilder<double>(
            tween: Tween(end: budget <= 0 ? 0 : (planned / budget).clamp(0, 1)),
            duration: motionTime(context, 450),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => FractionallySizedBox(
              widthFactor: value,
              heightFactor: 1,
              child: ColoredBox(
                color: planned > budget
                    ? const Color(0xFFE9AE88)
                    : const Color(0xFF6E9C82),
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(end: budget <= 0 ? 0 : (cart / budget).clamp(0, 1)),
            duration: motionTime(context, 450),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => FractionallySizedBox(
              widthFactor: value,
              heightFactor: 1,
              child: const ColoredBox(color: mint),
            ),
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
    required this.busy,
    required this.onToggle,
    required this.onEdit,
  });
  final ShoppingItem item;
  final Product? product;
  final bool busy;
  final VoidCallback onToggle;
  final void Function(BuildContext) onEdit;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 0, 16, 0),
    child: Row(
      children: [
        Semantics(
          label: 'No carrinho: ${item.name}',
          checked: item.checked,
          child: Checkbox(
            key: ValueKey('cart-${item.id}'),
            value: item.checked,
            onChanged: busy ? null : (_) => onToggle(),
            shape: const CircleBorder(),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (anchor) => InkWell(
              onTap: () => onEdit(anchor),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: lineColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: motionTime(context, 200),
                            style: TextStyle(
                              fontFamily: '.SF Pro Text',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: item.checked ? muted : ink,
                              decoration: item.checked
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                            child: Text(item.name),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.quantity} ${item.quantity == 1 ? 'unidade' : 'unidades'}${product == null || product!.pack.isEmpty ? '' : ' · ${product!.pack}'}',
                            style: const TextStyle(fontSize: 11, color: muted),
                          ),
                          if (item.expiry != null)
                            Text(
                              'Validade ${displayDate(item.expiry!)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.price == 0 ? 'Sem preço' : money(item.total),
                      style: TextStyle(
                        fontSize: 12,
                        color: item.checked || item.priority == Priority.later
                            ? muted
                            : ink,
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
  );
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.data,
    required this.expanded,
    required this.busy,
    required this.onToggle,
    required this.onBudget,
    required this.onCheckout,
  });
  final AppData data;
  final bool expanded, busy;
  final VoidCallback onToggle;
  final void Function(BuildContext) onBudget;
  final VoidCallback onCheckout;
  @override
  Widget build(BuildContext context) {
    final count = data.list.where((e) => e.checked).length;
    final unknown = data.list.where((e) => e.checked && e.price == 0).length;
    return Container(
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: .13),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              expanded: expanded,
              label: expanded ? 'Recolher carrinho' : 'Expandir carrinho',
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 15, 16, 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedMoney(
                              value: data.cart,
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 26,
                                color: paper,
                                letterSpacing: -.7,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              count == 0
                                  ? 'Nada no carrinho ainda'
                                  : '$count ${count == 1 ? 'item no carrinho' : 'itens no carrinho'}${unknown > 0 ? ' · estimativa parcial' : ''}',
                              style: const TextStyle(
                                color: Color(0xFFB4C9BA),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      BumpOnChange(
                        value: count,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: mint,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.cart,
                                size: 19,
                                color: ink,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                '$count',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      AnimatedRotation(
                        turns: expanded ? .5 : 0,
                        duration: motionTime(context, 280),
                        child: const Icon(
                          CupertinoIcons.chevron_up,
                          size: 16,
                          color: Color(0xFFB4C9BA),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.budget > 0) ...[
                      BudgetTrack(
                        planned: data.planned,
                        cart: data.cart,
                        budget: data.budget,
                      ),
                      const SizedBox(height: 13),
                    ],
                    Text(
                      'Planejado: ${money(data.planned)} · no carrinho: ${money(data.cart)}',
                      style: const TextStyle(
                        color: Color(0xFFB4C9BA),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      data.budget == 0
                          ? 'Sem orçamento definido'
                          : data.cart > data.budget
                          ? '${money(data.cart - data.budget)} acima do orçamento no carrinho'
                          : '${money(data.budget - data.cart)} disponíveis após o carrinho',
                      style: const TextStyle(color: paper, fontSize: 12),
                    ),
                    if (unknown > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          '$unknown ${unknown == 1 ? 'item marcado sem preço' : 'itens marcados sem preço'}. Confira antes de guardar.',
                          style: const TextStyle(
                            color: Color(0xFFE9AE88),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    Builder(
                      builder: (anchor) => TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB4C9BA),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () => onBudget(anchor),
                        child: const Text(
                          'Ajustar orçamento',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (count > 0)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: mint,
                            foregroundColor: ink,
                            disabledBackgroundColor: mint.withValues(
                              alpha: .55,
                            ),
                            disabledForegroundColor: ink.withValues(alpha: .6),
                          ),
                          onPressed: busy || count == 0 ? null : onCheckout,
                          icon: const Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 18,
                          ),
                          label: const Text('Concluir compra'),
                        ),
                      ),
                    if (count == 0)
                      const Text(
                        'Marque os itens que comprou para guardar no estoque.',
                        style: TextStyle(
                          color: Color(0xFFB4C9BA),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
