import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design.dart';
import '../illustration.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';
import '../symbols.dart';

typedef _PlaceStyle = ({
  Color frame,
  double radius,
  double innerRadius,
  Color inside,
  Color shelf,
  bool handle,
  double padRight,
});

const Map<String, _PlaceStyle> _placeStyles = {
  'Geladeira': (
    frame: zinc200,
    radius: 30,
    innerRadius: 22,
    inside: Color(0xFFF5F9FF),
    shelf: Color(0x1F006FEE),
    handle: true,
    padRight: 20,
  ),
  'Freezer': (
    frame: zinc200,
    radius: 22,
    innerRadius: 14,
    inside: Color(0xFFF0F7FF),
    shelf: Color(0x29006FEE),
    handle: true,
    padRight: 20,
  ),
  'Despensa': (
    frame: Color(0xFFE7E2DA),
    radius: 12,
    innerRadius: 6,
    inside: Color(0xFFFAF8F5),
    shelf: Color(0xFFE7E2DA),
    handle: false,
    padRight: 10,
  ),
  'Farmacinha': (
    frame: Color(0xFFF7D9E4),
    radius: 14,
    innerRadius: 8,
    inside: Color(0xFFFFFAFC),
    shelf: Color(0x1FF31260),
    handle: true,
    padRight: 20,
  ),
};
const _PlaceStyle _defaultPlace = (
  frame: zinc200,
  radius: 18,
  innerRadius: 10,
  inside: zinc50,
  shelf: zinc200,
  handle: false,
  padRight: 10,
);

class StockContent extends StatefulWidget {
  const StockContent({
    super.key,
    required this.store,
    required this.header,
    required this.onProduct,
    required this.onAdd,
  });
  final PantryStore store;
  final Widget header;
  final void Function(Product) onProduct;
  final VoidCallback onAdd;
  @override
  State<StockContent> createState() => _StockContentState();
}

class _StockContentState extends State<StockContent> {
  final search = TextEditingController();
  String filter = 'Todos', view = 'list';
  String? place;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.store.data;
    final used = locations
        .where((l) => data.products.any((p) => p.location == l))
        .toList();
    return ListView(
      key: const PageStorageKey('stock-scroll'),
      padding: tabPadding(context),
      children: [
        widget.header,
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 2, 20, 0),
          child: Headline('Seu estoque.'),
        ),
        if (data.products.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: EmptyState(
              title: 'Sua casa, organizada.',
              message:
                  'Adicione o que já tem em casa.\nPode ser pela câmera ou do seu jeito.',
              action: AppButton(
                label: 'Adicionar produto',
                icon: Symbols.add,
                glow: true,
                onPressed: widget.onAdd,
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Stat(
                      value: data.products.length,
                      label: 'produtos em casa',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TouchSurface(
                      label: 'Filtrar produtos acabando',
                      onTap: () => setState(() {
                        filter = 'Acabando';
                        view = 'list';
                      }),
                      child: _Stat(
                        value: data.products.where((p) => p.low).length,
                        label: 'para ficar de olho',
                        dot: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: SegmentedPicker<String>(
              keyPrefix: 'stock-view',
              options: const [
                ('list', 'Lista', Symbols.viewAgenda),
                ('place', 'Por lugar', Symbols.kitchen),
              ],
              selected: view,
              onSelected: (value) => setState(() => view = value),
            ),
          ),
          if (view == 'list') ..._list(data) else ..._places(data, used),
        ],
      ],
    );
  }

  List<Widget> _list(AppData data) {
    final now = DateTime.now();
    final used = locations.where(
      (l) => data.products.any((p) => p.location == l),
    );
    final shown = data.products
        .where(
          (p) =>
              normalized(
                '${p.name} ${p.brand}',
              ).contains(normalized(search.text)) &&
              (filter == 'Todos' ||
                  filter == 'Acabando' && p.low ||
                  filter == 'Abertos' && p.opened.isNotEmpty ||
                  filter == 'Validades' && p.needsExpiryAttention(now) ||
                  filter == 'Remédios' && p.category == 'Remédios' ||
                  p.location == filter),
        )
        .toList();
    if (filter == 'Validades') {
      shown.sort((a, b) => a.nearestExpiry!.compareTo(b.nearestExpiry!));
    }
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: TextField(
          key: const ValueKey('stock-search'),
          controller: search,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'O que você está procurando?',
            prefixIcon: Icon(Symbols.search, size: 20),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: FilterPills(
          options: [
            'Todos',
            'Acabando',
            'Abertos',
            'Validades',
            if (data.products.any((p) => p.category == 'Remédios')) 'Remédios',
            ...used,
          ],
          selected: filter,
          onSelected: (value) => setState(() => filter = value),
        ),
      ),
      if (shown.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              Text(
                'Nada por aqui.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'Tente outro nome ou filtro.',
                style: TextStyle(fontSize: 13, color: muted),
              ),
            ],
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
          child: Container(
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
                  for (final (i, p) in shown.indexed)
                    _StockRow(
                      key: ValueKey('stock-${p.id}'),
                      product: p,
                      last: i == shown.length - 1,
                      now: now,
                      onTap: () => widget.onProduct(p),
                    ),
                ],
              ),
            ),
          ),
        ),
      const Padding(
        padding: EdgeInsets.fromLTRB(32, 18, 32, 0),
        child: Text(
          'Sem balança, sem complicação. Os níveis dos abertos são estimativas suas.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: faint),
        ),
      ),
    ];
  }

  List<Widget> _places(AppData data, List<String> used) {
    final current = used.contains(place) ? place! : used.first;
    final style = _placeStyles[current] ?? _defaultPlace;
    final here = data.products
        .where((p) => p.location == current && p.available > 0)
        .toList();
    final preposition = current == 'Freezer' || current == 'Banheiro'
        ? 'no'
        : 'na';
    return [
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: FilterPills(
          options: used,
          selected: current,
          onSelected: (value) => setState(() => place = value),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: _PlaceFrame(
          style: style,
          products: here,
          onProduct: widget.onProduct,
        ),
      ),
      if (style.handle)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 44),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 2; i++)
                Container(
                  width: 22,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: zinc300,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            const Tag(
              'Experimental',
              background: secondarySoft,
              foreground: secondaryInk,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                here.isEmpty
                    ? 'Nada guardado aqui.'
                    : '${here.length} ${here.length == 1 ? 'produto' : 'produtos'} $preposition ${current.toLowerCase()}. Toque para abrir.',
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.dot = false});
  final int value;
  final String label;
  final bool dot;
  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    shadow: shadowSmall,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$value',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            if (dot) ...[
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: warning,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: dot ? warningInk : muted),
        ),
      ],
    ),
  );
}

