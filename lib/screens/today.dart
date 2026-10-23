import 'package:flutter/material.dart';
import '../design.dart';
import '../illustration.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';
import '../symbols.dart';
import 'quick_level.dart' show levelChange;
import 'shopping.dart' show BudgetTrack;

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
  return '${days[date.weekday - 1]}, ${date.day} de ${monthNames[date.month - 1]}';
}

String capitalized(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

String attentionHeadline(int count, bool empty) {
  if (empty) return 'Sua casa,\nno seu ritmo.';
  if (count == 0) return 'Tudo no seu lugar.';
  if (count == 1) return 'Uma coisa pede atenção.';
  const words = {2: 'Duas', 3: 'Três', 4: 'Quatro', 5: 'Cinco'};
  return '${words[count] ?? count} coisas pedem atenção.';
}

/// Identifies an acknowledged expiry; a new nearest date asks again.
String expiryKey(Product p) => '${p.id}@${dateOnly(p.nearestExpiry!)}';

String _lowDetail(Product p) {
  final opened = p.opened.isEmpty
      ? ''
      : '${levelNames[(p.opened.first * 4).round()]} aberto · ';
  return '$opened${p.closed} ${p.closed == 1 ? 'fechado' : 'fechados'} · mín. ${p.minimum.toStringAsFixed(0)}';
}

String _expiryDetail(Product p) {
  final lot = p.activeLots.first;
  return lot.closed == 0
      ? '${p.location} · embalagem aberta do lote'
      : '${p.location} · ${lot.closed} ${lot.closed == 1 ? 'fechado' : 'fechados'} no lote';
}

List<Product> attentionProducts(AppData data, DateTime now) =>
    data.products.where((p) => p.low || p.needsExpiryAttention(now)).toList();

/// A low product asks for replenishment; otherwise the card is about its expiry.
bool attentionDone(AppData data, Set<String> seen, Product p) => p.low
    ? data.list.any((e) => e.productId == p.id)
    : seen.contains(expiryKey(p));

int pendingAttention(AppData data, Set<String> seen, DateTime now) =>
    attentionProducts(
      data,
      now,
    ).where((p) => !attentionDone(data, seen, p)).length;

class TodayContent extends StatelessWidget {
  const TodayContent({
    super.key,
    required this.store,
    required this.header,
    required this.seen,
    required this.onSeen,
    required this.onList,
    required this.onAdd,
    required this.onProduct,
    required this.onLevelDown,
    required this.onLevelDetail,
    required this.onSuggestion,
  });
  final PantryStore store;
  final Widget header;
  final Set<String> seen;
  final void Function(Product) onSeen, onProduct;
  final VoidCallback onList, onAdd;
  final void Function(Product, int) onLevelDown, onLevelDetail;
  final Future<void> Function(Product) onSuggestion;
  @override
  Widget build(BuildContext context) {
    final data = store.data, now = DateTime.now();
    bool inList(Product p) => data.list.any((e) => e.productId == p.id);
    final attention = attentionProducts(data, now);
    bool done(Product p) => attentionDone(data, seen, p);
    final pending = attention.where((p) => !done(p)).length;
    final opened = [
      for (final p in data.products)
        for (var i = 0; i < p.opened.length; i++) (p, i),
    ];
    final headline = attentionHeadline(pending, data.products.isEmpty);
    return ListView(
      key: const PageStorageKey('today-scroll'),
      padding: tabPadding(context),
      children: [
        header,
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
          child: AnimatedSwitcher(
            duration: motionTime(context, 240),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, ?current],
            ),
            child: Align(
              key: ValueKey(headline),
              alignment: Alignment.centerLeft,
              child: Headline(headline),
            ),
          ),
        ),
        if (data.products.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: EmptyState(
              title: 'Vamos conhecer sua casa.',
              message:
                  'Cadastre o que você já tem.\nAs sugestões aparecem no seu ritmo.',
              action: AppButton(
                label: 'Adicionar meu primeiro produto',
                icon: Symbols.add,
                glow: true,
                onPressed: onAdd,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                for (final p in attention)
                  Collapsible(
                    key: ValueKey('attention-${p.id}-${p.low ? 'low' : 'exp'}'),
                    collapsed: done(p),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: p.low
                          ? _lowCard(p, inList(p))
                          : _expiryCard(p, done(p), now),
                    ),
                  ),
                if (pending == 0)
                  const PopIn(
                    delay: .5,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 4, 0, 18),
                      child: Row(
                        children: [
                          Icon(
                            Symbols.checkCircle,
                            size: 20,
                            fill: 1,
                            color: success,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nada mais pedindo atenção por hoje.',
                              style: TextStyle(fontSize: 14, color: muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: TouchSurface(
            label: 'Abrir lista da próxima compra',
            onTap: onList,
            child: _NextPurchase(data: data),
          ),
        ),
        if (opened.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'Abertos agora',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Flexible(
                  child: Text(
                    'toque para baixar o nível',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (p, i) in opened)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _OpenedJar(
                      key: ValueKey('jar-${p.id}-$i'),
                      product: p,
                      level: p.opened[i],
                      onTap: store.busy ? null : () => onLevelDown(p, i),
                      onLongPress: () => onLevelDetail(p, i),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _lowCard(Product p, bool done) {
    final out = p.available == 0;
    return _AttentionCard(
      product: p,
      detail: _lowDetail(p),
      tag: Tag(
        done
            ? 'Na lista'
            : out
            ? 'Acabou'
            : 'Acabando',
        icon: done ? Symbols.check : Symbols.trendingDown,
        background: done
            ? successSoft
            : out
            ? dangerSoft
            : warningSoft,
        foreground: done
            ? successInk
            : out
            ? dangerInk
            : warningInk,
      ),
      action: AppButton(
        label: 'Pôr na lista',
        icon: done ? Symbols.check : Symbols.add,
        tone: done ? ButtonTone.success : ButtonTone.solid,
        height: 32,
        onPressed: done
            ? () {}
            : store.busy
            ? null
            : () => onSuggestion(p),
      ),
      onOpen: () => onProduct(p),
    );
  }

  Widget _expiryCard(Product p, bool done, DateTime now) {
    final expired = daysUntil(p.nearestExpiry!, now) < 0;
    return _AttentionCard(
      product: p,
      detail: _expiryDetail(p),
      tag: Tag(
        done ? 'Conferido' : expiryLabel(p.nearestExpiry!, now),
        icon: done ? Symbols.check : Symbols.event,
        background: done
            ? successSoft
            : expired
            ? dangerSoft
            : warningSoft,
        foreground: done
            ? successInk
            : expired
            ? dangerInk
            : warningInk,
      ),
      action: AppButton(
        label: 'Vi',
        icon: done ? Symbols.check : Symbols.visibility,
        tone: done ? ButtonTone.success : ButtonTone.soft,
        height: 32,
        onPressed: done ? () {} : () => onSeen(p),
      ),
      onOpen: () => onProduct(p),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.product,
    required this.detail,
    required this.tag,
    required this.action,
    required this.onOpen,
  });
  final Product product;
  final String detail;
  final Widget tag, action;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          MediaQuery.textScalerOf(context).scale(1) > 1.2 ||
          constraints.maxWidth < 310;
      return TouchSurface(
        onTap: onOpen,
        label: 'Abrir ${product.name}',
        child: Surface(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  ProductArt(product: product),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                        const SizedBox(height: 6),
                        tag,
                      ],
                    ),
                  ),
                  if (!compact) ...[const SizedBox(width: 12), action],
                ],
              ),
              if (compact)
                Padding(padding: const EdgeInsets.only(top: 10), child: action),
            ],
          ),
        ),
      );
    },
  );
}

