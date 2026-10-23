import 'package:flutter/material.dart';
import '../design.dart';
import '../models.dart';
import '../store.dart';
import '../symbols.dart';

String eventTime(DateTime date) =>
    '${displayDate(date)} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.store});
  final PantryStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final events = store.data.events;
      return PanelScaffold(
        title: 'O que passou por aqui.',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
          children: [
            if (events.isEmpty)
              const EmptyState(
                title: 'Tudo começa agora.',
                message: 'Seu histórico vai aparecer aqui.',
              )
            else
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: shadowMedium,
                ),
                child: Column(
                  children: [
                    for (final (i, event) in events.indexed)
                      _EventRow(event: event, last: i == events.length - 1),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.last});
  final StockEvent event;
  final bool last;
  @override
  Widget build(BuildContext context) {
    final purchase = event.kind == 'purchase';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: last ? Colors.transparent : zinc100),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(
            purchase ? Symbols.shoppingBag : Symbols.sync,
            background: purchase ? successSoft : zinc100,
            foreground: purchase ? successStrong : muted,
            iconSize: 19,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (purchase) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: successSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          money(event.total),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: successInk,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  event.detail,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: zinc600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  eventTime(event.date),
                  style: const TextStyle(fontSize: 11, color: faint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
