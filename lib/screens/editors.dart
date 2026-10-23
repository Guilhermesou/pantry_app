import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../design.dart';
import '../main.dart';
import '../models.dart';
import '../services.dart';
import '../store.dart';
import '../symbols.dart';
import '../toast.dart';
import 'lots.dart';

class BudgetEditor extends StatefulWidget {
  const BudgetEditor({super.key, required this.store});
  final PantryStore store;
  @override
  State<BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<BudgetEditor> {
  late final value = TextEditingController(
    text: widget.store.data.budget == 0
        ? ''
        : widget.store.data.budget.toStringAsFixed(2).replaceAll('.', ','),
  );
  String? error;
  bool saving = false;
  @override
  void dispose() {
    value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
    title: 'Quanto cabe agora?',
    subtitle: 'Um limite para esta compra. Você pode mudar depois.',
    footer: FilledButton(
      onPressed: saving
          ? null
          : () async {
              final amount = parseAmount(value.text);
              if (amount == null || amount <= 0) {
                setState(() => error = 'Informe um valor maior que zero.');
                return;
              }
              setState(() => saving = true);
              final ok = await perform(
                context,
                () => widget.store.change((d) => d.budget = amount),
              );
              if (context.mounted) {
                if (ok) {
                  Navigator.pop(context);
                } else {
                  setState(() => saving = false);
                }
              }
            },
      child: const Text('Salvar orçamento'),
    ),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const SectionLabel('Orçamento da compra'),
        const SizedBox(height: 10),
        TextField(
          controller: value,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Valor disponível',
            prefixText: 'R\$ ',
            hintText: '600,00',
            errorText: error,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'O total planejado considera os itens essenciais e os que cabem no orçamento. Os que podem esperar ficam de fora.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: saving
              ? null
              : () async {
                  setState(() => saving = true);
                  final ok = await perform(
                    context,
                    () => widget.store.change((d) => d.budget = 0),
                  );
                  if (context.mounted) {
                    if (ok) {
                      Navigator.pop(context);
                    } else {
                      setState(() => saving = false);
                    }
                  }
                },
          child: const Text('Continuar sem orçamento'),
        ),
      ],
    ),
  );
}

class ShoppingEditor extends StatefulWidget {
  const ShoppingEditor({
    super.key,
    required this.store,
    this.item,
    this.product,
  });
  final PantryStore store;
  final ShoppingItem? item;
  final Product? product;
  @override
  State<ShoppingEditor> createState() => _ShoppingEditorState();
}

class _ShoppingEditorState extends State<ShoppingEditor> {
  late final name = TextEditingController(
    text: widget.item?.name ?? widget.product?.name ?? '',
  );
  late final price = TextEditingController(
    text: (widget.item?.price ?? widget.product?.lastPrice ?? 0) == 0
        ? ''
        : (widget.item?.price ?? widget.product!.lastPrice)
              .toStringAsFixed(2)
              .replaceAll('.', ','),
  );
  late int quantity = widget.item?.quantity ?? 1;
  late Priority priority = widget.item?.priority ?? Priority.essential;
  late String? productId = widget.item?.productId ?? widget.product?.id;
  late DateTime? expiry = widget.item?.expiry;
  final form = GlobalKey<FormState>();
  bool saving = false;
  @override
  void dispose() {
    name.dispose();
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
    title: widget.item == null ? 'Na próxima compra.' : 'Do seu jeito.',
    subtitle: 'O que você quer levar para casa?',
    footer: FilledButton(
      onPressed: saving
          ? null
          : () async {
              if (!form.currentState!.validate()) return;
              setState(() => saving = true);
              final ok = await perform(
                context,
                () => widget.store.change((d) {
                  final existing = widget.item;
                  final item = ShoppingItem(
                    id: existing?.id ?? newId(),
                    name: name.text.trim(),
                    productId: productId,
                    quantity: quantity,
                    price: parseAmount(price.text) ?? 0,
                    priority: priority,
                    checked: existing?.checked ?? false,
                    expiry: expiry,
                  );
                  if (existing == null) {
                    d.list.add(item);
                  } else {
                    d.list[d.list.indexWhere((e) => e.id == existing.id)] =
                        item;
                  }
                }),
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
        widget.item == null ? 'Adicionar à lista' : 'Salvar alterações',
      ),
    ),
    child: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          TextFormField(
            controller: name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome do item',
              hintText: 'Ex.: leite',
            ),
            validator: (v) => v!.trim().isEmpty ? 'Dê um nome ao item.' : null,
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: productId ?? '',
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Vincular ao estoque'),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Item genérico / novo produto'),
              ),
              ...widget.store.data.products.map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (id) {
              setState(() => productId = id!.isEmpty ? null : id);
              final p = widget.store.data.product(productId);
              if (p != null) {
                name.text = p.name;
                if (price.text.isEmpty && p.lastPrice > 0) {
                  price.text = p.lastPrice
                      .toStringAsFixed(2)
                      .replaceAll('.', ',');
                }
              }
            },
          ),
          const SizedBox(height: 18),
          Counter(
            label: 'Quantidade de embalagens',
            value: quantity,
            onChanged: (n) => setState(() => quantity = n),
            min: 1,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Preço por embalagem (opcional)',
              prefixText: 'R\$ ',
              hintText: '0,00',
            ),
            validator: (v) => v!.isNotEmpty && parseAmount(v) == null
                ? 'Informe um preço válido.'
                : null,
          ),
          const SizedBox(height: 18),
          ExpiryField(
            value: expiry,
            onChanged: (value) => setState(() => expiry = value),
          ),
          const SizedBox(height: 24),
          const SectionLabel('Prioridade nesta compra'),
          const SizedBox(height: 8),
          SegmentedPicker<Priority>(
            options: [for (final p in Priority.values) (p, p.label, null)],
            selected: priority,
            onSelected: (v) => setState(() => priority = v),
          ),
          const SizedBox(height: 8),
          const Text(
            'O que pode esperar fica fora do total planejado.',
            style: TextStyle(fontSize: 12, color: muted),
          ),
          if (widget.item != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (await confirm(
                            context,
                            'Tirar da lista?',
                            'O estoque não será alterado.',
                            label: 'Remover',
                          ) &&
                          context.mounted) {
                        setState(() => saving = true);
                        final ok = await perform(
                          context,
                          () => widget.store.change(
                            (d) => d.list.removeWhere(
                              (e) => e.id == widget.item!.id,
                            ),
                          ),
                        );
                        if (context.mounted) {
                          if (ok) {
                            Navigator.pop(context);
                          } else {
                            setState(() => saving = false);
                          }
                        }
                      }
                    },
              style: TextButton.styleFrom(foregroundColor: dangerInk),
              child: const Text('Remover da lista'),
            ),
          ],
        ],
      ),
    ),
  );
}