class _NextPurchase extends StatelessWidget {
  const _NextPurchase({required this.data});
  final AppData data;
  @override
  Widget build(BuildContext context) {
    final count = data.list.length;
    final over = data.budget > 0 && data.planned > data.budget;
    final partial = data.list.any(
      (e) => e.priority != Priority.later && e.price == 0,
    );
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Próxima compra',
                  style: TextStyle(fontSize: 14, color: muted),
                ),
              ),
              BumpOnChange(
                value: count,
                child: Tag(
                  '$count ${count == 1 ? 'item' : 'itens'}',
                  background: primarySoft,
                  foreground: primaryInk,
                  size: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedMoney(
            value: data.planned,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 12),
          BudgetTrack(planned: data.planned, budget: data.budget),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  data.budget == 0
                      ? 'Sem orçamento definido'
                      : 'de ${money(data.budget)}',
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ),
              if (data.budget > 0) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    over
                        ? '${money(data.planned - data.budget)} acima'
                        : '${money(data.budget - data.planned)} de margem',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      color: over ? dangerInk : muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (partial)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Estimativa parcial · há itens sem preço',
                style: TextStyle(fontSize: 11, color: faint),
              ),
            ),
        ],
      ),
    );
  }
}

class _OpenedJar extends StatelessWidget {
  const _OpenedJar({
    super.key,
    required this.product,
    required this.level,
    required this.onTap,
    required this.onLongPress,
  });
  final Product product;
  final double level;
  final VoidCallback? onTap, onLongPress;
  @override
  Widget build(BuildContext context) {
    final name = levelNames[(level * 4).round()];
    return TouchSurface(
      onTap: onTap,
      onLongPress: onLongPress,
      label:
          '${product.name}, $name. Toque para baixar um quarto; toque e segure para ajustar.',
      child: Container(
        width: 104,
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: shadowSmall,
        ),
        child: Column(
          children: [
            RiseOnChange(
              value: level,
              describe: levelChange,
              child: PackageIllustration(product: product, level: level),
            ),
            const SizedBox(height: 10),
            Text(
              product.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              '$name · ${(level * 100).round()}%',
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
