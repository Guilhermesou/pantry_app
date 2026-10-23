import 'package:flutter/cupertino.dart';
import '../design.dart';
import '../models.dart';
import '../store.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.store});
  final PantryStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => PanelScaffold(
      title: 'O que passou por aqui.',
      subtitle: 'Compras, aberturas e ajustes.',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (store.data.events.isEmpty)
            const EmptyState(
              icon: CupertinoIcons.clock,
              title: 'Tudo começa agora.',
              message: 'Seu histórico vai aparecer aqui.',
            ),
          for (final event in store.data.events)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Surface(
                padding: const EdgeInsets.all(17),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: event.kind == 'purchase'
                            ? mint
                            : const Color(0xFFF2E8DA),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        event.kind == 'purchase'
                            ? CupertinoIcons.bag
                            : CupertinoIcons.arrow_2_circlepath,
                        size: 18,
                        color: green,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            event.detail,
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            '${displayDate(event.date)} · ${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 10, color: muted),
                          ),
                          if (event.kind == 'purchase')
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                money(event.total),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
