import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/level_model.dart';
import '../utils/sound_manager.dart';
import 'animal_widget.dart';
import 'effects.dart';
import 'egg_widget.dart';

/// The whole hatch sequence, drawn over the game board:
///   appear -> egg shakes 3 times -> cracks grow -> cracks open (pop)
///   -> baby jumps out with hearts/stars -> special move -> walks home.
///
/// [from] / [to] are centre points in the coordinates of the Stack that
/// contains this widget. [onPop] fires at the moment the egg opens (confetti,
/// screen shake). [onFinished] fires when the baby has arrived home.
class HatchAnimation extends StatefulWidget {
  const HatchAnimation({
    super.key,
    required this.level,
    required this.eggType,
    required this.from,
    required this.to,
    required this.eggSize,
    required this.animalSize,
    required this.endSize,
    required this.onPop,
    required this.onFinished,
  });

  final LevelModel level;
  final EggType eggType;
  final Offset from;
  final Offset to;
  final double eggSize;
  final double animalSize;
  final double endSize; // size of the baby when it sits at home
  final VoidCallback onPop;
  final VoidCallback onFinished;

  @override
  State<HatchAnimation> createState() => _HatchAnimationState();
}

class _HatchAnimationState extends State<HatchAnimation> with SingleTickerProviderStateMixin {
  // timeline in milliseconds
  static const double _tAppear = 350;
  static const double _tShakeEnd = 1650; // 3 shakes
  static const double _tCrackEnd = 2350; // egg opens
  static const double _tCelebEnd = 3750;
  static const double _total = 4950; // baby arrives home

  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4950),
  );
  bool _cracked = false;
  bool _popped = false;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _ctl.addListener(_tick);
    _ctl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onFinished();
    });
    _ctl.forward();
  }

  void _tick() {
    final ms = _ctl.value * _total;
    if (!_cracked && ms >= _tShakeEnd) {
      _cracked = true;
      SoundManager.instance.play('crack');
    }
    if (!_popped && ms >= _tCrackEnd) {
      _popped = true;
      SoundManager.instance.play(widget.level.hatchSfx);
      widget.onPop();
    }
    if (!_fired && widget.level.kind == BabyKind.dragon && ms >= _tCrackEnd + 800) {
      _fired = true;
      SoundManager.instance.play('fire');
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Widget _at(Offset c, double w, double h, Widget child) => Positioned(
        left: c.dx - w / 2,
        top: c.dy - h / 2,
        width: w,
        height: h,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (context, _) {
          final ms = _ctl.value * _total;
          return SizedBox.expand(
            child: Stack(clipBehavior: Clip.none, children: _layers(ms)),
          );
        },
      ),
    );
  }

  List<Widget> _layers(double ms) {
    final kind = widget.level.kind;
    final from = widget.from;
    final bigW = widget.eggSize * 1.7;
    final bigH = bigW * kEggAspect;
    final out = <Widget>[];

    if (ms < _tCrackEnd) {
      double scale = 1, angle = 0, crack = 0;
      if (ms < _tAppear) {
        scale = 0.35 + 0.65 * Curves.easeOutBack.transform(ms / _tAppear);
      } else if (ms < _tShakeEnd) {
        final u = (ms - _tAppear) / (_tShakeEnd - _tAppear);
        angle = math.sin(u * math.pi * 2 * 3) * 0.26; // exactly 3 shakes
        scale = 1 + 0.06 * math.sin(u * math.pi * 6).abs();
      } else {
        final u = (ms - _tShakeEnd) / (_tCrackEnd - _tShakeEnd);
        crack = u;
        angle = math.sin(u * math.pi * 10) * 0.07 * (0.5 + u);
        scale = 1 + 0.12 * u;
      }
      out.add(_at(
        from, bigW, bigH,
        Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            child: EggWidget(type: widget.eggType, size: bigW, crack: crack),
          ),
        ),
      ));
      return out;
    }

    // ---- after the egg opened ------------------------------------------
    final since = ms - _tCrackEnd;
    final shellT = (since / 800).clamp(0.0, 1.0);
    if (shellT < 1) {
      final e = Curves.easeOut.transform(shellT);
      for (final top in [true, false]) {
        final dir = top ? -1.0 : 1.0;
        out.add(_at(
          from.translate(dir * bigW * 0.1 * e, dir * bigH * 0.1 * e), bigW, bigH,
          Transform.translate(
            offset: Offset(dir * bigW * 0.55 * e, dir * bigH * (top ? 0.45 : -0.1) * e + (top ? 0 : bigH * 0.5 * e * e)),
            child: Transform.rotate(
              angle: dir * 0.8 * e,
              child: Opacity(
                opacity: 1 - shellT,
                child: ClipPath(
                  clipper: EggHalfClipper(top: top),
                  child: EggWidget(type: widget.eggType, size: bigW, crack: 1),
                ),
              ),
            ),
          ),
        ));
      }
    }

    // hearts / stars / dots
    out.add(Positioned(
      left: from.dx - 160,
      top: from.dy - 160,
      width: 320,
      height: 320,
      child: CustomPaint(
        painter: BurstPainter(t: (since / 1500).clamp(0.0, 1.0), seed: widget.level.number * 7),
      ),
    ));

    // baby animal
    final aw = widget.animalSize;
    var pos = from;
    var size = aw * 1.25;
    var angle = 0.0;
    var dy = 0.0;
    var flip = false;
    var sx = 1.0, sy = 1.0;
    final popScale = Curves.elasticOut.transform((since / 700).clamp(0.0, 1.0));
    double fanT = 0;
    double fireT = 0;

    if (ms >= _tCelebEnd) {
      final u = ((ms - _tCelebEnd) / (_total - _tCelebEnd)).clamp(0.0, 1.0);
      final e = Curves.easeInOut.transform(u);
      pos = Offset.lerp(from, widget.to, e)!;
      size = aw * 1.25 + (widget.endSize - aw * 1.25) * e;
      flip = widget.to.dx < from.dx;
      switch (kind) {
        case BabyKind.penguin: // slides on the ice, no hopping
          angle = (flip ? 1 : -1) * 0.22;
          sx = 1.1;
          sy = 0.92;
          break;
        case BabyKind.dragon: // heavy little stomps
        case BabyKind.dino:
          dy = -math.sin(u * math.pi * 6).abs() * 8;
          angle = math.sin(u * math.pi * 12) * 0.07;
          break;
        case BabyKind.bunny: // big bunny hops
          dy = -math.sin(u * math.pi * 5).abs() * 26;
          break;
        default: // happy hops
          dy = -math.sin(u * math.pi * 5).abs() * 14;
      }
      if (kind == BabyKind.peacock) fanT = (1 - u * 3).clamp(0.0, 1.0);
    } else if (since > 700) {
      final u = (since - 700) / (_tCelebEnd - _tCrackEnd - 700);
      dy = -math.sin(u * math.pi * 3).abs() * 18;
      if (kind == BabyKind.penguin) angle = math.sin(u * math.pi * 6) * 0.12;
      if (kind == BabyKind.unicorn) angle = math.sin(u * math.pi * 6) * 0.22;
      if (kind == BabyKind.peacock) fanT = Curves.easeOutBack.transform(((since - 400) / 600).clamp(0.0, 1.0));
      if (kind == BabyKind.dragon) fireT = ((since - 800) / 700).clamp(0.0, 1.0);
    } else if (kind == BabyKind.peacock) {
      fanT = Curves.easeOut.transform(((since - 400) / 600).clamp(0.0, 1.0));
    }

    final center = pos.translate(0, dy);
    if (fanT > 0) {
      final fs = size * 2.4;
      out.add(_at(center.translate(0, -size * 0.12), fs, fs,
          CustomPaint(painter: FanPainter(fanT))));
    }
    out.add(_at(
      center, size, size,
      Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values((flip ? -1.0 : 1.0) * sx * popScale, sy * popScale, 1),
        child: Transform.rotate(
          angle: angle,
          child: AnimalWidget(asset: widget.level.animalAsset, size: size, idle: false),
        ),
      ),
    ));
    if (fireT > 0 && fireT < 1) {
      final fs = size * 1.8;
      out.add(_at(center.translate(0, -size * 0.35), fs, fs,
          CustomPaint(painter: FirePainter(fireT))));
    }
    return out;
  }
}
