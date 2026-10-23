import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'models.dart';

const paper = Color(0xFFF7F6F0);
const ink = Color(0xFF203C35);
const muted = Color(0xFF788079);
const green = Color(0xFF386652);
const mint = Color(0xFFE3EDDD);
const peach = Color(0xFFF0D8BF);
const lineColor = Color(0xFFE6E7DE);
const orange = Color(0xFFAC5A31);

ThemeData pantryTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: paper,
  fontFamily: '.SF Pro Text',
  colorScheme: ColorScheme.fromSeed(
    seedColor: green,
    primary: green,
    surface: paper,
    onSurface: ink,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 15, height: 1.45, color: ink),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
  ),
  dividerColor: lineColor,
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: lineColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: lineColor),
    ),
    labelStyle: const TextStyle(color: muted),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: ink,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: green,
      minimumSize: const Size(44, 44),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: ink,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

class Editorial extends StatelessWidget {
  const Editorial(this.text, {super.key, this.size = 38, this.color = ink});
  final String text;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontFamily: 'Georgia',
      fontSize: size,
      height: 1.12,
      letterSpacing: -1.1,
      color: color,
    ),
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = muted});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: color,
      fontSize: 10,
      letterSpacing: 2,
      fontWeight: FontWeight.w700,
    ),
  );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: lineColor.withValues(alpha: .65)),
    ),
    child: child,
  );
}

class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.dark = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool dark;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: label,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: dark ? ink : Colors.white,
      foregroundColor: dark ? Colors.white : ink,
      minimumSize: const Size(48, 48),
      side: dark ? null : const BorderSide(color: lineColor),
    ),
    icon: Icon(icon, size: 21),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
    child: Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: const BoxDecoration(
            color: mint,
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          child: Icon(icon, size: 36, color: green),
        ),
        const SizedBox(height: 22),
        Editorial(title, size: 27),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, height: 1.5),
        ),
        if (action != null) ...[const SizedBox(height: 18), action!],
      ],
    ),
  );
}

IconData productIcon(String category, String name) {
  final n = name.toLowerCase();
  if (n.contains('café')) return CupertinoIcons.cube_box;
  if (n.contains('leite') || category == 'Bebidas') return CupertinoIcons.drop;
  if (category == 'Higiene') return CupertinoIcons.sparkles;
  if (category == 'Limpeza') return CupertinoIcons.drop_triangle;
  return CupertinoIcons.cube_box;
}

class ProductArt extends StatelessWidget {
  const ProductArt({super.key, required this.product, this.size = 64});
  final Product product;
  final double size;
  @override
  Widget build(BuildContext context) {
    Widget fallback() => CustomPaint(
      size: Size.square(size),
      painter: _PackagePainter(
        color: product.category == 'Bebidas'
            ? const Color(0xFFADC4CB)
            : product.category == 'Higiene'
            ? const Color(0xFFD6B1A2)
            : const Color(0xFFB3C39B),
        bottle: product.category == 'Bebidas',
        letter: product.name.isEmpty ? 'D' : product.name[0].toUpperCase(),
      ),
    );
    Widget image;
    if (product.photo.isNotEmpty) {
      image = Image.file(
        File(product.photo),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else if (product.remotePhoto.startsWith('https://')) {
      image = Image.network(
        product.remotePhoto,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else {
      image = fallback();
    }
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1E9),
        borderRadius: BorderRadius.circular(size * .26),
      ),
      child: image,
    );
  }
}

class _PackagePainter extends CustomPainter {
  _PackagePainter({
    required this.color,
    required this.bottle,
    required this.letter,
  });
  final Color color;
  final bool bottle;
  final String letter;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .5, h * .83),
        width: w * .48,
        height: h * .09,
      ),
      Paint()..color = ink.withValues(alpha: .07),
    );
    final shape = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .29, h * .23, w * .42, h * .58),
      Radius.circular(w * .05),
    );
    canvas.drawRRect(shape, Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .33, h * .13, w * .34, h * .15),
        Radius.circular(w * .025),
      ),
      Paint()..color = Color.lerp(color, ink, .18)!,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * .29, h * .43, w * .42, h * .23),
      Paint()..color = paper,
    );
    final text = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(fontFamily: 'Georgia', color: ink, fontSize: w * .17),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset((w - text.width) / 2, h * .45));
    canvas.drawLine(
      Offset(w * .35, h * .72),
      Offset(w * .63, h * .72),
      Paint()
        ..color = paper.withValues(alpha: .65)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _PackagePainter old) =>
      old.color != color || old.letter != letter;
}

