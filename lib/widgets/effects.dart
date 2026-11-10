import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

Path heartPath(Offset c, double s) {
  final p = Path();
  p.moveTo(c.dx, c.dy + s * 0.9);
  p.cubicTo(c.dx - s * 1.6, c.dy - s * 0.1, c.dx - s * 0.9, c.dy - s * 1.2, c.dx, c.dy - s * 0.35);
  p.cubicTo(c.dx + s * 0.9, c.dy - s * 1.2, c.dx + s * 1.6, c.dy - s * 0.1, c.dx, c.dy + s * 0.9);
  p.close();
  return p;
}

Path starPath(Offset c, double r, {double rot = 0}) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final rad = i.isEven ? r : r * 0.45;
    final a = rot + math.pi * i / 5 - math.pi / 2;
    final x = c.dx + rad * math.cos(a);
    final y = c.dy + rad * math.sin(a);
    if (i == 0) {
      p.moveTo(x, y);
    } else {
      p.lineTo(x, y);
    }
  }
  p.close();
  return p;
}

/// Crack lines drawn over an egg. [progress] 0..1 grows the cracks.
class CrackPainter extends CustomPainter {
  CrackPainter(this.progress);
  final double progress;

  static const _main = [
    Offset(0.20, 0.52), Offset(0.33, 0.44), Offset(0.42, 0.56), Offset(0.52, 0.43),
    Offset(0.62, 0.57), Offset(0.72, 0.45), Offset(0.82, 0.53),
  ];
  static const _branches = [
    [Offset(0.42, 0.56), Offset(0.37, 0.72)],
    [Offset(0.62, 0.57), Offset(0.67, 0.74)],
    [Offset(0.33, 0.44), Offset(0.29, 0.28)],
    [Offset(0.72, 0.45), Offset(0.76, 0.30)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final dark = Paint()
      ..color = const Color(0xFF3E2A1C)
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final light = Paint()
      ..color = const Color(0xAAFFFFFF)
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    Offset pt(Offset o) => Offset(o.dx * size.width, o.dy * size.height);

    final n = _main.length - 1;
    final seg = progress.clamp(0.0, 1.0) * n;
    for (var i = 0; i < n; i++) {
      final f = (seg - i).clamp(0.0, 1.0);
      if (f <= 0) break;
      final a = pt(_main[i]);
      final b = Offset.lerp(a, pt(_main[i + 1]), f)!;
      canvas.drawLine(a, b, dark);
      canvas.drawLine(a.translate(2, -2), b.translate(2, -2), light);
    }
    final bp = ((progress - 0.5) * 2).clamp(0.0, 1.0);
    if (bp > 0) {
      for (final br in _branches) {
        final a = pt(br[0]);
        final b = Offset.lerp(a, pt(br[1]), bp)!;
        canvas.drawLine(a, b, dark);
      }
    }
  }

  @override
  bool shouldRepaint(CrackPainter old) => old.progress != progress;
}

/// Clips the top or bottom half of an egg along a zig-zag line.
class EggHalfClipper extends CustomClipper<Path> {
  EggHalfClipper({required this.top});
  final bool top;

  @override
  Path getClip(Size size) {
    const teeth = 7;
    final pts = <Offset>[];
    for (var i = 0; i <= teeth; i++) {
      pts.add(Offset(
        size.width * i / teeth,
        size.height * (0.52 + (i.isOdd ? -0.05 : 0.05)),
      ));
    }
    final p = Path();
    if (top) {
      p.moveTo(0, 0);
      p.lineTo(size.width, 0);
      for (var i = pts.length - 1; i >= 0; i--) {
        p.lineTo(pts[i].dx, pts[i].dy);
      }
    } else {
      p.moveTo(0, size.height);
      p.lineTo(size.width, size.height);
      for (var i = pts.length - 1; i >= 0; i--) {
        p.lineTo(pts[i].dx, pts[i].dy);
      }
    }
    p.close();
    return p;
  }

  @override
  bool shouldReclip(EggHalfClipper old) => old.top != top;
}

/// Hearts, stars and dots flying out of the centre of the canvas.
class BurstPainter extends CustomPainter {
  BurstPainter({required this.t, this.seed = 1});
  final double t; // 0..1
  final int seed;

