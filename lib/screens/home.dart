import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design.dart';
import '../main.dart';
import '../models.dart';
import '../store.dart';
import 'editors.dart';
import 'capture.dart';
import 'settings.dart';

class PantryHome extends StatefulWidget {
  const PantryHome({super.key, required this.store});
  final PantryStore store;
  @override
  State<PantryHome> createState() => _PantryHomeState();
}

class _PantryHomeState extends State<PantryHome> with WidgetsBindingObserver {
  int tab = 0;
  String query = '', filter = 'Todos';
  PantryStore get store => widget.store;
  AppData get data => store.data;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) store.refreshTime();
  }

  void add(BuildContext anchor) => fluidPage(
    context,
    AddHub(store: store, tab: tab),
    origin: originRect(anchor),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      if (!data.onboarded) return _Welcome(store: store);
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 22, 16),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: ink,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        CupertinoIcons.leaf_arrow_circlepath,
                        color: paper,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'despensa',
                      style: TextStyle(
                        fontSize: 21,
                        letterSpacing: -1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Builder(
                      builder: (anchor) => RoundButton(
                        icon: CupertinoIcons.slider_horizontal_3,
                        label: 'Ajustes e backup',
                        onPressed: () => fluidPage(
                          context,
                          SettingsPage(store: store),
                          origin: originRect(anchor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (data.demo)
                Container(
                  color: peach,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: const Text(
                    'Modo de exemplo · apague os exemplos nos Ajustes.',
                    style: TextStyle(fontSize: 11, color: ink),
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Duration(
                    milliseconds: MediaQuery.disableAnimationsOf(context)
                        ? 0
                        : 250,
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(tab),
                    child: tab == 0
                        ? _shopping()
                        : tab == 1
                        ? _stock()
                        : _history(),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _navigation(),
      );
    },
  );

  Widget _navigation() => Container(
    decoration: const BoxDecoration(
      color: paper,
      border: Border(top: BorderSide(color: lineColor)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 8),
        child: Row(
          children: [
            for (final (index, icon, title) in [
              (0, CupertinoIcons.list_bullet, 'Lista'),
              (1, CupertinoIcons.cube_box, 'Estoque'),
              (2, CupertinoIcons.clock, 'Histórico'),
            ])
              Expanded(
                child: Semantics(
                  selected: tab == index,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        tab = index;
                        query = '';
                        filter = 'Todos';
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 22,
                            color: tab == index ? green : muted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: tab == index
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: tab == index ? green : muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Builder(
              builder: (anchor) => RoundButton(
                icon: CupertinoIcons.add,
                label: 'Adicionar',
                dark: true,
                onPressed: store.busy ? null : () => add(anchor),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _heading(String eyebrow, String title, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(eyebrow),
              const SizedBox(height: 10),
              Editorial(title),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );

  Widget _shopping() {
    final active = data.list
        .where((e) => e.priority != Priority.later)
        .toList();
    final selected = data.list.where((e) => e.checked).length;
    final unknown = active.where((e) => e.price == 0).length;
    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        _heading(
          'MENOS ESQUECIMENTO, MAIS TRANQUILIDADE',
          'Sua próxima\ncompra.',
          trailing: Text(
            '${data.list.length} itens',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Builder(
            builder: (anchor) => InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () => fluidPage(
                context,
                BudgetEditor(store: store),
                origin: originRect(anchor),
              ),
              child: Surface(
                color: ink,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Eyebrow(
                          'Seu planejamento',
                          color: Color(0xFFB4C9BA),
                        ),
                        const Spacer(),
                        Icon(
                          CupertinoIcons.pencil,
                          size: 16,
                          color: paper.withValues(alpha: .8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Editorial(money(data.planned), size: 34, color: paper),
                    const SizedBox(height: 7),
                    Text(
                      data.budget == 0
                          ? 'Toque para definir um orçamento'
                          : 'de ${money(data.budget)} disponíveis',
                      style: const TextStyle(
                        color: Color(0xFFB4C9BA),
                        fontSize: 13,
                      ),
                    ),
                    if (data.budget > 0) ...[
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (data.planned / data.budget).clamp(0, 1),
                          minHeight: 5,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(
                            data.planned > data.budget
                                ? const Color(0xFFE9AE88)
                                : const Color(0xFFBED7A9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        data.planned > data.budget
                            ? '${money(data.planned - data.budget)} acima do orçamento'
                            : '${money(data.budget - data.planned)} de margem',
                        style: const TextStyle(
                          color: Color(0xFFDBE8D6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      unknown > 0
                          ? 'Estimativa parcial · $unknown ${unknown == 1 ? 'item sem preço' : 'itens sem preço'}'
                          : 'Estimativa com os preços informados',
                      style: const TextStyle(
                        color: Color(0xFFB4C9BA),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Icon(CupertinoIcons.lightbulb, size: 17, color: green),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Compre o que faz sentido agora.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ),
            ],
          ),
        ),
        if (data.list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: EmptyState(
              icon: CupertinoIcons.bag,
              title: 'Uma lista leve.',
              message:
                  'Adicione o que você precisa.\nO que pode esperar também tem seu lugar.',
              action: Builder(
                builder: (anchor) => FilledButton.icon(
                  onPressed: () => add(anchor),
                  icon: const Icon(CupertinoIcons.add, size: 18),
                  label: const Text('Montar minha lista'),
                ),
              ),
            ),
          ),
        for (final priority in Priority.values)
          if (data.list.any((e) => e.priority == priority)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 27, 24, 10),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: priority == Priority.essential
                          ? green
                          : priority == Priority.flexible
                          ? orange
                          : muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Eyebrow(priority.label),
                  const Spacer(),
                  Text(
                    '${data.list.where((e) => e.priority == priority).length}',
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
            ),
            ...data.list.where((e) => e.priority == priority).map(_shoppingRow),
          ],
        if (selected > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Surface(
              color: mint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$selected ${selected == 1 ? 'item no carrinho' : 'itens no carrinho'} · ${money(data.cart)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Confira quantidades e preços antes de guardar.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: store.busy
                          ? null
                          : () async {
                              if (await confirm(
                                    context,
                                    'Guardar a compra?',
                                    'Os $selected itens marcados entram no estoque e saem da lista. Se usar o cupom desta compra, importe o cupom em vez de confirmar aqui.',
                                    label: 'Guardar no estoque',
                                  ) &&
                                  mounted) {
                                await perform(
                                  context,
                                  store.checkout,
                                  success:
                                      'Compra guardada. Tudo no seu lugar.',
                                );
                              }
                            },
                      icon: const Icon(CupertinoIcons.checkmark_alt, size: 18),
                      label: const Text('Concluir compra'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (data.products.any(
          (p) => p.low && !data.list.any((e) => e.productId == p.id),
        )) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 30, 24, 12),
            child: Eyebrow('Vale dar uma olhada'),
          ),
          ...data.products
              .where((p) => p.low && !data.list.any((e) => e.productId == p.id))
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: Surface(
                    padding: const EdgeInsets.all(14),
                    color: const Color(0xFFF0EADF),
                    child: Row(
                      children: [
                        ProductArt(product: p, size: 46),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                p.available == 0
                                    ? 'Acabou em casa'
                                    : 'Abaixo do mínimo · estimativa',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Adicionar ${p.name} à lista',
                          onPressed: store.busy
                              ? null
                              : () => perform(
                                  context,
                                  () => store.addSuggestion(p.id),
                                ),
                          icon: const Icon(
                            CupertinoIcons.add_circled,
                            color: green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }

  Widget _shoppingRow(ShoppingItem item) {
    final product = data.product(item.productId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: lineColor)),
        ),
        child: Row(
          children: [
            Semantics(
              label: 'No carrinho: ${item.name}',
              checked: item.checked,
              child: Checkbox(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                value: item.checked,
                onChanged: store.busy
                    ? null
                    : (value) {
                        HapticFeedback.selectionClick();
                        perform(
                          context,
                          () => store.change(
                            (d) =>
                                d.list
                                        .firstWhere((e) => e.id == item.id)
                                        .checked =
                                    value!,
                          ),
                        );
                      },
              ),
            ),
            Expanded(
              child: Builder(
                builder: (anchor) => InkWell(
                  onTap: () => fluidPage(
                    context,
                    ShoppingEditor(store: store, item: item),
                    origin: originRect(anchor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: item.checked
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.checked ? muted : ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.quantity} ${item.quantity == 1 ? 'unidade' : 'unidades'}${product == null ? '' : ' · ${product.pack.isEmpty ? product.stockLabel : product.pack}'}',
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Text(
              item.price == 0 ? 'Sem preço' : money(item.total),
              style: TextStyle(
                fontSize: 12,
                color: item.price == 0 ? muted : ink,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_right, size: 12, color: muted),
          ],
        ),
      ),
    );
  }

  Widget _stock() {
    final now = DateTime.now();
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
    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        _heading('CUIDAR DO QUE JÁ ESTÁ EM CASA', 'Seu estoque.'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Surface(
                  color: mint,
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
                      const Text(
                        'produtos em casa',
                        style: TextStyle(color: green, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Surface(
                  color: const Color(0xFFF1E5D5),
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
                      const Text(
                        'para ficar de olho',
                        style: TextStyle(color: orange, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (attention > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Surface(
              color: peach,
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.calendar, size: 20, color: orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$attention ${attention == 1 ? 'produto com validade' : 'produtos com validades'} para conferir',
                      style: const TextStyle(fontSize: 12, color: ink),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
          child: TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: const InputDecoration(
              hintText: 'O que você está procurando?',
              prefixIcon: Icon(CupertinoIcons.search, size: 19),
            ),
            textInputAction: TextInputAction.search,
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              for (final f in [
                'Todos',
                'Acabando',
                'Abertos',
                'Validades',
                ...locations,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: filter == f,
                    showCheckmark: false,
                    selectedColor: ink,
                    labelStyle: TextStyle(
                      color: filter == f ? paper : muted,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: filter == f ? ink : lineColor),
                    shape: const StadiumBorder(),
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
                ? 'Cadastre o primeiro produto para começar.\nPode ser pela câmera ou do seu jeito.'
                : 'Tente outro nome ou filtro.',
            action: data.products.isEmpty
                ? Builder(
                    builder: (anchor) => FilledButton(
                      onPressed: () => add(anchor),
                      child: const Text('Adicionar produto'),
                    ),
                  )
                : null,
          ),
        ...products.map(
          (p) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 13, 24, 0),
            child: Builder(
              builder: (anchor) => InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => fluidPage(
                  context,
                  ProductDetail(store: store, id: p.id),
                  origin: originRect(anchor),
                ),
                child: Surface(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ProductArt(product: p, size: 68),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              [
                                p.pack,
                                p.location,
                              ].where((e) => e.isNotEmpty).join(' · '),
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p.stockLabel,
                              style: const TextStyle(fontSize: 11),
                            ),
                            if (p.nearestExpiry != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  expiryLabel(p.nearestExpiry!, now),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: p.needsExpiryAttention(now)
                                        ? orange
                                        : muted,
                                  ),
                                ),
                              ),
                            if (p.opened.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 54,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: p.opened.first,
                                        minHeight: 4,
                                        color: green,
                                        backgroundColor: mint,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      '${levelNames[(p.opened.first * 4).round()]} · aprox.',
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          if (p.low)
                            const Icon(
                              CupertinoIcons.circle_fill,
                              color: orange,
                              size: 7,
                            ),
                          const SizedBox(height: 10),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            size: 13,
                            color: muted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (data.products.isNotEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(32, 22, 32, 0),
            child: Text(
              'Sem balança, sem complicação. Os níveis dos abertos são estimativas suas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _history() => ListView(
    padding: const EdgeInsets.only(bottom: 30),
    children: [
      _heading('CADA COISA NO SEU TEMPO', 'O que passou\npor aqui.'),
      if (data.events.isEmpty)
        const EmptyState(
          icon: CupertinoIcons.clock,
          title: 'Tudo começa agora.',
          message: 'Compras, embalagens abertas e ajustes\nvão aparecer aqui.',
        ),
      for (final event in data.events)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
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
                        '${event.date.day.toString().padLeft(2, '0')}/${event.date.month.toString().padLeft(2, '0')}/${event.date.year} · ${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')}',
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
  );
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.store});
  final PantryStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.leaf_arrow_circlepath, color: green),
              SizedBox(width: 9),
              Text(
                'despensa',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: const BoxDecoration(
                    color: mint,
                    borderRadius: BorderRadius.all(Radius.elliptical(85, 100)),
                  ),
                ),
                Transform.rotate(
                  angle: -.17,
                  child: ProductArt(
                    product: Product(id: 'welcome', name: 'Arroz'),
                    size: 132,
                  ),
                ),
                Positioned(
                  right: 25,
                  top: 23,
                  child: Transform.rotate(
                    angle: .15,
                    child: ProductArt(
                      product: Product(
                        id: 'welcome2',
                        name: 'Leite',
                        category: 'Bebidas',
                      ),
                      size: 90,
                    ),
                  ),
                ),
                Positioned(
                  left: 15,
                  bottom: 12,
                  child: Surface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_alt_circle_fill,
                          color: green,
                          size: 18,
                        ),
                        SizedBox(width: 7),
                        Text('Já tem em casa.', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          const Eyebrow('UM POUCO MAIS DE LEVEZA'),
          const SizedBox(height: 14),
          const Editorial('Sua casa.\nSeu ritmo.\nSua despensa.', size: 45),
          const SizedBox(height: 20),
          const Text(
            'Compre com intenção. Cuide do que já tem.\nSem medir cada gota, sem complicar a vida.',
            style: TextStyle(color: muted, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 30),
          FilledButton(
            onPressed: store.busy
                ? null
                : () => perform(
                    context,
                    () => store.change((d) => d.onboarded = true),
                  ),
            child: const Text('Começar minha despensa'),
          ),
          const SizedBox(height: 5),
          TextButton(
            onPressed: store.busy
                ? null
                : () =>
                      perform(context, () => store.replace(AppData.example())),
            child: const Text('Explorar com exemplos'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Só sua. Sem conta. Salva neste aparelho.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}
