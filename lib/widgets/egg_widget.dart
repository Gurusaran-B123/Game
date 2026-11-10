import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/level_model.dart';
import 'effects.dart';

/// Height / width of the egg pictures (assets/images/egg_*.png are 220 x 270).
const double kEggAspect = 270 / 220;

/// An egg picture that can shake. Change [shakeToken] to start a shake.
///
/// The picture comes from [EggType.asset]. If the file is missing, a simple
/// painted egg in the same colour is shown instead.
class EggWidget extends StatefulWidget {
  const EggWidget({
    super.key,
    required this.type,
    this.size = 56,
    this.shakeToken = 0,
    this.shakeTimes = 2,
    this.crack = 0,
  });

  final EggType type;
  final double size; // width in logical pixels
  final int shakeToken;
  final int shakeTimes;
  final double crack; // 0..1 crack lines

  @override
  State<EggWidget> createState() => _EggWidgetState();
}

class _EggWidgetState extends State<EggWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _ctl.duration = Duration(milliseconds: 230 * widget.shakeTimes);
  }

  @override
  void didUpdateWidget(EggWidget old) {
    super.didUpdateWidget(old);
    if (widget.shakeToken != old.shakeToken) {
      _ctl.duration = Duration(milliseconds: 230 * widget.shakeTimes);
      _ctl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.size;
    final h = w * kEggAspect;
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, child) {
        final t = _ctl.value;
        final wave = math.sin(t * math.pi * 2 * widget.shakeTimes) * (1 - t * 0.4);
        return Transform.translate(
          offset: Offset(wave * w * 0.07, 0),
          child: Transform.rotate(angle: wave * 0.22, child: child),
        );
      },
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              widget.type.asset,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (context, error, stack) =>
                  CustomPaint(painter: _FallbackEggPainter(widget.type.color)),
            ),
            if (widget.crack > 0)
              CustomPaint(painter: CrackPainter(widget.crack)),
          ],
        ),
      ),
    );
  }
}

class _FallbackEggPainter extends CustomPainter {
  _FallbackEggPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const n = 80;
    for (var i = 0; i <= n; i++) {
      final t = 2 * math.pi * i / n;
      final x = size.width / 2 + size.width * 0.46 * math.sin(t) * (1 - 0.16 * math.cos(t));
      final y = size.height / 2 - size.height * 0.46 * math.cos(t);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.lerp(color, Colors.black, 0.35)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.04,
    );
  }

  @override
  bool shouldRepaint(_FallbackEggPainter old) => old.color != color;
}
