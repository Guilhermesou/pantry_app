import 'package:flutter/material.dart';
import 'design.dart';
import 'models.dart';
import 'motion.dart';

/// Package silhouettes on a 60×70 canvas: the body holds the level, the extra is the cap or lid.
const _shapes = {
  'carton': (
    body:
        'M14 24 L22 12 L38 12 L46 24 L46 62 Q46 66 42 66 L18 66 Q14 66 14 62 Z',
    extra: 'M21 5 H39 V12 H21 Z',
  ),
  'bag': (
    body:
        'M17 15 L43 15 Q49 40 46 61 Q45 66 40 66 L20 66 Q15 66 14 61 Q11 40 17 15 Z',
    extra: 'M19 8 Q30 13 41 8 L41 15 L19 15 Z',
  ),
  'pouch': (
    body: 'M14 10 L46 10 L46 57 Q46 66 37 66 L23 66 Q14 66 14 57 Z',
    extra: 'M14 10 L46 10 L46 15 L14 15 Z',
  ),
  'tub': (
    body: 'M13 25 L47 25 L43 63 Q43 66 40 66 L20 66 Q17 66 17 63 Z',
    extra: 'M10 18 Q10 16 12 16 L48 16 Q50 16 50 18 L50 25 L10 25 Z',
  ),
  'bottle': (
    body:
        'M25 16 L35 16 Q44 20 44 30 L44 62 Q44 66 40 66 L20 66 Q16 66 16 62 L16 30 Q16 20 25 16 Z',
    extra: 'M24 6 H36 V16 H24 Z',
  ),
  'bar': (
    body:
        'M10 30 Q10 22 18 22 L42 22 Q50 22 50 30 L50 58 Q50 66 42 66 L18 66 Q10 66 10 58 Z',
    extra: '',
  ),
};

String packageShape(Product p) {
  final n = normalized(p.name);
  bool has(List<String> words) => words.any(n.contains);
  if (has(['leite', 'suco', 'creme de leite'])) return 'carton';
  if (has(['iogurte', 'manteiga', 'margarina', 'requeij', 'sorvete'])) {
    return 'tub';
  }
  if (has(['arroz', 'feij', 'açúcar', 'acucar', 'farinha', 'macarr'])) {
    return 'bag';
  }
  if (has(['café', 'cafe'])) return 'pouch';
  return switch (p.category) {
    'Bebidas' || 'Limpeza' => 'bottle',
    'Higiene' => 'bar',
    _ => 'pouch',
  };
}

final _paths = <String, Path>{};
Path _svg(String d) => _paths.putIfAbsent(d, () {
  final path = Path();
  final tokens = RegExp(r'[MLQHVZ]|-?\d*\.?\d+').allMatches(d).toList();
  var i = 0;
  var command = 'M';
  var x = 0.0, y = 0.0;
  double next() => double.parse(tokens[i++].group(0)!);
  while (i < tokens.length) {
    final token = tokens[i].group(0)!;
    if (RegExp('[MLQHVZ]').hasMatch(token)) {
      command = token;
      i++;
      if (command == 'Z') path.close();
      continue;
    }
    switch (command) {
      case 'M':
        path.moveTo(x = next(), y = next());
      case 'L':
        path.lineTo(x = next(), y = next());
      case 'H':
        path.lineTo(x = next(), y);
      case 'V':
        path.lineTo(x, y = next());
      case 'Q':
        final cx = next(), cy = next();
        path.quadraticBezierTo(cx, cy, x = next(), y = next());
      default:
        i++;
    }
  }
  return path;
});

/// A package filled to an approximate level. The fill only interpolates when the level changes.
class PackageIllustration extends StatelessWidget {
  const PackageIllustration({
    super.key,
    required this.product,
    required this.level,
    this.width = 52,
    this.shadow = true,
  });
  final Product product;
  final double level, width;
  final bool shadow;
  @override
  Widget build(BuildContext context) => Semantics(
    label: levelNames[(level * 4).round().clamp(0, 4)],
    child: TweenAnimationBuilder<double>(
      tween: Tween(end: level),
      duration: motionTime(context, 600),
      curve: levelCurve,
      builder: (_, value, _) => CustomPaint(
        size: Size(width, width * 70 / 60),
        painter: _PackagePainter(
          shape: packageShape(product),
          art: artFor(product),
          level: value,
          shadow: shadow,
        ),
      ),
    ),
  );
}

class _PackagePainter extends CustomPainter {
  _PackagePainter({
    required this.shape,
    required this.art,
    required this.level,
    required this.shadow,
  });
  final String shape;
  final ({Color tint, Color ink, IconData icon}) art;
  final double level;
  final bool shadow;
  @override
  void paint(Canvas canvas, Size size) {
    final s = _shapes[shape]!;
    canvas.save();
    canvas.scale(size.width / 60, size.height / 70);
    if (shadow) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(30, 67), width: 36, height: 5),
        Paint()..color = const Color(0x0F000000),
      );
    }
    final body = _svg(s.body);
    canvas.drawPath(body, Paint()..color = art.tint);
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
      Rect.fromLTWH(0, 10 + (1 - level) * 56, 60, 70),
      Paint()..color = art.ink.withValues(alpha: .8),
    );
    canvas.restore();
    if (s.extra.isNotEmpty) {
      canvas.drawPath(_svg(s.extra), Paint()..color = art.ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PackagePainter old) =>
      old.level != level || old.shape != shape || old.art != art;
}
