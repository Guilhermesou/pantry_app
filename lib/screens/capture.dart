import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../design.dart';
import '../main.dart';
import '../models.dart';
import '../services.dart';
import '../store.dart';
import 'editors.dart';
import 'lots.dart';

class AddHub extends StatelessWidget {
  const AddHub({super.key, required this.store, required this.tab});
  final PantryStore store;
  final int tab;
  @override
  Widget build(BuildContext context) => PanelScaffold(
    title: 'O que vamos adicionar?',
    subtitle: 'Escolha o caminho mais simples para você.',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _option(
          context,
          CupertinoIcons.list_bullet,
          'Um item na lista',
          'Pode ser só “leite”. A marca você decide depois.',
          ShoppingEditor(store: store),
        ),
        _option(
          context,
          CupertinoIcons.barcode_viewfinder,
          'Ler código de barras',
          'Reconheça um produto pela embalagem.',
          BarcodePage(store: store),
        ),
        _option(
          context,
          CupertinoIcons.cube_box,
          'Um produto no estoque',
          'Nome, foto e o que já tem em casa.',
          ProductEditor(store: store),
        ),
        _option(
          context,
          CupertinoIcons.doc_text_viewfinder,
          'Importar um cupom',
          'Fotografe, confira e guarde a compra.',
          ReceiptCapture(store: store),
        ),
        const SizedBox(height: 20),
        const Text(
          'A lista e o estoque funcionam sem internet. A consulta a novos códigos precisa de conexão.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ],
    ),
  );
  Widget _option(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Widget destination,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Builder(
      builder: (anchor) => InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () async {
          await fluidPage(context, destination, origin: originRect(anchor));
          if (context.mounted) Navigator.pop(context);
        },
        child: Surface(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: mint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: green, size: 25),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(CupertinoIcons.chevron_right, size: 14, color: muted),
            ],
          ),
        ),
      ),
    ),
  );
}

