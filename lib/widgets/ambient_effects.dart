import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/level_model.dart';

/// Light animated decoration over the background (snow, embers, fireflies,
/// drifting leaves). Purely visual.
class AmbientLayer extends StatefulWidget {
  const AmbientLayer({super.key, required this.kind});
  final AmbientKind kind;

  @override
  State<AmbientLayer> createState() => _AmbientLayerState();
}

class _AmbientLayerState extends State<AmbientLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctl,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _AmbientPainter(widget.kind, _ctl.value),
          ),
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.kind, this.t);
  final AmbientKind kind;
  final double t; // 0..1 loops every 24 s

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    const n = 28;
    for (var i = 0; i < n; i++) {
      final x0 = rnd.nextDouble();
      final y0 = rnd.nextDouble();
      final spd = 1 + rnd.nextInt(3); // whole loops per cycle -> seamless
      final r = 2 + rnd.nextDouble() * 4;
      final ph = rnd.nextDouble() * math.pi * 2;
      final cyc = (t * spd + y0) % 1.0;
      switch (kind) {
        case AmbientKind.ice: // snow falls
          {
          final x = size.width * x0 + math.sin(t * math.pi * 2 * 2 + ph) * 14;
          canvas.drawCircle(Offset(x, size.height * cyc), r,
              Paint()..color = Colors.white.withAlpha(220));
          }
          break;
        case AmbientKind.volcano: // embers rise
          {
          final x = size.width * x0 + math.sin(t * math.pi * 2 * 3 + ph) * 12;
          final y = size.height * (1 - cyc);
          canvas.drawCircle(Offset(x, y), r * 0.8,
              Paint()..color = const Color(0xFFFFA040).withAlpha((200 * (1 - (1 - cyc) * 0.6)).round()));
          }
          break;
        case AmbientKind.forest: // fireflies + leaves
          if (i.isEven) {
            final x = size.width * x0 + math.sin(t * math.pi * 2 * 2 + ph) * 20;
            final y = size.height * y0 * 0.8 + math.cos(t * math.pi * 2 * 3 + ph) * 16;
            final glow = 0.5 + 0.5 * math.sin(t * math.pi * 2 * 6 + ph);
            canvas.drawCircle(Offset(x, y), r * 1.6,
                Paint()..color = const Color(0xFFFFF59D).withAlpha((40 + 140 * glow).round()));
            canvas.drawCircle(Offset(x, y), r * 0.6,
                Paint()..color = Colors.white.withAlpha((120 + 120 * glow).round()));
          } else {
            final x = size.width * x0 + math.sin(t * math.pi * 2 * 2 + ph) * 24;
            canvas.save();
            canvas.translate(x, size.height * cyc);
            canvas.rotate(t * math.pi * 4 + ph);
            canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 3, height: r * 1.5),
                Paint()..color = const Color(0xFF9CCC65).withAlpha(200));
            canvas.restore();
          }
          break;
        case AmbientKind.farm: // petals + little birds
          if (i < 6) {
            final x = size.width * ((t * spd + x0) % 1.0);
            final y = size.height * 0.05 + size.height * 0.2 * y0 + math.sin(t * math.pi * 2 * 4 + ph) * 6;
            final wing = math.sin(t * math.pi * 2 * 40 + ph) * 4;
            final p = Path()
              ..moveTo(x - 8, y - wing)
              ..quadraticBezierTo(x - 3, y - 4, x, y)
              ..quadraticBezierTo(x + 3, y - 4, x + 8, y - wing);
            canvas.drawPath(
                p,
                Paint()
                  ..color = const Color(0xFF455A64)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..strokeCap = StrokeCap.round);
          } else if (i.isEven) {
            final x = size.width * x0 + math.sin(t * math.pi * 2 * 2 + ph) * 22;
            canvas.drawCircle(Offset(x, size.height * cyc), r * 0.8,
                Paint()..color = const Color(0xFFFFF176).withAlpha(200));
          }
          break;
      }
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.t != t || old.kind != kind;
}
