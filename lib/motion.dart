import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// cubic-bezier(.2, 0, 0, 1): surfaces, popovers and pages.
const emphasized = Cubic(.2, 0, 0, 1);

/// cubic-bezier(.65, 0, .35, 1): the fill of a package changing level.
const levelCurve = Cubic(.65, 0, .35, 1);

Duration motionTime(BuildContext context, int milliseconds) => Duration(
  milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : milliseconds,
);

/// A finite response to touch; never starts a repeating animation.
class TouchSurface extends StatefulWidget {
  const TouchSurface({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.label,
    this.radius = 14,
  });
  final Widget child;
  final VoidCallback? onTap, onLongPress;
  final String? label;
  final double radius;
  @override
  State<TouchSurface> createState() => _TouchSurfaceState();
}

class _TouchSurfaceState extends State<TouchSurface> {
  bool pressed = false;
  void press(bool value) {
    if (pressed != value) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    button: widget.onTap != null,
    child: AnimatedScale(
      scale: pressed ? .97 : 1,
      duration: motionTime(context, pressed ? 110 : 260),
      curve: pressed ? Curves.easeOut : Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.radius),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onHighlightChanged: press,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: widget.child,
        ),
      ),
    ),
  );
}

/// Scales up and settles back once when [value] changes.
class BumpOnChange extends StatefulWidget {
  const BumpOnChange({super.key, required this.value, required this.child});
  final Object value;
  final Widget child;
  @override
  State<BumpOnChange> createState() => _BumpOnChangeState();
}

class _BumpOnChangeState extends State<BumpOnChange>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    value: 1,
  );
  @override
  void didUpdateWidget(covariant BumpOnChange old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !MediaQuery.disableAnimationsOf(context)) {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: widget.child,
    builder: (_, child) => Transform.scale(
      scale: 1 + math.sin(controller.value * math.pi) * .2,
      child: child,
    ),
  );
}

class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({super.key, required this.value, required this.style});
  final double value;
  final TextStyle style;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value),
    duration: motionTime(context, 380),
    curve: Curves.easeOutCubic,
    builder: (_, amount, _) => Text(
      'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
      style: style,
    ),
  );
}

/// Shows its confirmed state for a moment, then folds away; removed once folded.
class Collapsible extends StatefulWidget {
  const Collapsible({super.key, required this.collapsed, required this.child});
  final bool collapsed;
  final Widget child;
  @override
  State<Collapsible> createState() => _CollapsibleState();
}

class _CollapsibleState extends State<Collapsible>
    with SingleTickerProviderStateMixin {
  // 350 ms hold, then 500 ms of height and 300 ms of opacity.
  static const total = 850, hold = 350;
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: total),
    value: widget.collapsed ? 1 : 0,
  );
  @override
  void didUpdateWidget(covariant Collapsible old) {
    super.didUpdateWidget(old);
    if (old.collapsed == widget.collapsed) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.value = widget.collapsed ? 1 : 0;
    } else if (widget.collapsed) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: widget.child,
    builder: (_, child) {
      final t = controller.value;
      if (t == 1) return const SizedBox.shrink();
      // Clip only while folding, so the card's shadow stays soft at rest.
      if (t == 0) return child!;
      final height = const Interval(
        hold / total,
        1,
        curve: emphasized,
      ).transform(t);
      final fade = const Interval(
        hold / total,
        (hold + 300) / total,
      ).transform(t);
      return ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1 - height,
          child: Opacity(opacity: 1 - fade, child: child),
        ),
      );
    },
  );
}

/// A page that slides over the app from the right edge.
Future<T?> pushPage<T>(BuildContext context, Widget page) {
  final reduced = MediaQuery.disableAnimationsOf(context);
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      transitionDuration: Duration(milliseconds: reduced ? 0 : 500),
      reverseTransitionDuration: Duration(milliseconds: reduced ? 0 : 420),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: CurvedAnimation(
          parent: animation,
          curve: emphasized,
          reverseCurve: emphasized.flipped,
        ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
        child: child,
      ),
    ),
  );
}

/// A sheet rising from the bottom over a dimmed, blurred backdrop.
Future<T?> showSheet<T>(BuildContext context, Widget page) {
  final reduced = MediaQuery.disableAnimationsOf(context);
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierLabel: 'Fechar',
      transitionDuration: Duration(milliseconds: reduced ? 0 : 500),
      reverseTransitionDuration: Duration(milliseconds: reduced ? 0 : 380),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (context, animation, _, child) {
        final top = MediaQuery.paddingOf(context).top + 10;
        final curved = CurvedAnimation(
          parent: animation,
          curve: emphasized,
          reverseCurve: emphasized.flipped,
        );
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (_, _) => BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: animation.value * 4,
                      sigmaY: animation.value * 4,
                    ),
                    child: ColoredBox(
                      color: Colors.black.withValues(
                        alpha: animation.value * .3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: top,
              bottom: 0,
              child: SlideTransition(
                position: curved.drive(
                  Tween(begin: const Offset(0, 1.05), end: Offset.zero),
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x14000000),
                        offset: Offset(0, -10),
                        blurRadius: 33.77,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
