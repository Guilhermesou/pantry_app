import 'package:flutter/material.dart';
import '../design.dart';
import '../main.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';
import '../symbols.dart';
import 'editors.dart' show Counter;

class ExpiryField extends StatelessWidget {
  const ExpiryField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Surface(
    color: zinc100,
    padding: const EdgeInsets.fromLTRB(14, 2, 4, 2),
    child: Row(
      children: [
        const Icon(Symbols.event, color: muted, size: 19),
        const SizedBox(width: 6),
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              foregroundColor: value == null ? muted : fg,
            ),
            onPressed: !enabled
                ? null
                : () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: value ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2200, 12, 31),
                      helpText: 'Validade da embalagem',
                      cancelText: 'Cancelar',
                      confirmText: 'Anotar',
                    );
                    if (selected != null && context.mounted) {
                      onChanged(calendarDate(selected));
                    }
                  },
            child: Text(
              value == null
                  ? 'Anotar validade (opcional)'
                  : 'Validade: ${displayDate(value!)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        if (value != null)
          IconButton(
            tooltip: 'Remover validade',
            onPressed: enabled ? () => onChanged(null) : null,
            icon: const Icon(Symbols.cancel, size: 20, color: faint),
          ),
      ],
    ),
  );
}

Future<void> choosePackage(
  BuildContext context,
  PantryStore store,
  String id,
) async {
  final p = store.data.product(id)!;
  final lots = p.activeLots.where((lot) => lot.closed > 0).toList();
  if (lots.length + (p.undatedClosed > 0 ? 1 : 0) <= 1) {
    await perform(context, () => store.openPackage(id));
    return;
  }
  final choice = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .75,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Headline('Qual você abriu?', size: 20),
              const SizedBox(height: 6),
              const Text(
                'Confira a validade na embalagem para manter o lote certo.',
                style: TextStyle(color: muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              for (final lot in lots)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const IconTile(Symbols.event),
                  title: Text(displayDate(lot.expiry)),
                  subtitle: Text(
                    '${lot.closed} ${lot.closed == 1 ? 'fechada' : 'fechadas'} · ${expiryLabel(lot.expiry, DateTime.now())}',
                  ),
                  onTap: () => Navigator.pop(context, lot.id),
                ),
              if (p.undatedClosed > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const IconTile(
                    Symbols.package2,
                    background: zinc100,
                    foreground: muted,
                  ),
                  title: const Text('Sem validade anotada'),
                  subtitle: Text(
                    '${p.undatedClosed} ${p.undatedClosed == 1 ? 'fechada' : 'fechadas'}',
                  ),
                  onTap: () => Navigator.pop(context, ''),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  if (choice != null && context.mounted) {
    await perform(
      context,
      () => store.openPackage(id, lotId: choice.isEmpty ? null : choice),
    );
  }
}

class LotsPage extends StatelessWidget {
  const LotsPage({super.key, required this.store, required this.id});
  final PantryStore store;
  final String id;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final p = store.data.product(id);
      if (p == null) {
        return const PanelScaffold(
          title: 'Produto removido.',
          child: SizedBox(),
        );
      }
      return PanelScaffold(
        title: 'Cada lote, seu tempo.',
        subtitle: p.name,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
          children: [
            const Text(
              'Validades são opcionais. Anotar uma data aqui organiza o saldo existente; não adiciona outra compra.',
              style: TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            if (p.undatedClosed > 0)
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.undatedClosed} ${p.undatedClosed == 1 ? 'fechada' : 'fechadas'} sem data',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Você pode anotar a validade de todas ou só de algumas.',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: 'Anotar validade',
                      icon: Symbols.add,
                      tone: ButtonTone.soft,
                      height: 40,
                      onPressed: store.busy
                          ? null
                          : () => showSheet(
                              context,
                              LotEditor(store: store, id: id),
                            ),
                    ),
                  ],
                ),
              ),
            if (p.activeLots.isEmpty && p.undatedClosed == 0)
              const EmptyState(
                title: 'Sem lotes com data.',
                message:
                    'Nas embalagens abertas, anote a validade\npelo controle de nível do produto.',
              ),
            for (final lot in p.activeLots)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Builder(
                  builder: (_) => TouchSurface(
                    onTap: () => showSheet(
                      context,
                      LotEditor(store: store, id: id, lotId: lot.id),
                    ),
                    child: Surface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Symbols.event,
                                color: primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  displayDate(lot.expiry),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(
                                Symbols.chevronRight,
                                size: 20,
                                color: faint,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Tag(
                            expiryLabel(lot.expiry, DateTime.now()),
                            icon: Symbols.event,
                            background:
                                daysUntil(lot.expiry, DateTime.now()) < 0
                                ? dangerSoft
                                : daysUntil(lot.expiry, DateTime.now()) <= 7
                                ? warningSoft
                                : successSoft,
                            foreground:
                                daysUntil(lot.expiry, DateTime.now()) < 0
                                ? dangerInk
                                : daysUntil(lot.expiry, DateTime.now()) <= 7
                                ? warningInk
                                : successInk,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${lot.closed} ${lot.closed == 1 ? 'fechada' : 'fechadas'} · ${p.openedLotIds.where((ref) => ref == lot.id).length} ${p.openedLotIds.where((ref) => ref == lot.id).length == 1 ? 'aberta' : 'abertas'}',
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 22),
            const Text(
              'Os avisos aparecem no app. Embalagens vencidas continuam no saldo até você registrar o consumo, o descarte ou uma correção.',
              style: TextStyle(color: faint, fontSize: 12),
            ),
          ],
        ),
      );
    },
  );
}