class Counter extends StatelessWidget {
  const Counter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
  });
  final String label;
  final int value, min, max;
  final ValueChanged<int>? onChanged;
  @override
  Widget build(BuildContext context) => Surface(
    color: zinc100,
    padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        IconButton(
          tooltip: 'Diminuir $label',
          onPressed: value > min && onChanged != null
              ? () => onChanged!(value - 1)
              : null,
          icon: const Icon(Symbols.remove, size: 20),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          ),
        ),
        IconButton(
          tooltip: 'Aumentar $label',
          onPressed: value < max && onChanged != null
              ? () => onChanged!(value + 1)
              : null,
          icon: const Icon(Symbols.add, size: 20),
        ),
      ],
    ),
  );
}

class ProductEditor extends StatefulWidget {
  const ProductEditor({
    super.key,
    required this.store,
    this.product,
    this.fromCatalog = false,
  });
  final PantryStore store;
  final Product? product;
  final bool fromCatalog;
  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  late final p = Product.fromJson(
    (widget.product ?? Product(id: newId(), name: '')).toJson(),
  );
  late final name = TextEditingController(text: p.name);
  late final brand = TextEditingController(text: p.brand);
  late final pack = TextEditingController(text: p.pack);
  late final code = TextEditingController(text: p.barcode);
  late final minimum = TextEditingController(
    text: p.minimum.toStringAsFixed(0),
  );
  late final price = TextEditingController(
    text: p.lastPrice == 0
        ? ''
        : p.lastPrice.toStringAsFixed(2).replaceAll('.', ','),
  );
  final form = GlobalKey<FormState>();
  bool saving = false, photoBusy = false;

  /// Dates for part of the first count; packages left over stay undated.
  final initialLots = <StockLot>[];
  var lotSerial = 0;
  int get datedClosed => initialLots.fold(0, (sum, lot) => sum + lot.closed);
  bool get existing => widget.store.data.product(p.id) != null;
  Future<void> addInitialLot() async {
    final expiry = await pickExpiry(context, null);
    if (expiry == null || !mounted) return;
    setState(() {
      final remaining = p.closed - datedClosed;
      if (remaining == 0) p.closed++;
      initialLots.add(
        StockLot(
          id: 'initial-${p.id}-${lotSerial++}',
          closed: remaining == 0 ? 1 : remaining,
          expiry: expiry,
        ),
      );
    });
  }

