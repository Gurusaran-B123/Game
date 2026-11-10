import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Baby animal picture with an optional gentle "breathing" idle animation.
/// Replace the picture by overwriting the file in assets/images/.
class AnimalWidget extends StatefulWidget {
  const AnimalWidget({
    super.key,
    required this.asset,
    required this.size,
    this.idle = true,
    this.phase = 0,
  });

  final String asset;
  final double size;
  final bool idle;
  final double phase;

  @override
  State<AnimalWidget> createState() => _AnimalWidgetState();
}

class _AnimalWidgetState extends State<AnimalWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.idle) _ctl.repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final picture = SizedBox(
      width: s,
      height: s,
      child: Image.asset(
        widget.asset,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) => Container(
          decoration: const BoxDecoration(color: Color(0xFFFFD54F), shape: BoxShape.circle),
          child: Icon(Icons.pets, size: s * 0.6, color: Colors.white),
        ),
      ),
    );
    if (!widget.idle) return picture;
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, child) {
        final v = math.sin((_ctl.value + widget.phase) * math.pi * 2);
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.diagonal3Values(1 - v * 0.025, 1 + v * 0.04, 1),
          child: child,
        );
      },
      child: picture,
    );
  }
}