class BarcodePage extends StatefulWidget {
  const BarcodePage({super.key, required this.store});
  final PantryStore store;
  @override
  State<BarcodePage> createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> with WidgetsBindingObserver {
  final scanner = MobileScannerController(
    autoStart: false,
    formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.itf14,
    ],
  );
  final code = TextEditingController();
  final catalog = CatalogService();
  bool busy = false, active = false;
  String? message;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      scanner.stop();
    }
    if (state == AppLifecycleState.resumed && active && !busy) {
      scanner.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scanner.dispose();
    code.dispose();
    catalog.close();
    super.dispose();
  }

  Future<void> lookup(String value) async {
    if (busy) return;
    final raw = value.trim();
    if (!RegExp(r'^\d{8,14}$').hasMatch(raw)) {
      setState(() => message = 'Use um código de 8 a 14 números.');
      return;
    }
    setState(() {
      busy = true;
      code.text = raw;
      message = null;
    });
    await scanner.stop();
    final local = widget.store.data.byBarcode(raw);
    if (local != null) {
      if (mounted) {
        await fluidPage(
          context,
          ProductDetail(store: widget.store, id: local.id),
        );
        if (mounted) Navigator.pop(context);
      }
      return;
    }
    try {
      final product = await catalog.lookup(raw);
      if (!mounted) return;
      if (product == null) {
        setState(() {
          message =
              'Não encontramos esse produto. Você pode cadastrá-lo uma vez e o app lembrará do código.';
          busy = false;
        });
      } else {
        await fluidPage(
          context,
          ProductEditor(
            store: widget.store,
            product: product,
            fromCatalog: true,
          ),
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          message =
              'Não foi possível consultar o catálogo. Confira sua conexão ou faça o cadastro manual.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PanelScaffold(
    title: 'Apontou, encontrou.',
    subtitle: 'Enquadre o código de barras da embalagem.',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AspectRatio(
          aspectRatio: 1.1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (active)
                  MobileScanner(
                    controller: scanner,
                    onDetect: (capture) {
                      for (final b in capture.barcodes) {
                        if (b.rawValue != null) {
                          lookup(b.rawValue!);
                          break;
                        }
                      }
                    },
                    errorBuilder: (context, error) => const ColoredBox(
                      color: ink,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Câmera indisponível. Autorize nos Ajustes do iPhone ou digite o código abaixo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: paper),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const ColoredBox(color: ink),
                if (!active)
                  Center(
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        setState(() => active = true);
                        await Future<void>.delayed(
                          const Duration(milliseconds: 100),
                        );
                        if (mounted) {
                          try {
                            await scanner.start();
                          } catch (_) {
                            if (mounted) {
                              setState(
                                () => message =
                                    'Câmera indisponível. Digite o código abaixo.',
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(CupertinoIcons.camera),
                      label: const Text('Ativar câmera'),
                    ),
                  ),
                if (active && !busy)
                  const IgnorePointer(
                    child: Center(
                      child: Icon(
                        CupertinoIcons.viewfinder,
                        size: 150,
                        color: Color(0xFFDBE8D6),
                      ),
                    ),
                  ),
                if (busy)
                  const ColoredBox(
                    color: Color(0x99000000),
                    child: Center(
                      child: CircularProgressIndicator(color: paper),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: code,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: lookup,
          decoration: const InputDecoration(
            labelText: 'Ou digite o código',
            prefixIcon: Icon(CupertinoIcons.barcode),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: busy ? null : () => lookup(code.text),
          child: Text(busy ? 'Procurando produto…' : 'Buscar produto'),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(message!, style: const TextStyle(color: orange)),
          ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: busy
              ? null
              : () async {
                  await scanner.stop();
                  if (!context.mounted) return;
                  await fluidPage(
                    context,
                    ProductEditor(
                      store: widget.store,
                      product: Product(
                        id: newId(),
                        name: '',
                        barcode: code.text,
                      ),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
          child: const Text('Cadastrar manualmente'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Busca de alimentos: Open Food Facts · dados ODbL. Nem todo produto está no catálogo. Confirme nome, marca e embalagem antes de salvar.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: muted),
        ),
      ],
    ),
  );
}

class ReceiptCapture extends StatefulWidget {
  const ReceiptCapture({super.key, required this.store});
  final PantryStore store;
  @override
  State<ReceiptCapture> createState() => _ReceiptCaptureState();
}

class _ReceiptCaptureState extends State<ReceiptCapture> {
  final text = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> capture(ImageSource source) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final recognized = await recognizeReceipt(source);
      if (!mounted || recognized == null) return;
      text.text = recognized;
      if (recognized.trim().isEmpty) {
        setState(
          () => error =
              'Não conseguimos ler o texto. Tente uma foto mais nítida, com o cupom inteiro e boa luz.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Não foi possível ler a imagem. Verifique a permissão de câmera/fotos ou cole o texto abaixo.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PanelScaffold(
    title: 'Uma compra,\numa foto.',
    subtitle: 'A leitura acontece no seu aparelho.',
    footer: FilledButton(
      onPressed: busy
          ? null
          : () async {
              if (text.text.trim().isEmpty) {
                setState(
                  () => error =
                      'Fotografe o cupom ou cole o texto para continuar.',
                );
                return;
              }
              final fingerprint = ReceiptParser.fingerprint(text.text);
              if (widget.store.data.receipts.contains(fingerprint)) {
                setState(
                  () => error =
                      'Este cupom já foi importado. O estoque não foi alterado.',
                );
                return;
              }
              final lines = ReceiptParser.parse(text.text);
              ReceiptMatcher.prepare(lines, widget.store.data);
              if (lines.isEmpty) {
                lines.add(ReceiptLine(name: '', selected: true));
              }
              final saved = await fluidPage<bool>(
                context,
                ReceiptReview(
                  store: widget.store,
                  lines: lines,
                  fingerprint: fingerprint,
                ),
              );
              if (saved == true && context.mounted) Navigator.pop(context);
            },
      child: const Text('Revisar itens da compra'),
    ),
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Surface(
          color: mint,
          child: Column(
            children: [
              const Icon(
                CupertinoIcons.doc_text_viewfinder,
                size: 52,
                color: green,
              ),
              const SizedBox(height: 16),
              const Text(
                'Cupom inteiro. Boa luz. Sem dobras.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const Text(
                'Depois da leitura, você confere os nomes, as quantidades de embalagens e os preços.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: green),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : () => capture(ImageSource.camera),
                  icon: const Icon(CupertinoIcons.camera, size: 18),
                  label: const Text('Fotografar cupom'),
                ),
              ),
              TextButton(
                onPressed: busy ? null : () => capture(ImageSource.gallery),
                child: const Text('Escolher foto existente'),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Eyebrow('OU COLE O TEXTO DO CUPOM'),
        const SizedBox(height: 12),
        TextField(
          controller: text,
          maxLines: 9,
          decoration: const InputDecoration(
            hintText:
                'Exemplo de formato:\nARROZ INTEGRAL 8,90\nLEITE INTEGRAL 2 x 5,49 10,98',
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(error!, style: const TextStyle(color: orange)),
          ),
        const SizedBox(height: 18),
        const Text(
          'Nesta versão: foto ou texto do cupom. PDF, XML e consulta de NFC-e por QR Code ficam para uma próxima etapa.',
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ],
    ),
  );
}

class ReceiptReview extends StatefulWidget {
  const ReceiptReview({
    super.key,
    required this.store,
    required this.lines,
    required this.fingerprint,
  });
  final PantryStore store;
  final List<ReceiptLine> lines;
  final String fingerprint;
  @override
  State<ReceiptReview> createState() => _ReceiptReviewState();
}

class _ReceiptReviewState extends State<ReceiptReview> {
  final form = GlobalKey<FormState>();
  bool saving = false, clearList = true;
  @override
  Widget build(BuildContext context) {
    final selected = widget.lines.where((e) => e.selected).toList();
    final total = selected.fold(
      0.0,
      (sum, e) => sum + e.quantity * e.unitPrice,
    );
    return PanelScaffold(
      title: 'Confira com calma.',
      subtitle: 'Só os itens selecionados entram no estoque.',
      footer: FilledButton(
        onPressed: saving || selected.isEmpty
            ? null
            : () async {
                if (!form.currentState!.validate()) return;
                if (!await confirm(
                  context,
                  'Guardar estes itens?',
                  '${selected.length} itens serão adicionados ao estoque. Você já conferiu as quantidades e os vínculos?',
                  label: 'Guardar compra',
                )) {
                  return;
                }
                if (!context.mounted) return;
                setState(() => saving = true);
                final ok = await perform(
                  context,
                  () => widget.store.importReceipt(
                    widget.lines,
                    widget.fingerprint,
                    clearList: clearList,
                  ),
                );
                if (context.mounted) {
                  if (ok) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() => saving = false);
                  }
                }
              },
        child: Text(saving ? 'Guardando…' : 'Confirmar entrada no estoque'),
      ),
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Surface(
              color: peach,
              child: const Text(
                'A leitura pode confundir linhas, pesos e descontos. Confira o preço por embalagem. Para itens vendidos por peso, cadastre a porção comprada como 1 embalagem.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            for (final l in widget.lines)
              Padding(
                key: ObjectKey(l),
                padding: const EdgeInsets.only(bottom: 16),
                child: Surface(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: l.selected,
                            onChanged: (v) => setState(() => l.selected = v!),
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: l.name,
                              onChanged: (v) => l.name = v,
                              decoration: const InputDecoration(
                                labelText: 'Nome do produto',
                              ),
                              validator: (v) => l.selected && v!.trim().isEmpty
                                  ? 'Informe o nome.'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      if (l.selected) ...[
                        const SizedBox(height: 14),
                        if (l.originalName.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No cupom: ${l.originalName}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        if (l.matchSource == ReceiptMatchSource.memory ||
                            l.matchSource == ReceiptMatchSource.exactName)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.checkmark_circle,
                                  size: 17,
                                  color: green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l.matchSource == ReceiptMatchSource.memory
                                        ? 'Você já associou esta descrição antes. Confira o vínculo.'
                                        : 'Mesmo nome no estoque. Confira a embalagem.',
                                    style: const TextStyle(
                                      color: green,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (l.suggestedProductId != null && l.productId == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Surface(
                              color: mint,
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pode ser este produto?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    widget.store.data
                                        .product(l.suggestedProductId)!
                                        .name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      l.productId = l.suggestedProductId;
                                      l.matchSource = ReceiptMatchSource.manual;
                                    }),
                                    child: const Text('Usar este produto'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            '${identityHashCode(l)}-${l.productId}',
                          ),
                          initialValue: l.productId ?? '',
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Corresponde a qual produto?',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Criar novo produto'),
                            ),
                            ...widget.store.data.products.map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  [p.name, p.brand, p.pack]
                                      .where((value) => value.isNotEmpty)
                                      .join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            l.productId = v!.isEmpty ? null : v;
                            l.matchSource = ReceiptMatchSource.manual;
                            l.suggestedProductId = null;
                          }),
                        ),
                        if (l.originalName.isNotEmpty)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: l.remember,
                            onChanged: (value) =>
                                setState(() => l.remember = value!),
                            title: const Text(
                              'Lembrar esta descrição',
                              style: TextStyle(fontSize: 12),
                            ),
                            subtitle: const Text(
                              'Só depois de confirmar esta compra.',
                              style: TextStyle(fontSize: 10, color: muted),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Counter(
                          label: 'Embalagens',
                          value: l.quantity,
                          min: 1,
                          onChanged: (n) => setState(() => l.quantity = n),
                        ),
                        const SizedBox(height: 12),
                        ExpiryField(
                          value: l.expiry,
                          onChanged: (value) =>
                              setState(() => l.expiry = value),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: l.unitPrice
                              .toStringAsFixed(2)
                              .replaceAll('.', ','),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Preço por embalagem',
                            prefixText: 'R\$ ',
                          ),
                          onChanged: (v) => setState(
                            () => l.unitPrice = parseAmount(v) ?? -1,
                          ),
                          validator: (v) => parseAmount(v ?? '') == null
                              ? 'Confira o preço.'
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () =>
                  setState(() => widget.lines.add(ReceiptLine(name: ''))),
              icon: const Icon(CupertinoIcons.add, size: 18),
              label: const Text('Adicionar item que faltou'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: clearList,
              onChanged: (v) => setState(() => clearList = v!),
              title: const Text(
                'Retirar os produtos correspondentes da lista',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Somente itens vinculados ao mesmo produto e cobertos pela quantidade comprada.',
                style: TextStyle(fontSize: 11, color: muted),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${selected.length} itens · ${money(total < 0 ? 0 : total)}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 21),
            ),
            const SizedBox(height: 12),
            const Text(
              'Não importe o cupom se você já guardou esta compra usando “Concluir compra”. Isso somaria as quantidades novamente.',
              style: TextStyle(color: orange, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
