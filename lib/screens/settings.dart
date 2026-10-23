import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../design.dart';
import '../main.dart';
import '../models.dart';
import '../store.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store});
  final PantryStore store;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool busy = false;
  String? status;
  Future<void> export(BuildContext anchor) async {
    final rect = originRect(anchor);
    setState(() {
      busy = true;
      status = null;
    });
    try {
      final snapshot = widget.store.data.copy();
      final payload = snapshot.toJson();
      final photos = <String, String>{};
      for (final p in snapshot.products) {
        if (p.photo.isNotEmpty && await File(p.photo).exists()) {
          photos[p.id] = base64Encode(await File(p.photo).readAsBytes());
        }
      }
      payload['embeddedPhotos'] = photos;
      final file = File(
        '${(await getTemporaryDirectory()).path}/despensa-backup-${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(jsonEncode(payload));
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: rect,
          subject: 'Backup da minha Despensa',
        ),
      );
      if (mounted) {
        setState(
          () => status =
              'O backup foi preparado. Para guardá-lo, escolha “Salvar em Arquivos” na folha de compartilhamento.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => status = 'Não foi possível preparar o backup. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> restore() async {
    setState(() {
      busy = true;
      status = null;
    });
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (picked == null) return;
      if ((await picked.length() ?? 0) > 50 * 1024 * 1024) {
        throw const FormatException('Backup maior que 50 MB.');
      }
      final bytes = await picked.readAsBytes();
      if (bytes.length > 50 * 1024 * 1024) {
        throw const FormatException('Arquivo inválido ou maior que 50 MB.');
      }
      final payload = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final replacement = AppData.fromJson(payload);
      final photos = payload['embeddedPhotos'] as Map<String, dynamic>? ?? {};
      // Validate all image bytes before writing or replacing any app data.
      final decoded = <String, List<int>>{};
      for (final p in replacement.products) {
        if (photos[p.id] != null) {
          decoded[p.id] = base64Decode(photos[p.id] as String);
        }
      }
      if (!mounted) return;
      if (!await confirm(
        context,
        'Restaurar este backup?',
        'Ele contém ${replacement.products.length} produtos e ${replacement.list.length} itens na lista. Seu estado atual será substituído. Exporte o atual antes se quiser preservá-lo.',
        label: 'Restaurar',
      )) {
        return;
      }
      final directory = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/photos',
      );
      await directory.create(recursive: true);
      for (final p in replacement.products) {
        final image = decoded[p.id];
        p.photo = '';
        if (image != null) {
          final file = File(
            '${directory.path}/restore-${newId()}-${replacement.products.indexOf(p)}.jpg',
          );
          await file.writeAsBytes(image, flush: true);
          p.photo = file.path;
        }
      }
      await widget.store.replace(replacement);
      if (mounted) {
        setState(
          () => status = 'Backup restaurado. Sua despensa está de volta.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => status =
              'Não foi possível restaurar este arquivo. Confira se é um backup válido da Despensa. Seu estado anterior foi preservado.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PanelScaffold(
    title: 'Sua despensa,\nsuas escolhas.',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Surface(
          color: mint,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CupertinoIcons.lock_shield, color: green, size: 28),
              SizedBox(height: 14),
              Text(
                'Só neste aparelho.',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Sem login ou sincronização. O estoque, a lista, as fotos e o histórico ficam salvos localmente. Exporte um backup antes de apagar o app ou trocar de iPhone.',
                style: TextStyle(color: green, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Eyebrow('UMA CÓPIA PARA GUARDAR'),
        const SizedBox(height: 12),
        Builder(
          builder: (anchor) => FilledButton.icon(
            onPressed: busy ? null : () => export(anchor),
            icon: const Icon(CupertinoIcons.square_arrow_up, size: 19),
            label: const Text('Exportar backup com fotos'),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: busy ? null : restore,
          icon: const Icon(CupertinoIcons.square_arrow_down, size: 19),
          label: const Text('Restaurar backup'),
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (status != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              status!,
              style: const TextStyle(fontSize: 12, color: green),
            ),
          ),
        const SizedBox(height: 28),
        const Eyebrow('O APP APRENDE COM VOCÊ'),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: widget.store,
          builder: (context, _) => Builder(
            builder: (anchor) => OutlinedButton.icon(
              onPressed: busy || widget.store.busy
                  ? null
                  : () => fluidPage(
                      context,
                      ReceiptAliasesPage(store: widget.store),
                      origin: originRect(anchor),
                    ),
              icon: const Icon(CupertinoIcons.link, size: 19),
              label: Text(
                'Descrições lembradas (${widget.store.data.receiptAliases.length})',
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Vínculos que você confirmou nos cupons. Esquecer uma descrição não altera o estoque.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 28),
        const Eyebrow('MOVIMENTO COM CONFORTO'),
        const SizedBox(height: 12),
        const Text(
          'As transições acompanham a opção “Reduzir Movimento” dos Ajustes de Acessibilidade do iPhone.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 26),
        const Eyebrow('SOBRE ESTA VERSÃO'),
        const SizedBox(height: 12),
        const Text(
          'Despensa · 0.4.0\n\nConsulta de alimentos: Open Food Facts (ODbL). As fotos do catálogo têm licença CC BY-SA. Cadastros externos são sugestões e precisam de conferência.\n\nA leitura de cupons usa Apple Vision no aparelho e exige revisão. A proteção contra repetição reconhece a mesma chave fiscal, quando legível, ou o mesmo texto normalizado. Leituras diferentes da mesma compra ainda podem exigir sua atenção.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
        const SizedBox(height: 30),
        if (widget.store.data.demo)
          OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    if (await confirm(
                          context,
                          'Começar com seus dados?',
                          'Todos os dados deste modo de exemplo, incluindo alterações que você fez nele, serão removidos.',
                          label: 'Começar do zero',
                        ) &&
                        context.mounted) {
                      final ok = await perform(
                        context,
                        () => widget.store.replace(AppData(onboarded: true)),
                      );
                      if (ok && context.mounted) Navigator.pop(context);
                    }
                  },
            child: const Text('Apagar exemplos e começar do zero'),
          ),
      ],
    ),
  );
}

class ReceiptAliasesPage extends StatefulWidget {
  const ReceiptAliasesPage({super.key, required this.store});
  final PantryStore store;
  @override
  State<ReceiptAliasesPage> createState() => _ReceiptAliasesPageState();
}

class _ReceiptAliasesPageState extends State<ReceiptAliasesPage> {
  String query = '';
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final data = widget.store.data;
      final entries =
          data.receiptAliases.entries
              .where(
                (entry) => normalized(
                  '${entry.key} ${data.product(entry.value)?.name ?? ''}',
                ).contains(normalized(query)),
              )
              .toList()
            ..sort((a, b) => a.key.compareTo(b.key));
      return PanelScaffold(
        title: 'O que já aprendemos.',
        subtitle: 'Descrições que você vinculou ao seu estoque.',
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Uma mesma abreviação pode ser usada para produtos diferentes. Confira o vínculo em cada compra e corrija quando precisar.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                hintText: 'Buscar descrição ou produto',
                prefixIcon: Icon(CupertinoIcons.search, size: 19),
              ),
            ),
            const SizedBox(height: 18),
            if (entries.isEmpty)
              EmptyState(
                icon: CupertinoIcons.link,
                title: query.isEmpty
                    ? 'Uma vez já ajuda.'
                    : 'Nenhum vínculo encontrado.',
                message: query.isEmpty
                    ? 'Ao revisar um cupom, escolha o produto\ne mantenha “Lembrar esta descrição”.'
                    : 'Tente outro nome ou descrição.',
              ),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Surface(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data.product(entry.value)!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Esquecer ${entry.key}',
                        onPressed: widget.store.busy
                            ? null
                            : () async {
                                final ok = await perform(
                                  context,
                                  () => widget.store.forgetReceiptAlias(
                                    entry.key,
                                  ),
                                );
                                if (ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Descrição esquecida. O estoque continua igual.',
                                      ),
                                      action: SnackBarAction(
                                        label: 'Desfazer',
                                        onPressed: () => perform(
                                          context,
                                          () => widget.store.change((d) {
                                            if (d.product(entry.value) ==
                                                    null ||
                                                d.receiptAliases.containsKey(
                                                  entry.key,
                                                )) {
                                              throw StateError(
                                                'O vínculo mudou. Confira a associação na próxima compra.',
                                              );
                                            }
                                            d.receiptAliases[entry.key] =
                                                entry.value;
                                          }),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(
                          CupertinoIcons.xmark_circle,
                          color: muted,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