class _StockRow extends StatelessWidget {
  const _StockRow({
    super.key,
    required this.product,
    required this.last,
    required this.now,
    required this.onTap,
  });
  final Product product;
  final bool last;
  final DateTime now;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = product;
    final level = p.opened.isEmpty ? 0.0 : p.opened.first;
    final expiry = p.nearestExpiry;
    final urgent = p.needsExpiryAttention(now);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: last ? Colors.transparent : zinc100),
          ),
        ),
        child: Row(
          children: [
            ProductArt(product: p, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    [
                      p.pack,
                      p.location,
                      p.stockLabel,
                    ].where((s) => s.isNotEmpty).join(' · '),
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                  if (p.opened.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: SizedBox(
                            width: 64,
                            height: 4,
                            child: ColoredBox(
                              color: zinc200,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(end: level),
                                duration: motionTime(context, 400),
                                curve: Curves.ease,
                                builder: (_, value, _) => FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: value,
                                  child: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: primary,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(999),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${levelNames[(level * 4).round()]} · aprox.',
                            style: const TextStyle(fontSize: 11, color: muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (expiry != null) ...[
                    const SizedBox(height: 6),
                    Tag(
                      expiryLabel(expiry, now),
                      icon: Symbols.event,
                      background: urgent ? warningSoft : zinc100,
                      foreground: urgent ? warningInk : muted,
                    ),
                  ],
                ],
              ),
            ),
            if (p.low) ...[
              const SizedBox(width: 8),
              const Tag(
                'Baixo',
                background: warningSoft,
                foreground: warningInk,
              ),
            ],
            const Icon(Symbols.chevronRight, size: 20, color: faint),
          ],
        ),
      ),
    );
  }
}

class _PlaceFrame extends StatelessWidget {
  const _PlaceFrame({
    required this.style,
    required this.products,
    required this.onProduct,
  });
  final _PlaceStyle style;
  final List<Product> products;
  final void Function(Product) onProduct;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        padding: EdgeInsets.fromLTRB(10, 10, style.padRight, 10),
        decoration: BoxDecoration(
          color: style.frame,
          borderRadius: BorderRadius.circular(style.radius),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: style.inside,
            borderRadius: BorderRadius.circular(style.innerRadius),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final perShelf = math.max(
                      1,
                      ((constraints.maxWidth - 4 + 6) / 70).floor(),
                    );
                    final shelves = math.max(
                      3,
                      (products.length / perShelf).ceil(),
                    );
                    return Column(
                      children: [
                        for (var s = 0; s < shelves; s++)
                          Container(
                            constraints: const BoxConstraints(minHeight: 98),
                            alignment: Alignment.bottomLeft,
                            padding: const EdgeInsets.fromLTRB(2, 14, 2, 0),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: style.shelf,
                                  width: 5,
                                ),
                              ),
                            ),
                            child: Wrap(
                              spacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.end,
                              children: [
                                for (final p
                                    in products
                                        .skip(s * perShelf)
                                        .take(perShelf))
                                  _ShelfSlot(
                                    product: p,
                                    onTap: () => onProduct(p),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              // A soft inner shadow under the top edge.
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 10,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x0D000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      if (style.handle)
        Positioned(
          right: 6,
          top: 36,
          child: Container(
            width: 5,
            height: 90,
            decoration: BoxDecoration(
              color: zinc300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
    ],
  );
}

class _ShelfSlot extends StatelessWidget {
  const _ShelfSlot({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = product, count = p.closed + p.opened.length;
    return Semantics(
      button: true,
      label: '${p.name}, $count ${count == 1 ? 'embalagem' : 'embalagens'}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 64,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    PackageIllustration(
                      product: p,
                      level: p.closed > 0 ? 1 : p.opened.first,
                      width: 40,
                      shadow: false,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.name.split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: zinc600,
                      ),
                    ),
                  ],
                ),
                if (count > 1)
                  Positioned(
                    top: -6,
                    right: 6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: fg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '$count',
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (p.low)
                  Positioned(
                    top: -2,
                    left: 10,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: warning,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