class LotEditor extends StatefulWidget {
  const LotEditor({
    super.key,
    required this.store,
    required this.id,
    this.lotId,
  });
  final PantryStore store;
  final String id;
  final String? lotId;
  @override
  State<LotEditor> createState() => _LotEditorState();
}

class _LotEditorState extends State<LotEditor> {
  Product get product => widget.store.data.product(widget.id)!;
  late final StockLot? lot = product.lot(widget.lotId);
  late int quantity = lot?.closed ?? product.undatedClosed;
  late DateTime? expiry = lot?.expiry;
  bool saving = false;
  @override
  Widget build(BuildContext context) => SheetScaffold(
    title: 'Anote no seu ritmo.',
    subtitle: product.name,
    footer: FilledButton(
      onPressed: saving || (expiry == null && lot == null)
          ? null
          : () async {
              if (expiry == null &&
                  !await confirm(
                    context,
                    'Remover esta validade?',
                    'O saldo permanece no estoque, sem data anotada.',
                    label: 'Remover data',
                  )) {
                return;
              }
              if (!context.mounted) return;
              setState(() => saving = true);
              final ok = await perform(
                context,
                () => widget.store.assignExpiry(
                  widget.id,
                  quantity,
                  expiry,
                  lotId: widget.lotId,
                ),
              );
              if (context.mounted) {
                if (ok) {
                  Navigator.pop(context);
                } else {
                  setState(() => saving = false);
                }
              }
            },
      child: Text(
        expiry == null && lot != null ? 'Remover validade' : 'Salvar validade',
      ),
    ),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Counter(
          label: 'Fechadas neste lote',
          value: quantity,
          min: lot != null && product.openedLotIds.contains(lot!.id) ? 0 : 1,
          max: product.undatedClosed + (lot?.closed ?? 0),
          onChanged: saving
              ? null
              : (value) => setState(() => quantity = value),
        ),
        const SizedBox(height: 16),
        ExpiryField(
          value: expiry,
          enabled: !saving,
          onChanged: (value) => setState(() => expiry = value),
        ),
        const SizedBox(height: 18),
        const Text(
          'A quantidade vem do seu estoque atual. As outras embalagens permanecem com suas próprias datas ou sem validade anotada.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        if (lot != null) ...[
          const SizedBox(height: 24),
          TextButton(
            onPressed: saving
                ? null
                : () async {
                    if (!await confirm(
                      context,
                      'Remover esta validade?',
                      'A quantidade continua no estoque, sem uma data anotada. Isso também vale para as embalagens abertas deste lote.',
                      label: 'Remover data',
                    )) {
                      return;
                    }
                    if (!context.mounted) return;
                    setState(() => saving = true);
                    final ok = await perform(
                      context,
                      () => widget.store.assignExpiry(
                        widget.id,
                        0,
                        null,
                        lotId: widget.lotId,
                      ),
                    );
                    if (context.mounted) {
                      if (ok) {
                        Navigator.pop(context);
                      } else {
                        setState(() => saving = false);
                      }
                    }
                  },
            style: TextButton.styleFrom(foregroundColor: zinc700),
            child: const Text('Remover data sem alterar saldo'),
          ),
          TextButton(
            onPressed: saving
                ? null
                : () async {
                    if (!await confirm(
                      context,
                      'Registrar descarte deste lote?',
                      'Serão retiradas ${lot!.closed} fechadas e ${product.openedLotIds.where((ref) => ref == lot!.id).length} abertas com validade ${displayDate(lot!.expiry)}. Os outros lotes ficam no estoque.',
                      label: 'Registrar descarte',
                    )) {
                      return;
                    }
                    if (!context.mounted) return;
                    setState(() => saving = true);
                    final ok = await perform(
                      context,
                      () => widget.store.discardLot(widget.id, widget.lotId!),
                    );
                    if (context.mounted) {
                      if (ok) {
                        Navigator.pop(context);
                      } else {
                        setState(() => saving = false);
                      }
                    }
                  },
            style: TextButton.styleFrom(foregroundColor: dangerInk),
            child: const Text('Descartar este lote'),
          ),
        ],
      ],
    ),
  );
}
