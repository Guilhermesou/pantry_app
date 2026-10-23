import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design.dart';
import '../main.dart';
import '../models.dart';
import '../motion.dart';
import '../store.dart';
import '../symbols.dart';
import '../toast.dart';
import 'capture.dart';
import 'editors.dart';
import 'history.dart';
import 'product.dart';
import 'quick_level.dart';
import 'receipts.dart';
import 'settings.dart';
import 'shopping.dart';
import 'stock.dart';
import 'today.dart';
import 'welcome.dart';

class PantryHome extends StatefulWidget {
  const PantryHome({super.key, required this.store});
  final PantryStore store;
  @override
  State<PantryHome> createState() => _PantryHomeState();
}

class _PantryHomeState extends State<PantryHome>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int tab = 0;
  bool addOpen = false, moreOpen = false;
  // Expiry warnings acknowledged with "Vi" during this session; lots stay untouched.
  final seen = <String>{};
  late final addMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final moreMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
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
    addMotion.dispose();
    moreMotion.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) store.refreshTime();
  }

  void _drive(AnimationController controller, bool open) {
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.value = open ? 1 : 0;
    } else if (open) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }

  void setAdd(bool value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      addOpen = value;
      if (value) moreOpen = false;
    });
    _drive(addMotion, value);
    if (value) _drive(moreMotion, false);
  }

  void setMore(bool value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      moreOpen = value;
      if (value) addOpen = false;
    });
    _drive(moreMotion, value);
    if (value) _drive(addMotion, false);
  }

  void closeOverlays() {
    if (addOpen) setAdd(false);
    if (moreOpen) setMore(false);
  }

  void selectTab(int index) {
    if (index == tab) return closeOverlays();
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    setState(() {
      tab = index;
      addOpen = moreOpen = false;
    });
    addMotion.value = 0;
    moreMotion.value = 0;
  }

  void openSheet(Widget page) {
    closeOverlays();
    showSheet(context, page);
  }

  void openPage(Widget page) {
    closeOverlays();
    pushPage(context, page);
  }

  void openProduct(Product p) =>
      openSheet(ProductDetail(store: store, id: p.id));

  Future<void> addSuggestion(Product p) async {
    final ok = await perform(
      context,
      () => store.addSuggestion(p.id),
      success: '${p.name} foi para a lista.',
    );
    if (ok) HapticFeedback.lightImpact();
  }

  void acknowledgeExpiry(Product p) {
    HapticFeedback.selectionClick();
    setState(() => seen.add(expiryKey(p)));
    showToast(context, '${p.name}: usar primeiro.');
  }

  /// A tap on an opened package lowers it by a quarter; the last quarter finishes it.
  Future<void> lowerLevel(Product p, int index) async {
    final level = p.opened[index], lotId = p.openedLotIds[index];
    final next = ((level * 4).round() - 1) / 4;
    HapticFeedback.selectionClick();
    if (next > 0) {
      await perform(context, () => store.setLevel(p.id, index, next));
      return;
    }
    final ok = await perform(context, () => store.setLevel(p.id, index, 0));
    if (ok && mounted) {
      showToast(
        context,
        '${p.name}: embalagem finalizada.',
        undo: () =>
            perform(context, () => store.restoreOpened(p.id, level, lotId)),
      );
    }
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
      final overlay = addOpen || moreOpen;
      final navBottom = floatingNavBottom(context);
      return PopScope(
        canPop: !overlay,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) closeOverlays();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  excluding: overlay,
                  child: IndexedStack(
                    index: tab,
                    children: [
                      TickerMode(
                        enabled: tab == 0,
                        child: TodayContent(
                          store: store,
                          header: _header(
                            capitalized(todayLabel(DateTime.now())),
                          ),
                          seen: seen,
                          onSeen: acknowledgeExpiry,
                          onList: () => selectTab(1),
                          onAdd: () => openSheet(ProductEditor(store: store)),
                          onProduct: openProduct,
                          onLevelDown: lowerLevel,
                          onLevelDetail: (p, i) =>
                              showQuickLevel(context, store, p.id, i),
                          onSuggestion: addSuggestion,
                        ),
                      ),
                      TickerMode(
                        enabled: tab == 1,
                        child: ShoppingContent(
                          store: store,
                          header: _header('Menos esquecimento'),
                          onEdit: (item) => openSheet(
                            ShoppingEditor(store: store, item: item),
                          ),
                          onToggle: toggleItem,
                          onBudget: () => openSheet(BudgetEditor(store: store)),
                        ),
                      ),
                      TickerMode(
                        enabled: tab == 2,
                        child: StockContent(
                          store: store,
                          header: _header('Cuidar do que já está em casa'),
                          onProduct: openProduct,
                          onAdd: () => openSheet(ProductEditor(store: store)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: navBottom + 102,
                child: const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: [0, .55, 1],
                        colors: [Colors.white, Colors.white, Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),
              ),
              _checkoutBar(navBottom),
              _dim(),
              _addMenu(navBottom),
              _moreMenu(),
              Positioned(
                left: 16,
                right: 16,
                bottom: navBottom,
                child: _navigation(),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _header(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: muted),
          ),
        ),
        IconButton(
          tooltip: 'Mais',
          onPressed: () => setMore(!moreOpen),
          style: IconButton.styleFrom(
            backgroundColor: zinc100,
            foregroundColor: zinc700,
            fixedSize: const Size(40, 40),
            minimumSize: const Size(40, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Symbols.moreHoriz, size: 22),
        ),
      ],
    ),
  );

  Widget _navigation() => Row(
    children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.all(4),
              color: zinc100.withValues(alpha: .92),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    for (final (index, icon, title) in [
                      (0, Symbols.wbSunny, 'Hoje'),
                      (1, Symbols.checklist, 'Lista'),
                      (2, Symbols.package2, 'Estoque'),
                    ]) ...[
                      if (index > 0) const SizedBox(width: 2),
                      Expanded(child: _navItem(index, icon, title)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Tooltip(
        message: addOpen ? 'Fechar atalhos' : 'Adicionar',
        child: Semantics(
          button: true,
          label: addOpen ? 'Fechar atalhos' : 'Adicionar',
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              boxShadow: shadowPrimary,
            ),
            child: Material(
              type: MaterialType.transparency,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: store.busy
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        setAdd(!addOpen);
                      },
                splashColor: Colors.white24,
                child: AnimatedRotation(
                  turns: addOpen ? .125 : 0,
                  duration: motionTime(context, 400),
                  curve: emphasized,
                  child: const Icon(Symbols.add, color: Colors.white, size: 26),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _navItem(int index, IconData icon, String title) {
    final selected = tab == index;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('nav-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: () => selectTab(index),
        child: AnimatedContainer(
          duration: motionTime(context, 250),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected ? shadowSmall : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  fill: selected ? 1 : 0,
                  color: selected ? fg : muted,
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? fg : muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkoutBar(double navBottom) {
    final cart = data.list.where((e) => e.checked).length;
    final visible = cart > 0 && tab == 1;
    return Positioned(
      left: 16,
      right: 16,
      bottom: navBottom + 72,
      child: IgnorePointer(
        ignoring: !visible,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: visible ? 0 : 160),
          duration: motionTime(context, 450),
          curve: emphasized,
          builder: (_, dy, child) => Transform.translate(
            offset: Offset(0, dy),
            child: Opacity(opacity: (1 - dy / 160).clamp(0, 1), child: child),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: shadowPrimary,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: const ValueKey('checkout-bar'),
                borderRadius: BorderRadius.circular(14),
                splashColor: Colors.white24,
                onTap: store.busy ? null : checkout,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        const Icon(
                          Symbols.check,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Guardar no estoque · ${cart == 1 ? '1 item' : '$cart itens'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedMoney(
                          value: data.cart,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dim() => AnimatedBuilder(
    animation: Listenable.merge([addMotion, moreMotion]),
    builder: (context, _) {
      final t = math.max(addMotion.value, moreMotion.value);
      if (t == 0) return const SizedBox.shrink();
      return Positioned.fill(
        child: GestureDetector(
          onTap: closeOverlays,
          behavior: HitTestBehavior.opaque,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: t * 4, sigmaY: t * 4),
            child: ColoredBox(color: Colors.black.withValues(alpha: t * .3)),
          ),
        ),
      );
    },
  );

  Widget _popover({
    required AnimationController motion,
    required bool open,
    required Alignment origin,
    required Widget child,
  }) => IgnorePointer(
    ignoring: !open,
    child: AnimatedBuilder(
      animation: motion,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: shadowLarge,
        ),
        child: Material(type: MaterialType.transparency, child: child),
      ),
      builder: (_, child) {
        final t = emphasized.transform(motion.value);
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: .85 + .15 * t,
            alignment: origin,
            child: child,
          ),
        );
      },
    ),
  );

  Widget _menuItem({
    required Widget leading,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _addMenu(double navBottom) {
    if (!addOpen && addMotion.isDismissed) return const SizedBox.shrink();
    final actions = <(IconData, String, String, VoidCallback)>[
      (
        Symbols.editNote,
        'Um item na lista',
        'Nome, quantidade e preço',
        () => openSheet(ShoppingEditor(store: store)),
      ),
      (
        Symbols.package2,
        'Um produto no estoque',
        'O que você já tem em casa',
        () => openSheet(ProductEditor(store: store)),
      ),
      (
        Symbols.barcodeScanner,
        'Código de barras',
        'Câmera ou digitação',
        () => openPage(BarcodePage(store: store)),
      ),
      (
        Symbols.receiptLong,
        'Cupom',
        'Foto, galeria ou texto colado',
        () => openPage(ReceiptCapture(store: store)),
      ),
    ];
    return Positioned(
      right: 16,
      bottom: navBottom + 72,
      width: 250,
      child: _popover(
        motion: addMotion,
        open: addOpen,
        origin: Alignment.bottomRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                'Adicionar',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ),
            for (final (icon, title, subtitle, onTap) in actions)
              _menuItem(
                leading: IconTile(icon),
                title: title,
                subtitle: subtitle,
                onTap: onTap,
              ),
          ],
        ),
      ),
    );
  }

  Widget _moreMenu() {
    if (!moreOpen && moreMotion.isDismissed) return const SizedBox.shrink();
    Widget item(IconData icon, String title, String subtitle, Widget page) =>
        _menuItem(
          leading: Icon(icon, size: 20, color: muted),
          title: title,
          subtitle: subtitle,
          onTap: () => openPage(page),
        );
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 50,
      right: 16,
      width: 240,
      child: _popover(
        motion: moreMotion,
        open: moreOpen,
        origin: Alignment.topRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            item(
              Symbols.history,
              'Histórico',
              'Compras, aberturas e ajustes',
              HistoryPage(store: store),
            ),
            item(
              Symbols.receiptLong,
              'Notas e cupons',
              'Comprovantes das suas compras',
              ReceiptsPage(store: store),
            ),
            const Divider(height: 9, indent: 8, endIndent: 8, color: zinc200),
            item(
              Symbols.tune,
              'Ajustes e backup',
              'Orçamento, dados e exemplos',
              SettingsPage(store: store),
            ),
          ],
        ),
      ),
    );
  }
}