Rect originRect(BuildContext context) {
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  return const Rect.fromLTWH(180, 700, 48, 48);
}

Future<T?> fluidPage<T>(BuildContext context, Widget page, {Rect? origin}) {
  final reduced = MediaQuery.disableAnimationsOf(context);
  final start = origin ?? originRect(context);
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      barrierLabel: 'Fechar painel',
      transitionDuration: Duration(milliseconds: reduced ? 0 : 620),
      reverseTransitionDuration: Duration(milliseconds: reduced ? 0 : 420),
      pageBuilder: (_, _, _) => ScaffoldMessenger(child: page),
      transitionsBuilder: (context, animation, secondary, child) =>
          AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final size = MediaQuery.sizeOf(context);
              final t = Curves.easeInOutCubicEmphasized.transform(
                animation.value,
              );
              final target = Rect.fromLTWH(0, 0, size.width, size.height);
              final rect = Rect.lerp(start, target, t)!;
              return Stack(
                children: [
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: t * 7, sigmaY: t * 7),
                      child: ColoredBox(
                        color: ink.withValues(alpha: animation.value * .16),
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: rect,
                    child: ClipPath(
                      clipper: FluidRevealClipper(t),
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minWidth: size.width,
                        maxWidth: size.width,
                        minHeight: size.height,
                        maxHeight: size.height,
                        child: Opacity(
                          opacity: (animation.value * 2).clamp(0, 1),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
    ),
  );
}

/// An asymmetric droplet that resolves into the page's final rectangular surface.
class FluidRevealClipper extends CustomClipper<Path> {
  FluidRevealClipper(this.progress);
  final double progress;
  @override
  Path getClip(Size size) {
    final bend = math.sin(progress * math.pi);
    final radius = math.min(size.width, size.height) * .5 * (1 - progress);
    return Path()..addRRect(
      RRect.fromRectAndCorners(
        Offset.zero & size,
        topLeft: Radius.circular(radius * (1 + bend * .28)),
        topRight: Radius.circular(radius * (1 - bend * .20)),
        bottomLeft: Radius.circular(radius * (1 - bend * .12)),
        bottomRight: Radius.circular(radius * (1 + bend * .22)),
      ),
    );
  }

  @override
  bool shouldReclip(covariant FluidRevealClipper old) =>
      old.progress != progress;
}

class PanelScaffold extends StatelessWidget {
  const PanelScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: paper,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 18, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Editorial(title, size: 30),
                      if (subtitle != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle!,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                RoundButton(
                  icon: CupertinoIcons.xmark,
                  label: 'Fechar',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(child: child),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
              child: SizedBox(width: double.infinity, child: footer),
            ),
        ],
      ),
    ),
  );
}

class LiquidLevel extends StatelessWidget {
  const LiquidLevel({super.key, required this.level, this.size = 110});
  final double level, size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: levelNames[(level * 4).round()],
    child: TweenAnimationBuilder<double>(
      tween: Tween(end: level),
      duration: Duration(
        milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 650,
      ),
      curve: Curves.easeInOutCubic,
      builder: (_, value, _) => CustomPaint(
        size: Size(size, size * 1.15),
        painter: _LiquidPainter(value),
      ),
    ),
  );
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter(this.level);
  final double level;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * .12,
      5,
      size.width * .76,
      size.height - 10,
    );
    final shape = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    canvas.drawRRect(shape, Paint()..color = mint);
    canvas.save();
    canvas.clipRRect(shape);
    final y = rect.bottom - rect.height * level;
    final wave = math.sin(level * math.pi) * 9;
    final path = Path()
      ..moveTo(rect.left, y)
      ..cubicTo(
        rect.left + rect.width * .3,
        y - wave,
        rect.left + rect.width * .7,
        y + wave,
        rect.right,
        y,
      )
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
    canvas.drawPath(path, Paint()..color = green.withValues(alpha: .75));
    canvas.restore();
    canvas.drawLine(
      Offset(size.width * .42, size.height * .5),
      Offset(size.width * .58, size.height * .5),
      Paint()
        ..color = paper
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter old) => old.level != level;
}