  @override
  void dispose() {
    for (final c in [name, brand, pack, code, minimum, price]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> photo(ImageSource source) async {
    setState(() => photoBusy = true);
    try {
      final path = await pickProductPhoto(source);
      if (mounted && path != null) setState(() => p.photo = path);
    } catch (_) {
      if (mounted) {
        showToast(
          context,
          'Não foi possível abrir a foto. Verifique a permissão nos Ajustes do iPhone.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => photoBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SheetScaffold(
    title: existing ? 'Sobre o produto.' : 'Um lugar na sua casa.',
    subtitle: 'Cadastre uma vez. Reconheça nas próximas compras.',
    footer: FilledButton(
      onPressed: saving || photoBusy
          ? null
          : () async {
              if (!form.currentState!.validate()) return;
              setState(() => saving = true);
              p.name = name.text.trim();
              p.brand = brand.text.trim();
              p.pack = pack.text.trim();
              p.barcode = code.text.trim();
              p.minimum = double.parse(minimum.text);
              p.lastPrice = parseAmount(price.text) ?? 0;
              final ok = await perform(
                context,
                () => widget.store.change((d) {
                  final index = d.products.indexWhere((e) => e.id == p.id);
                  if (index < 0) {
                    p.lots = List.of(initialLots);
                    d.products.add(p);
                  } else {
                    d.products[index] = p;
                  }
                  d.events.insert(
                    0,
                    StockEvent(
                      id: newId(),
                      title: index < 0
                          ? 'Produto cadastrado'
                          : 'Cadastro ajustado',
                      detail: p.name,
                      date: DateTime.now(),
                    ),
                  );
                }),
              );
              if (context.mounted) {
                if (ok) {
                  Navigator.pop(context);
                } else {
                  setState(() => saving = false);
                }
              }
            },
      child: Text(saving ? 'Salvando…' : 'Salvar produto'),
    ),
    child: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(
            children: [
              ProductArt(product: p, size: 88),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: photoBusy
                          ? null
                          : () => photo(ImageSource.camera),
                      icon: const Icon(Symbols.photoCamera, size: 18),
                      label: const Text('Tirar foto'),
                    ),
                    TextButton.icon(
                      onPressed: photoBusy
                          ? null
                          : () => photo(ImageSource.gallery),
                      icon: const Icon(Symbols.photoLibrary, size: 18),
                      label: const Text('Escolher da galeria'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nome do produto'),
            validator: (v) => v!.trim().isEmpty ? 'Informe o nome.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: brand,
            decoration: const InputDecoration(labelText: 'Marca (opcional)'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: pack,
            decoration: const InputDecoration(
              labelText: 'Tamanho da embalagem',
              hintText: 'Ex.: 1 kg, 500 ml, 12 unidades',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: code,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Código de barras (opcional)',
            ),
            validator: (v) {
              if (v!.isEmpty) return null;
              if (!RegExp(r'^\d{8,14}$').hasMatch(v)) {
                return 'Use de 8 a 14 números.';
              }
              if (widget.store.data.products.any(
                (e) => e.id != p.id && e.barcode == v,
              )) {
                return 'Este código já está cadastrado.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField(
            initialValue: p.category,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: categories
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => p.category = v!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField(
            initialValue: p.location,
            decoration: const InputDecoration(labelText: 'Onde fica?'),
            items: locations
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => p.location = v!,
          ),
          const SizedBox(height: 24),
          Counter(
            label: 'Embalagens fechadas',
            value: p.closed,
            min: existing ? p.closed - p.undatedClosed : datedClosed,
            onChanged: (n) => setState(() => p.closed = n),
          ),
          const SizedBox(height: 10),
          if (!existing) ...[
            for (final lot in initialLots) ...[
              ExpiryField(
                value: lot.expiry,
                onChanged: (value) => setState(() {
                  if (value == null) {
                    initialLots.remove(lot);
                  } else {
                    lot.expiry = value;
                  }
                }),
              ),
              const SizedBox(height: 4),
              Counter(
                label: 'Com esta validade',
                value: lot.closed,
                min: 1,
                max: p.closed - datedClosed + lot.closed,
                onChanged: (n) => setState(() => lot.closed = n),
              ),
              const SizedBox(height: 14),
            ],
            AppButton(
              label: initialLots.isEmpty
                  ? 'Anotar validade (opcional)'
                  : 'Outra validade',
              icon: Symbols.event,
              tone: ButtonTone.soft,
              height: 40,
              onPressed: addInitialLot,
            ),
            const SizedBox(height: 8),
            Text(
              initialLots.isEmpty
                  ? 'Embalagens com datas diferentes? Anote uma validade para cada grupo.'
                  : p.closed > datedClosed
                  ? '${p.closed - datedClosed} sem validade anotada.'
                  : 'Todas as fechadas têm validade.',
              style: const TextStyle(fontSize: 12, color: muted),
            ),
            const SizedBox(height: 10),
          ],
          if (p.lots.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'As unidades com validade são ajustadas em “Lotes e validades” no detalhe do produto.',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ),
          const Text(
            'Tem uma embalagem já aberta? Depois de salvar, registre-a no produto para indicar o nível e a validade.',
            style: TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: minimum,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Mínimo desejado (embalagens)',
            ),
            validator: (v) => int.tryParse(v ?? '') == null || int.parse(v!) < 0
                ? 'Informe um número inteiro a partir de zero.'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Último preço por embalagem (opcional)',
              prefixText: 'R\$ ',
            ),
            validator: (v) => v!.isNotEmpty && parseAmount(v) == null
                ? 'Informe um preço válido.'
                : null,
          ),
          if (p.source.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                'Cadastro sugerido por ${p.source}. Confira os dados.${p.source.startsWith('Open') ? ' Base ODbL; imagens CC BY-SA.' : ''}',
                style: const TextStyle(fontSize: 11, color: faint),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
