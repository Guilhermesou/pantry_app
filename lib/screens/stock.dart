import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../design.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';

String levelFraction(double level) => switch ((level * 4).round()) {
  1 => '¼',
  2 => '½',
  3 => '¾',
  _ => 'Cheio',
};

class StockContent extends StatefulWidget {
  const StockContent({
    super.key,
    required this.store,
    required this.onProduct,
    required this.onLevel,
    required this.onOpen,
    required this.onAdd,
  });
  final PantryStore store;
  final void Function(BuildContext, Product) onProduct;
  final void Function(BuildContext, Product, int) onLevel;
  final Future<void> Function(Product) onOpen;
  final void Function(BuildContext) onAdd;
  @override
  State<StockContent> createState() => _StockContentState();
}

class _StockContentState extends State<StockContent> {
  String query = '', filter = 'Todos';
  @override
  Widget build(BuildContext context) {
    final data = widget.store.data, now = DateTime.now();
    final attention = data.products
        .where((p) => p.needsExpiryAttention(now))
        .length;
    final products = data.products
        .where(
          (p) =>
              normalized('${p.name} ${p.brand}').contains(normalized(query)) &&
              (filter == 'Todos' ||
                  filter == 'Acabando' && p.low ||
                  filter == 'Abertos' && p.opened.isNotEmpty ||
                  filter == 'Validades' && p.needsExpiryAttention(now) ||
                  p.location == filter),
        )
        .toList();
    if (filter == 'Validades') {
      products.sort((a, b) => a.nearestExpiry!.compareTo(b.nearestExpiry!));
    }
    final groupedLocations = locations.where(
      (location) => products.any((p) => p.location == location),
    );
    return ListView(
      key: const PageStorageKey('stock-scroll'),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      children: [
        const Editorial('Seu estoque.'),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Surface(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.products.length}',
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'produtos em casa',
                      style: TextStyle(fontSize: 11, color: green),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TouchSurface(
                onTap: () => setState(() => filter = 'Acabando'),
                label: 'Filtrar produtos acabando',
                child: Surface(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.products.where((p) => p.low).length}',
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'para ficar de olho',
                        style: TextStyle(fontSize: 11, color: orange),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (attention > 0)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Surface(
              color: peach,
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.calendar, size: 18, color: orange),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '$attention ${attention == 1 ? 'produto com validade' : 'produtos com validades'} para conferir',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => filter = 'Validades'),
                    child: const Text('Conferir'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('stock-search'),
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(
            hintText: 'O que você está procurando?',
            prefixIcon: Icon(CupertinoIcons.search, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in [
                'Todos',
                'Acabando',
                'Abertos',
                'Validades',
                ...locations.where(
                  (l) => data.products.any((p) => p.location == l),
                ),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: filter == f,
                    showCheckmark: false,
                    selectedColor: ink,
                    backgroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    side: BorderSide(color: filter == f ? ink : lineColor),
                    labelStyle: TextStyle(
                      color: filter == f ? paper : muted,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => filter = f),
                  ),
                ),
            ],
          ),
        ),
        if (products.isEmpty)
          EmptyState(
            icon: CupertinoIcons.cube_box,
            title: data.products.isEmpty
                ? 'Sua casa, organizada.'
                : 'Nada por aqui.',
            message: data.products.isEmpty
                ? 'Adicione o que já tem em casa.\nPode ser pela câmera ou do seu jeito.'
                : 'Tente outro nome ou filtro.',
            action: data.products.isEmpty
                ? Builder(
                    builder: (anchor) => FilledButton(
                      onPressed: () => widget.onAdd(anchor),
                      child: const Text('Adicionar produto'),
                    ),
                  )
                : null,
          ),
        for (final location in groupedLocations) ...[
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(child: Eyebrow(location)),
              Text(
                '${products.where((p) => p.location == location).length}',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  constraints.maxWidth < 310 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.25
                  ? 1
                  : 2;
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 14,
                children: [
                  for (final p in products.where((p) => p.location == location))
                    SizedBox(
                      key: ValueKey('stock-${p.id}'),
                      width: width,
                      child: _StockCard(
                        product: p,
                        busy: widget.store.busy,
                        onProduct: (anchor) => widget.onProduct(anchor, p),
                        onLevel: (anchor) => widget.onLevel(anchor, p, 0),
                        onOpen: () => widget.onOpen(p),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        if (products.isNotEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 24, 8, 0),
            child: Text(
              'Sem balança, sem complicação. Os níveis dos abertos são estimativas suas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ),
      ],
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({
    required this.product,
    required this.busy,
    required this.onProduct,
    required this.onLevel,
    required this.onOpen,
  });
  final Product product;
  final bool busy;
  final void Function(BuildContext) onProduct, onLevel;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final p = product, open = p.opened.isNotEmpty;
    return Builder(
      builder: (anchor) => TouchSurface(
        onTap: () => onProduct(anchor),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 116,
                  child: Stack(
                    children: [
                      if (open)
                        Positioned.fill(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: p.opened.first),
                            duration: motionTime(context, 650),
                            curve: Curves.easeInOutCubic,
                            builder: (_, value, _) =>
                                CustomPaint(painter: StockFillPainter(value)),
                          ),
                        ),
                      Positioned(
                        top: 15,
                        left: 15,
                        child: ProductArt(product: p, size: 54),
                      ),
                      if (p.low)
                        const Positioned(
                          top: 19,
                          right: 15,
                          child: Icon(
                            CupertinoIcons.circle_fill,
                            color: orange,
                            size: 7,
                          ),
                        ),
                    ],
                  ),
                ),
                if (open)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          levelFraction(p.opened.first),
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 34,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${levelNames[(p.opened.first * 4).round()]} · aprox.${p.opened.length > 1 ? ' (1º aberto)' : ''}',
                          style: const TextStyle(color: green, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                // Stable reading surface: animated fluid never crosses the product's name.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        [
                          p.stockLabel,
                          p.pack,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                      if (p.nearestExpiry != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Text(
                            expiryLabel(p.nearestExpiry!, DateTime.now()),
                            style: TextStyle(
                              fontSize: 10,
                              color: p.needsExpiryAttention(DateTime.now())
                                  ? orange
                                  : muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(7, 0, 7, 7),
                  child: open
                      ? TextButton.icon(
                          onPressed: busy ? null : () => onLevel(anchor),
                          icon: const Icon(CupertinoIcons.drop, size: 15),
                          label: const Text(
                            'Ajustar nível',
                            style: TextStyle(fontSize: 11),
                          ),
                        )
                      : p.closed > 0
                      ? TextButton.icon(
                          onPressed: busy ? null : onOpen,
                          icon: const Icon(CupertinoIcons.cube_box, size: 15),
                          label: const Text(
                            'Abrir uma',
                            style: TextStyle(fontSize: 11),
                          ),
                        )
                      : const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'Sem estoque',
                            style: TextStyle(color: muted, fontSize: 11),
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

class StockFillPainter extends CustomPainter {
  StockFillPainter(this.level);
  final double level;
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * (1 - level);
    final wave = math.sin(level * math.pi) * 9;
    final path = Path()
      ..moveTo(0, y)
      ..cubicTo(
        size.width * .32,
        y - wave,
        size.width * .68,
        y + wave,
        size.width,
        y,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = mint);
    final edge = Path()
      ..moveTo(0, y)
      ..cubicTo(
        size.width * .32,
        y - wave,
        size.width * .68,
        y + wave,
        size.width,
        y,
      );
    canvas.drawPath(
      edge,
      Paint()
        ..color = green.withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant StockFillPainter old) => old.level != level;
}