  static const _colors = [
    Color(0xFFFF5C8A), Color(0xFFFFD54F), Color(0xFF4FC3F7),
    Color(0xFF81C784), Color(0xFFBA68C8), Color(0xFFFF8A65),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final rnd = math.Random(seed);
    final c = Offset(size.width / 2, size.height / 2);
    const n = 22;
    for (var i = 0; i < n; i++) {
      final ang = (i / n) * math.pi * 2 + rnd.nextDouble() * 0.4;
      final speed = 70 + rnd.nextDouble() * 90;
      final up = 30 + rnd.nextDouble() * 50; // floats upwards
      final pos = Offset(
        c.dx + math.cos(ang) * speed * t,
        c.dy + math.sin(ang) * speed * t - up * t * t,
      );
      final s = 6 + rnd.nextDouble() * 6;
      final col = _colors[i % _colors.length];
      final paint = Paint()
        ..color = col.withAlpha(((1 - t) * 255).round())
        ..style = PaintingStyle.fill;
      switch (i % 3) {
        case 0:
          canvas.drawPath(heartPath(pos, s * 0.9), paint);
          break;
        case 1:
          canvas.drawPath(starPath(pos, s * 1.3, rot: t * 4), paint);
          break;
        default:
          canvas.drawCircle(pos, s * 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(BurstPainter old) => old.t != t;
}

/// Baby peacock spreading its tail feathers behind the animal.
class FanPainter extends CustomPainter {
  FanPainter(this.t);
  final double t; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final c = Offset(size.width / 2, size.height * 0.56);
    final r = size.width * 0.40 * t;
    const count = 11;
    for (var i = 0; i < count; i++) {
      final a = math.pi * (190 / 180) + math.pi * (160 / 180) * i / (count - 1);
      final fc = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      canvas.save();
      canvas.translate(fc.dx, fc.dy);
      canvas.rotate(a + math.pi / 2);
      final w = r * 0.36;
      final h = r * 0.52;
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w, height: h),
          Paint()..color = const Color(0xFF1FAA78));
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.62, height: h * 0.62),
          Paint()..color = const Color(0xFF2E6FE0));
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.28, height: h * 0.28),
          Paint()..color = const Color(0xFFFFD54F));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(FanPainter old) => old.t != t;
}

/// Small fire breath going up from the baby dragon's mouth.
class FirePainter extends CustomPainter {
  FirePainter(this.t);
  final double t; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final base = Offset(size.width / 2, size.height * 0.5);
    final fade = t < 0.8 ? 1.0 : (1 - t) / 0.2;
    final len = size.height * 0.42 * math.sin(t * math.pi * 0.5 + 0.1);
    for (var i = 0; i < 5; i++) {
      final ang = -math.pi / 2 + (i - 2) * 0.3;
      final l = len * (0.75 + 0.25 * math.sin(t * 25 + i * 1.7));
      final dir = Offset(math.cos(ang), math.sin(ang));
      final perp = Offset(-dir.dy, dir.dx);
      final tip = base + dir * l;
      final wd = size.width * 0.07;
      for (var layer = 0; layer < 2; layer++) {
        final k = layer == 0 ? 1.0 : 0.55;
        final path = Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(
              (base + perp * wd * k + dir * l * 0.5).dx, (base + perp * wd * k + dir * l * 0.5).dy,
              (base + dir * l * k).dx, (base + dir * l * k).dy)
          ..quadraticBezierTo(
              (base - perp * wd * k + dir * l * 0.5).dx, (base - perp * wd * k + dir * l * 0.5).dy,
              base.dx, base.dy)
          ..close();
        final col = layer == 0 ? const Color(0xFFFF6D00) : const Color(0xFFFFE082);
        canvas.drawPath(path, Paint()..color = col.withAlpha((fade * 230).round()));
      }
      canvas.drawCircle(tip, 2.5, Paint()..color = const Color(0xFFFFAB40).withAlpha((fade * 255).round()));
    }
  }

  @override
  bool shouldRepaint(FirePainter old) => old.t != t;
}

/// Lottie sparkle (assets/lottie/sparkle.json). Draws nothing if the file is
/// missing, so replacing/removing it is always safe.
class SparkleBurst extends StatelessWidget {
  const SparkleBurst({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Lottie.asset(
          'assets/lottie/sparkle.json',
          repeat: false,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
