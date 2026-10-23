import 'package:flutter/material.dart';
import '../design.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';
import '../symbols.dart';
import 'capture.dart';

/// Purchases recorded by checkout or by an imported receipt, newest first.
class ReceiptsPage extends StatefulWidget {
  const ReceiptsPage({super.key, required this.store});
  final PantryStore store;
  @override
  State<ReceiptsPage> createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends State<ReceiptsPage> {
  String? expanded;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final now = DateTime.now();
      final purchases = widget.store.data.events
          .where((e) => e.kind == 'purchase')
          .toList();
      final month = purchases
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .toList();
      return PanelScaffold(
        title: 'Notas e cupons.',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
          children: [
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Gasto em ${monthNames[now.month - 1]}',
                          style: const TextStyle(fontSize: 14, color: muted),
                        ),
                      ),
                      Tag(
                        '${month.length} ${month.length == 1 ? 'compra' : 'compras'}',
                        size: 12,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedMoney(
                    value: month.fold(0.0, (sum, e) => sum + e.total),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'Escanear cupom',
                    icon: Symbols.documentScanner,
                    expand: true,
                    glow: true,
                    onPressed: () =>
                        pushPage(context, ReceiptCapture(store: widget.store)),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 24, 4, 8),
              child: SectionLabel('Recentes'),
            ),
            if (purchases.isEmpty)
              const EmptyState(
                title: 'Nenhuma compra ainda.',
                message:
                    'Ao guardar a compra da lista ou importar\num cupom, o registro aparece aqui.',
              )
            else
              Container(
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
                      for (final (i, e) in purchases.indexed)
                        _PurchaseRow(
                          event: e,
                          last: i == purchases.length - 1,
                          open: expanded == e.id,
                          onToggle: () => setState(
                            () => expanded = expanded == e.id ? null : e.id,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Text(
                'Cada compra guardada gera um registro aqui.',
                style: TextStyle(fontSize: 12, color: faint),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow({
    required this.event,
    required this.last,
    required this.open,
    required this.onToggle,
  });
  final StockEvent event;
  final bool last, open;
  final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) {
    final imported = event.title == 'Cupom importado';
    final items = [
      for (final part in event.detail.split(' · '))
        if (RegExp(r'^(\d+)× (.+)$').firstMatch(part) case final m?)
          (m.group(1)!, m.group(2)!)
        else
          ('', part),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: last ? Colors.transparent : zinc100),
        ),
      ),
      child: Column(
        children: [
          Semantics(
            expanded: open,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    IconTile(
                      imported ? Symbols.receiptLong : Symbols.receipt,
                      background: imported ? primarySoft : zinc100,
                      foreground: imported ? primary : muted,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            imported ? 'Cupom importado' : 'Compra da lista',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${displayDate(event.date)} · ${items.length} ${items.length == 1 ? 'item' : 'itens'}',
                            style: const TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      money(event.total),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? .5 : 0,
                      duration: motionTime(context, 250),
                      child: const Icon(
                        Symbols.expandMore,
                        size: 20,
                        color: faint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: motionTime(context, 300),
            curve: emphasized,
            alignment: Alignment.topCenter,
            child: !open
                ? const SizedBox(width: double.infinity)
                : Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: zinc50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (quantity, name) in items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    quantity.isEmpty ? '' : '$quantity×',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: faint,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 10),
                        const CustomPaint(
                          size: Size(double.infinity, 1),
                          painter: _DashedLine(),
                        ),
                        const SizedBox(height: 10),
                        Tag(
                          imported ? 'Lido no aparelho' : 'Marcada na lista',
                          icon: imported
                              ? Symbols.receiptLong
                              : Symbols.checklist,
                          background: imported ? successSoft : zinc100,
                          foreground: imported ? successInk : muted,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends CustomPainter {
  const _DashedLine();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = zinc300
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, .5), Offset(x + 4, .5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLine old) => false;
}
