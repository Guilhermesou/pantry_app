import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design.dart';
import '../main.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';
import 'editors.dart';
import 'capture.dart';
import 'history.dart';
import 'lots.dart';
import 'quick_level.dart';
import 'settings.dart';
import 'shopping.dart';
import 'stock.dart';
import 'today.dart';
import 'welcome.dart';

enum _MoreAction { history, settings }

class PantryHome extends StatefulWidget {
  const PantryHome({super.key, required this.store});
  final PantryStore store;
  @override
  State<PantryHome> createState() => _PantryHomeState();
}

class _PantryHomeState extends State<PantryHome>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int tab = 0;
  bool fabOpen = false;
  late final fabMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 430),
    reverseDuration: const Duration(milliseconds: 260),
  );
  late final tabMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );
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
    fabMotion.dispose();
    tabMotion.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) store.refreshTime();
  }

  void setFab(bool value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => fabOpen = value);
    if (MediaQuery.disableAnimationsOf(context)) {
      fabMotion.value = value ? 1 : 0;
    } else if (value) {
      fabMotion.forward();
    } else {
      fabMotion.reverse();
    }
  }

  void selectTab(int index) {
    if (index == tab) {
      if (fabOpen) setFab(false);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    setState(() {
      tab = index;
      fabOpen = false;
    });
    fabMotion.value = 0;
    if (MediaQuery.disableAnimationsOf(context)) {
      tabMotion.value = 1;
    } else {
      tabMotion.forward(from: 0);
    }
  }

  void openPage(BuildContext anchor, Widget page) {
    final origin = originRect(anchor);
    if (fabOpen) setFab(false);
    fluidPage(context, page, origin: origin);
  }

  void openProduct(BuildContext anchor, Product p) =>
      openPage(anchor, ProductDetail(store: store, id: p.id));
  void openLevel(BuildContext anchor, Product p, int index) =>
      showQuickLevel(context, store, p.id, index, origin: originRect(anchor));
  Future<void> addSuggestion(Product p) async {
    final ok = await perform(
      context,
      () => store.addSuggestion(p.id),
      success: '${p.name} foi para a lista.',
    );
    if (ok) HapticFeedback.lightImpact();
  }

  Future<void> toggleItem(ShoppingItem item) async {
    HapticFeedback.selectionClick();
    await perform(
      context,
      () => store.change((d) {
        final current = d.list.firstWhere((e) => e.id == item.id);
        current.checked = !current.checked;
      }),
    );
  }

  Future<void> checkout() async {
    final count = data.list.where((e) => e.checked).length;
    if (count == 0) return;
    if (await confirm(
          context,
          'Guardar a compra?',
          'Os $count itens marcados entram no estoque e saem da lista. Se usar o cupom desta compra, importe o cupom em vez de confirmar aqui.',
          label: 'Guardar no estoque',
        ) &&
        mounted) {
      final ok = await perform(
        context,
        store.checkout,
        success: 'Compra guardada. Tudo no seu lugar.',
      );
      if (ok) HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      if (!data.onboarded) return WelcomePage(store: store);
      return PopScope(
        canPop: !fabOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && fabOpen) setFab(false);
        },
        child: Scaffold(
          body: Stack(
            children: [
              ExcludeSemantics(
                excluding: fabOpen,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      if (data.demo)
                        Container(
                          width: double.infinity,
                          color: peach,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 7,
                          ),
                          child: const Text(
                            'Exemplos · seus dados começam quando você quiser.',
                            style: TextStyle(fontSize: 10, color: ink),
                          ),
                        ),
                      _topBar(),
                      Expanded(
                        child: FadeTransition(
                          opacity: tabMotion.drive(
                            CurveTween(curve: Curves.easeOut),
                          ),
                          child: SlideTransition(
                            position: tabMotion.drive(
                              Tween(
                                begin: const Offset(0, .018),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeOutCubic)),
                            ),
                            child: IndexedStack(
                              index: tab,
                              children: [
                                TickerMode(
                                  enabled: tab == 0,
                                  child: TodayContent(
                                    store: store,
                                    onList: () => selectTab(1),
                                    onAdd: (anchor) => openPage(
                                      anchor,
                                      ProductEditor(store: store),
                                    ),
                                    onProduct: openProduct,
                                    onLevel: openLevel,
                                    onSuggestion: addSuggestion,
                                  ),
                                ),
                                TickerMode(
                                  enabled: tab == 1,
                                  child: ShoppingContent(
                                    store: store,
                                    onEdit: (anchor, item) => openPage(
                                      anchor,
                                      ShoppingEditor(store: store, item: item),
                                    ),
                                    onToggle: toggleItem,
                                    onBudget: (anchor) => openPage(
                                      anchor,
                                      BudgetEditor(store: store),
                                    ),
                                    onCheckout: checkout,
                                    onAdd: (anchor) => openPage(
                                      anchor,
                                      ShoppingEditor(store: store),
                                    ),
                                  ),
                                ),
                                TickerMode(
                                  enabled: tab == 2,
                                  child: StockContent(
                                    store: store,
                                    onProduct: openProduct,
                                    onLevel: openLevel,
                                    onOpen: (p) =>
                                        choosePackage(context, store, p.id),
                                    onAdd: (anchor) => openPage(
                                      anchor,
                                      ProductEditor(store: store),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _addOverlay(),
            ],
          ),
          bottomNavigationBar: _navigation(),
        ),
      );
    },
  );

  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 16, 8),
    child: Row(
      children: [
        Expanded(
          child: Eyebrow(
            tab == 0
                ? todayLabel(DateTime.now())
                : tab == 1
                ? 'MENOS ESQUECIMENTO'
                : 'CUIDAR DO QUE JÁ ESTÁ EM CASA',
          ),
        ),
        Builder(
          builder: (anchor) => PopupMenuButton<_MoreAction>(
            tooltip: 'Mais',
            position: PopupMenuPosition.under,
            color: Colors.white,
            popUpAnimationStyle: AnimationStyle(
              duration: motionTime(context, 280),
              curve: Curves.easeOutCubic,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            icon: const Icon(CupertinoIcons.ellipsis, size: 22, color: ink),
            onSelected: (action) => openPage(
              anchor,
              action == _MoreAction.history
                  ? HistoryPage(store: store)
                  : SettingsPage(store: store),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _MoreAction.history,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(CupertinoIcons.clock, color: green, size: 20),
                  title: Text('Histórico', style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    'Compras, aberturas e ajustes',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const PopupMenuItem(
                value: _MoreAction.settings,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    CupertinoIcons.slider_horizontal_3,
                    color: green,
                    size: 20,
                  ),
                  title: Text(
                    'Ajustes e backup',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    'Seus dados e preferências',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _navigation() => Container(
    decoration: const BoxDecoration(
      color: paper,
      border: Border(top: BorderSide(color: lineColor)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            for (final (index, icon, title) in [
              (0, CupertinoIcons.sun_max, 'Hoje'),
              (1, CupertinoIcons.list_bullet, 'Lista'),
              (2, CupertinoIcons.cube_box, 'Estoque'),
            ])
              Expanded(
                child: Semantics(
                  selected: tab == index,
                  child: TouchSurface(
                    label: 'Abrir $title',
                    radius: 18,
                    onTap: () => selectTab(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: motionTime(context, 250),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tab == index
                                  ? mint.withValues(alpha: .55)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              icon,
                              size: 22,
                              color: tab == index ? green : muted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: motionTime(context, 180),
                            style: TextStyle(
                              fontFamily: '.SF Pro Text',
                              fontSize: 10,
                              color: tab == index ? green : muted,
                              fontWeight: tab == index
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                            child: Text(title),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Builder(
              builder: (anchor) => TouchSurface(
                onTap: store.busy
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        setFab(!fabOpen);
                      },
                label: fabOpen ? 'Fechar atalhos' : 'Adicionar',
                child: Tooltip(
                  message: fabOpen ? 'Fechar atalhos' : 'Adicionar',
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: ink,
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedRotation(
                      turns: fabOpen ? .125 : 0,
                      duration: motionTime(context, 350),
                      curve: Curves.easeInOutCubicEmphasized,
                      child: const Icon(
                        CupertinoIcons.add,
                        color: paper,
                        size: 23,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _addOverlay() => AnimatedBuilder(
    animation: fabMotion,
    builder: (context, _) {
      if (!fabOpen && !fabMotion.isAnimating) return const SizedBox();
      final t = fabMotion.value;
      final actions = <(IconData, String, String, Widget)>[
        (
          CupertinoIcons.list_bullet,
          'Um item na lista',
          'Nome, quantidade e preço',
          ShoppingEditor(store: store),
        ),
        (
          CupertinoIcons.cube_box,
          'Um produto no estoque',
          'O que você já tem em casa',
          ProductEditor(store: store),
        ),
        (
          CupertinoIcons.barcode_viewfinder,
          'Ler código de barras',
          'Câmera ou digitação',
          BarcodePage(store: store),
        ),
        (
          CupertinoIcons.doc_text_viewfinder,
          'Importar um cupom',
          'Foto, galeria ou texto',
          ReceiptCapture(store: store),
        ),
      ];
      return Positioned.fill(
        child: IgnorePointer(
          ignoring: !fabOpen,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setFab(false),
                  behavior: HitTestBehavior.opaque,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: t * 7, sigmaY: t * 7),
                    child: ColoredBox(color: ink.withValues(alpha: t * .16)),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < actions.length; i++)
                        Builder(
                          builder: (anchor) {
                            final (icon, title, subtitle, page) = actions[i];
                            final progress = Curves.easeOutCubic.transform(
                              ((t - (actions.length - 1 - i) * .08) / .76)
                                  .clamp(0, 1),
                            );
                            return Opacity(
                              opacity: progress,
                              child: Transform.translate(
                                offset: Offset(0, (1 - progress) * 32),
                                child: Transform.scale(
                                  scale: .88 + progress * .12,
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: TouchSurface(
                                      onTap: () => openPage(anchor, page),
                                      child: Surface(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          10,
                                          16,
                                          10,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 37,
                                              height: 37,
                                              decoration: BoxDecoration(
                                                color: paper,
                                                borderRadius:
                                                    BorderRadius.circular(13),
                                              ),
                                              child: Icon(
                                                icon,
                                                color: green,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    subtitle,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: muted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
