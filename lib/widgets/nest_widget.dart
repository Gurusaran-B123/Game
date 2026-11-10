import 'package:flutter/material.dart';

import '../models/level_model.dart';
import 'effects.dart';
import 'egg_widget.dart';
import 'ui_bits.dart';

/// Height / width of assets/images/nest.png (300 x 190).
const double kNestAspect = 190 / 300;

/// A coloured nest that accepts dragged eggs (DragTarget<int>, the data is the egg id).
class NestWidget extends StatelessWidget {
  const NestWidget({
    super.key,
    required this.type,
    required this.width,
    required this.slotWidth,
    required this.slotHeight,
    required this.eggCount,
    required this.eggsNeeded,
    required this.hatching,
    required this.hatched,
    required this.popToken,
    required this.canAccept,
    required this.onAccept,
  });

  final EggType type;
  final double width; // nest picture width
  final double slotWidth; // size of the whole drop area
  final double slotHeight;
  final int eggCount;
  final int eggsNeeded;
  final bool hatching;
  final bool hatched;
  final int popToken;
  final bool canAccept;
  final void Function(int eggId, Offset globalPointer) onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => canAccept,
      onAcceptWithDetails: (d) => onAccept(d.data, d.offset),
      builder: (context, candidate, rejected) {
        final hot = candidate.isNotEmpty;
        return SizedBox(
          width: slotWidth,
          height: slotHeight,
          child: Center(
            child: AnimatedScale(
              scale: hot ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: _body(hot),
            ),
          ),
        );
      },
    );
  }

  Widget _body(bool hot) {
    final h = width * kNestAspect;
    final eggW = width * 0.30;
    final showEggs = !hatching && !hatched;
    final nestImage = Image.asset(
      'assets/images/nest.png',
      width: width,
      height: h,
      fit: BoxFit.fill,
      errorBuilder: (c, e, s) => Container(
        width: width,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFF96642F),
          borderRadius: BorderRadius.circular(h),
        ),
      ),
    );

    return SizedBox(
      width: width,
      height: h * 1.35,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // glow when an egg is over the nest
          if (hot)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(h),
                  boxShadow: [
                    BoxShadow(color: alpha(type.color, 0.9), blurRadius: 26, spreadRadius: 4),
                  ],
                ),
              ),
            ),
          // back of the nest + coloured ring
          Positioned(left: 0, bottom: 0, child: nestImage),
          Positioned(
            left: 0,
            bottom: 0,
            width: width,
            height: h,
            child: CustomPaint(painter: _RingPainter(type.color, front: false)),
          ),
          // ghost egg shows which colour belongs here
          if (showEggs && eggCount < eggsNeeded)
            Positioned(
              bottom: h * 0.30,
              child: Opacity(
                opacity: 0.35,
                child: EggWidget(type: type, size: eggW),
              ),
            ),
          // eggs that are already inside
          if (showEggs)
            for (var k = 0; k < eggCount; k++)
              Positioned(
                left: width * 0.5 - eggW / 2 + (k - 1) * width * 0.25,
                bottom: h * (k == 1 ? 0.40 : 0.32),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('p$k'),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.elasticOut,
                  builder: (context, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: EggWidget(type: type, size: eggW),
                ),
              ),
          // front rim hides the bottom of the eggs
          Positioned(
            left: 0,
            bottom: 0,
            width: width,
            child: ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 0.36,
                child: SizedBox(
                  width: width,
                  height: h,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      nestImage,
                      CustomPaint(painter: _RingPainter(type.color, front: true)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // sparkles when an egg lands
          if (popToken > 0)
            Positioned(
              bottom: h * 0.1,
              child: SparkleBurst(key: ValueKey('s$popToken'), size: width * 0.95),
            ),
          // count dots
          if (!hatched)
            Positioned(
              top: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < eggsNeeded; i++)
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i < eggCount || hatching ? type.color : Colors.white54,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                ],
              ),
            ),
          if (hatched)
            Positioned(
              top: 0,
              right: width * 0.05,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

/// Coloured ring around the nest rim. front=true draws only the lower half.
class _RingPainter extends CustomPainter {
  _RingPainter(this.color, {required this.front});
  final Color color;
  final bool front;

  @override
  void paint(Canvas canvas, Size size) {
    // rim ellipse of nest.png: (22,28)-(278,150) of 300x190
    final rect = Rect.fromLTRB(
      size.width * 0.073, size.height * 0.147, size.width * 0.927, size.height * 0.789);
    final stroke = size.width * 0.06;
    final outline = Paint()
      ..color = const Color(0xFF5A3A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 4;
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (front) {
      canvas.drawArc(rect, 0, 3.14159, false, outline);
      canvas.drawArc(rect, 0, 3.14159, false, ring);
    } else {
      canvas.drawOval(rect, outline);
      canvas.drawOval(rect, ring);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color || old.front != front;
}
