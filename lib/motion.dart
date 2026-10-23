import 'dart:math' as math;
import 'package:flutter/material.dart';

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
    this.radius = 26,
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
      scale: pressed ? .975 : 1,
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
    duration: const Duration(milliseconds: 340),
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
      scale: 1 + math.sin(controller.value * math.pi) * .10,
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
