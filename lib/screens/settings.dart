import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../design.dart';
import '../main.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';
import '../symbols.dart';
import '../toast.dart';
import 'editors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store});
  final PantryStore store;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool busy = false;
  Future<void> export(BuildContext anchor) async {
    final box = anchor.findRenderObject();
    final rect = box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    setState(() => busy = true);
    try {
      final snapshot = widget.store.data.copy();
      final payload = snapshot.toJson()..remove('cosmosToken');
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
        showToast(
          context,
          'O backup foi preparado. Para guardá-lo, escolha “Salvar em Arquivos” na folha de compartilhamento.',
        );
      }
    } catch (_) {
      if (mounted) {
        showToast(
          context,
          'Não foi possível preparar o backup. Tente novamente.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> restore() async {
    setState(() => busy = true);
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
        showToast(context, 'Backup restaurado. Sua despensa está de volta.');
      }
    } catch (_) {
      if (mounted) {
        showToast(
          context,
          'Não foi possível restaurar este arquivo. Confira se é um backup válido da Despensa. Seu estado anterior foi preservado.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final data = widget.store.data;
      const spinner = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
      return PanelScaffold(
        title: 'Sua despensa, suas escolhas.',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: SectionLabel('Compra'),
            ),
            GroupedList(
              shadow: shadowSmall,
              children: [
                ListRow(
                  title: 'Orçamento',
                  value: data.budget == 0
                      ? 'Sem orçamento'
                      : money(data.budget),
                  chevron: true,
                  onTap: () =>
                      showSheet(context, BudgetEditor(store: widget.store)),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 24, 4, 8),
              child: SectionLabel('Código de barras'),
            ),
            GroupedList(
              shadow: shadowSmall,
              children: [
                ListRow(
                  title: 'Catálogo Cosmos',
                  value: data.cosmosToken.isEmpty ? 'Opcional' : 'Ativo',
                  chevron: true,
                  onTap: () => showSheet(
                    context,
                    CosmosTokenEditor(store: widget.store),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Text(
                'A busca consulta Open Food Facts (alimentos, higiene, pet e outros) e UPCitemdb. Com um token do Cosmos, inclui também a base brasileira da Bluesoft.',
                style: TextStyle(fontSize: 12, color: faint),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 24, 4, 8),
              child: SectionLabel('Seus dados'),
            ),
            GroupedList(
              shadow: shadowSmall,
              children: [
                Builder(
                  builder: (anchor) => ListRow(
                    title: 'Exportar backup',
                    value: busy ? null : 'JSON com fotos',
                    trailing: busy ? spinner : null,
                    onTap: busy ? null : () => export(anchor),
                  ),
                ),
                ListRow(
                  title: 'Restaurar backup',
                  value: busy ? null : 'até 50 MB',
                  trailing: busy ? spinner : null,
                  onTap: busy ? null : restore,
                ),
                ListRow(
                  title: 'Descrições lembradas',
                  value: '${data.receiptAliases.length}',
                  chevron: true,
                  onTap: busy || widget.store.busy
                      ? null
                      : () => pushPage(
                          context,
                          ReceiptAliasesPage(store: widget.store),
                        ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Text(
                'Só sua. Sem conta. Salva neste aparelho. Exporte um backup antes de apagar o app ou trocar de iPhone.',
                style: TextStyle(fontSize: 12, color: faint),
              ),
            ),
            if (data.demo) ...[
              const SizedBox(height: 24),
              AppButton(
                label: 'Apagar exemplos',
                tone: ButtonTone.danger,
                height: 48,
                expand: true,
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
                            () =>
                                widget.store.replace(AppData(onboarded: true)),
                          );
                          if (ok && context.mounted) Navigator.pop(context);
                        }
                      },
              ),
            ],
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 28, 4, 8),
              child: SectionLabel('Sobre esta versão'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Despensa · 0.4.0\n\nAs transições acompanham a opção “Reduzir Movimento” dos Ajustes de Acessibilidade do iPhone.\n\nConsulta de produtos: Open Food Facts, Open Beauty Facts, Open Pet Food Facts e Open Products Facts (ODbL, fotos CC BY-SA), UPCitemdb e, com seu token, Cosmos Bluesoft. Cadastros externos são sugestões e precisam de conferência.\n\nA leitura de cupons usa Apple Vision no aparelho e exige revisão. A proteção contra repetição reconhece a mesma chave fiscal, quando legível, ou o mesmo texto normalizado. Leituras diferentes da mesma compra ainda podem exigir sua atenção.\n\nTipografia Inter (SIL OFL) e ícones Material Symbols (Apache 2.0).',
                style: TextStyle(fontSize: 12, color: faint, height: 1.5),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class CosmosTokenEditor extends StatefulWidget {
  const CosmosTokenEditor({super.key, required this.store});
  final PantryStore store;
  @override
  State<CosmosTokenEditor> createState() => _CosmosTokenEditorState();
}

class _CosmosTokenEditorState extends State<CosmosTokenEditor> {
  late final value = TextEditingController(text: widget.store.data.cosmosToken);
  bool saving = false;
  @override
  void dispose() {
    value.dispose();
    super.dispose();
  }

  Future<void> save(String token) async {
    setState(() => saving = true);
    final ok = await perform(
      context,
      () => widget.store.change((d) => d.cosmosToken = token),
    );
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
      } else {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
    title: 'Mais códigos brasileiros.',
    subtitle: 'Cosmos Bluesoft, com o seu token pessoal.',
    footer: FilledButton(
      onPressed: saving ? null : () => save(value.text.trim()),
      child: const Text('Salvar token'),
    ),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        TextField(
          controller: value,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(labelText: 'Token do Cosmos'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Crie uma conta gratuita em cosmos.bluesoft.com.br e copie o token da área de desenvolvedor. O plano gratuito tem limite diário de consultas. O token fica só neste aparelho e não vai para o backup.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        if (widget.store.data.cosmosToken.isNotEmpty) ...[
          const SizedBox(height: 20),
          TextButton(
            onPressed: saving ? null : () => save(''),
            style: TextButton.styleFrom(foregroundColor: dangerInk),
            child: const Text('Remover token'),
          ),
        ],
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
          children: [
            const Text(
              'Uma mesma abreviação pode ser usada para produtos diferentes. Confira o vínculo em cada compra e corrija quando precisar.',
              style: TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                hintText: 'Buscar descrição ou produto',
                prefixIcon: Icon(Symbols.search, size: 20),
              ),
            ),
            const SizedBox(height: 18),
            if (entries.isEmpty)
              EmptyState(
                title: query.isEmpty
                    ? 'Uma vez já ajuda.'
                    : 'Nenhum vínculo encontrado.',
                message: query.isEmpty
                    ? 'Ao revisar um cupom, escolha o produto\ne mantenha “Lembrar esta descrição”.'
                    : 'Tente outro nome ou descrição.',
              ),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Surface(
                  shadow: shadowSmall,
                  padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 2),
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
                                  showToast(
                                    context,
                                    'Descrição esquecida. O estoque continua igual.',
                                    undo: () => perform(
                                      context,
                                      () => widget.store.change((d) {
                                        if (d.product(entry.value) == null ||
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
                                  );
                                }
                              },
                        icon: const Icon(
                          Symbols.cancel,
                          color: faint,
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
