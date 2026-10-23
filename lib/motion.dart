import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'design.dart' show primary, success, warning, danger, secondary;
import 'haptics.dart';

/// cubic-bezier(.2, 0, 0, 1): surfaces, popovers and pages.
const emphasized = Cubic(.2, 0, 0, 1);

/// cubic-bezier(.65, 0, .35, 1): the fill of a package changing level.
const levelCurve = Cubic(.65, 0, .35, 1);

/// cubic-bezier(.34, 1.56, .64, 1): a playful overshoot for releases and pops.
const springOut = Cubic(.34, 1.56, .64, 1);

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
      duration: motionTime(context, pressed ? 110 : 360),
      curve: pressed ? Curves.easeOut : springOut,
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
  const BumpOnChange({
    super.key,
    required this.value,
    required this.child,
    this.amount = .2,
    this.enabled = true,
  });
  final Object value;
  final Widget child;
  final double amount;

  /// Lets a group share one value while only the newly chosen item bumps.
  final bool enabled;
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
    if (old.value != widget.value &&
        widget.enabled &&
        !MediaQuery.disableAnimationsOf(context)) {
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
      scale: 1 + math.sin(controller.value * math.pi) * widget.amount,
      child: child,
    ),
  );
}

/// Squashes and springs back when [value] changes, like a package being pressed.
class Squish extends StatefulWidget {
  const Squish({super.key, required this.value, required this.child});
  final Object value;
  final Widget child;
  @override
  State<Squish> createState() => _SquishState();
}

class _SquishState extends State<Squish> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );
  @override
  void didUpdateWidget(covariant Squish old) {
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
    builder: (_, child) {
      // A damped wobble: flat and wide first, then tall, then rest.
      final t = controller.value;
      final wobble = math.sin(t * math.pi * 2.5) * math.pow(1 - t, 1.6) * .14;
      return Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.diagonal3Values(1 + wobble * .7, 1 - wobble, 1),
        child: child,
      );
    },
  );
}

/// Shakes sideways once each time [trigger] changes: the "not this" answer.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});
  final Object trigger;
  final Widget child;
  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  @override
  void didUpdateWidget(covariant Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger &&
        !MediaQuery.disableAnimationsOf(context)) {
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
    builder: (_, child) {
      final t = controller.value;
      return Transform.translate(
        offset: Offset(math.sin(t * math.pi * 6) * (1 - t) * 9, 0),
        child: child,
      );
    },
  );
}

/// Plays once when first built: grows from slightly small with a spring.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.delay = 0});
  final Widget child;

  /// Fraction of the entrance spent waiting, for a short stagger.
  final double delay;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: motionTime(context, 420),
    builder: (_, t, child) {
      final p = springOut.transform(
        delay == 0 ? t : ((t - delay) / (1 - delay)).clamp(0, 1),
      );
      return Opacity(
        opacity: p.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - p) * 14),
          child: Transform.scale(scale: .94 + .06 * p, child: child),
        ),
      );
    },
    child: child,
  );
}

/// A number that rolls up when it grows and down when it shrinks.
class RollingNumber extends StatefulWidget {
  const RollingNumber({super.key, required this.value, required this.style});
  final int value;
  final TextStyle style;
  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber> {
  bool up = true;
  @override
  void didUpdateWidget(covariant RollingNumber old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) up = widget.value > old.value;
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedSwitcher(
      duration: motionTime(context, 260),
      switchInCurve: springOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(widget.value);
        final from = (incoming == up) ? .7 : -.7;
        return SlideTransition(
          position: Tween(
            begin: Offset(0, from),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        '${widget.value}',
        key: ValueKey(widget.value),
        style: widget.style,
      ),
    ),
  );
}

/// Floats a short label such as "−¼" up from the child when [value] changes.
class RiseOnChange extends StatefulWidget {
  const RiseOnChange({
    super.key,
    required this.value,
    required this.describe,
    required this.child,
    this.color = primary,
  });
  final double value;

  /// The label for a change, or null to stay quiet.
  final String? Function(double from, double to) describe;
  final Widget child;
  final Color color;
  @override
  State<RiseOnChange> createState() => _RiseOnChangeState();
}

class _RiseOnChangeState extends State<RiseOnChange>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
    value: 1,
  );
  String? label;
  @override
  void didUpdateWidget(covariant RiseOnChange old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    label = widget.describe(old.value, widget.value);
    if (label != null && !MediaQuery.disableAnimationsOf(context)) {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.topCenter,
    children: [
      widget.child,
      Positioned(
        top: -6,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: controller,
            builder: (_, _) {
              final t = controller.value;
              if (t == 1 || label == null) return const SizedBox.shrink();
              return Transform.translate(
                offset: Offset(0, -Curves.easeOutCubic.transform(t) * 30),
                child: Opacity(
                  opacity: t < .6 ? 1 : 1 - (t - .6) / .4,
                  child: Transform.scale(
                    scale: springOut.transform((t * 3).clamp(0, 1)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
}

/// A one-shot confetti burst over the whole app, for finished milestones.
void celebrate(BuildContext context) {
  Haptics.celebrate();
  if (MediaQuery.disableAnimationsOf(context)) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _Confetti(onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _Confetti extends StatefulWidget {
  const _Confetti({required this.onDone});
  final VoidCallback onDone;
  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  static const colors = [primary, success, warning, danger, secondary];
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..forward().whenComplete(widget.onDone);
  final pieces = List.generate(64, (i) {
    final random = math.Random(i * 7919);
    return (
      x: random.nextDouble(),
      drift: (random.nextDouble() - .5) * 140,
      delay: random.nextDouble() * .18,
      speed: .75 + random.nextDouble() * .5,
      spin: (random.nextDouble() - .5) * 14,
      size: 7 + random.nextDouble() * 6,
      round: random.nextBool(),
      color: colors[i % colors.length],
    );
  });
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: controller,
      builder: (_, _) => CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(pieces, controller.value),
      ),
    ),
  );
}

typedef _Piece = ({
  double x,
  double drift,
  double delay,
  double speed,
  double spin,
  double size,
  bool round,
  Color color,
});

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local == 0) continue;
      // Thrown up from the top edge, then falling with gravity and a sway.
      final y =
          -30 +
          (-260 * local + 1500 * local * local) * p.speed * size.height / 900;
      final x =
          p.x * size.width +
          p.drift * local +
          math.sin(local * 9 + p.x * 6) * 10;
      final paint = Paint()
        ..color = p.color.withValues(
          alpha: local > .75 ? (1 - local) / .25 : 1,
        );
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * local);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2.4, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * .45,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
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
