import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/level_model.dart';
import '../utils/progress_store.dart';
import '../utils/sound_manager.dart';
import '../widgets/ambient_effects.dart';
import '../widgets/animal_widget.dart';
import '../widgets/egg_widget.dart';
import '../widgets/game_overlays.dart';
import '../widgets/hatch_animation.dart';
import '../widgets/nest_widget.dart';
import '../widgets/ui_bits.dart';

class _EggInfo {
  _EggInfo(this.id, this.type);
  final int id;
  final EggType type;
  bool placed = false;
}

class _NestInfo {
  _NestInfo(this.type);
  final EggType type;
  int count = 0;
  bool hatching = false;
  bool hatched = false;
  int popToken = 0;
}

class _Bounce {
  _Bounce(this.eggId, this.type, this.from, this.to);
  final int eggId;
  final EggType type;
  final Offset from;
  final Offset to;
  final Key key = UniqueKey();
}

class _Floaty {
  _Floaty(this.text, this.pos, this.color);
  final String text;
  final Offset pos;
  final Color color;
  final Key key = UniqueKey();
}

class _HatchInfo {
  _HatchInfo(this.nest);
  final int nest;
  final Key key = UniqueKey();
}

/// Sizes and positions of everything on the board.
class _Layout {
  _Layout(this.size, EdgeInsets pad) {
    top = pad.top + 8;
    final usable = size.height - pad.top - pad.bottom - hud - 16;
    final r0 = top + hud + 8;
    nestW = math.min(size.width / 3 - 14, 128.0);
    nestY = r0 + usable * 0.16;
    homeY = r0 + usable * 0.44;
    eggTop = r0 + usable * 0.58;
    eggBottom = size.height - pad.bottom - 8;
    eggW = math.min(size.width / 6.2, 58.0);
    eggH = eggW * kEggAspect;
    animalSize = math.min(size.width / 3.6, 96.0);
  }

  final Size size;
  final double hud = 56;
  late final double top;
  late final double nestW;
  late final double nestY;
  late final double homeY;
  late final double eggTop;
  late final double eggBottom;
  late final double eggW;
  late final double eggH;
  late final double animalSize;

  double get nestH => nestW * kNestAspect;
  double get slotH => nestH * 1.9;

  Offset nestCenter(int i) => Offset(size.width * (i + 0.5) / 3, nestY);
  Offset homeCenter(int i) => Offset(size.width * (i + 0.5) / 3, homeY);

  /// Top-left corner of egg slot [slot] (3 x 3 grid) with a small random shift.
  Offset eggTopLeft(int slot, Offset jitter) {
    final col = slot % 3;
    final row = slot ~/ 3;
    final cellW = (size.width - 20) / 3;
    final cellH = (eggBottom - eggTop) / 3;
    final cx = 10 + cellW * (col + 0.5);
    final cy = eggTop + cellH * (row + 0.5);
    final jx = math.max(0.0, (cellW - eggW) / 2 - 2);
    final jy = math.max(0.0, (cellH - eggH) / 2 - 2);
    return Offset(cx - eggW / 2 + jitter.dx * jx, cy - eggH / 2 + jitter.dy * jy);
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.levelIndex});
  final int levelIndex;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final LevelModel level = kLevels[widget.levelIndex];
  final GlobalKey _stackKey = GlobalKey();
  final math.Random _rnd = math.Random();

  late final List<_EggInfo> _eggs;
  late final List<_NestInfo> _nests;
  late final List<Offset> _jitter;
  final Map<int, int> _shake = {};
  final List<_Bounce> _bounces = [];
  final List<_Floaty> _floaties = [];
  final List<_HatchInfo> _hatches = [];
  final List<int> _seated = [];

  late int _remaining = level.timeSeconds;
  int _score = 0;
  int _stars = 0;
  int _bonus = 0;
  bool _paused = false;
  bool _won = false;
  bool _lost = false;
  bool _showIntro = true;
  Timer? _timer;

  late final AnimationController _shakeCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  final ConfettiController _hatchConfetti =
      ConfettiController(duration: const Duration(milliseconds: 1500));
  final ConfettiController _winConfetti =
      ConfettiController(duration: const Duration(seconds: 4));
  Offset _confettiPos = Offset.zero;
  _Layout? _lay;

  bool get _ended => _won || _lost;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final types = <EggType>[];
    for (final t in level.eggs) {
      for (var k = 0; k < level.eggsPerNest; k++) {
        types.add(t);
      }
    }
    types.shuffle(_rnd);
    _eggs = [for (var i = 0; i < types.length; i++) _EggInfo(i, types[i])];
    final nestTypes = List<EggType>.from(level.eggs)..shuffle(_rnd);
    _nests = [for (final t in nestTypes) _NestInfo(t)];
    _jitter = [
      for (var i = 0; i < _eggs.length; i++)
        Offset(_rnd.nextDouble() * 2 - 1, _rnd.nextDouble() * 2 - 1)
    ];
    _timer = Timer.periodic(const Duration(seconds: 1), _onSecond);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SoundManager.instance.playMusic(level.bgm);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _shakeCtl.dispose();
    _hatchConfetti.dispose();
    _winConfetti.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  // ---- timer / state --------------------------------------------------
  void _onSecond(Timer t) {
    if (!mounted || _paused || _ended) return;
    setState(() {
      if (_remaining > 0) _remaining--;
    });
    if (_remaining <= 0) {
      // If everything is already sorted, let the last hatch finish.
      if (_eggs.every((e) => e.placed)) return;
      _gameOver();
    }
  }

  void _pause() {
    if (!mounted || _ended || _paused) return;
    setState(() => _paused = true);
    SoundManager.instance.pauseMusic();
  }

  void _resume() {
    if (!mounted) return;
    setState(() => _paused = false);
    SoundManager.instance.resumeMusic();
  }

  Future<void> _openSettings() async {
    final wasPaused = _paused;
    if (!wasPaused) _pause();
    await showDialog<void>(context: context, builder: (_) => const SettingsDialog());
    if (!wasPaused && mounted && !_ended) _resume();
  }

  void _onBack() {
    if (_ended) {
      _goMenu();
    } else if (_paused) {
      _resume();
    } else {
      _pause();
    }
  }

  void _goMenu() {
    SoundManager.instance.pauseMusic();
    Navigator.of(context).pop();
  }

  void _restart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GameScreen(levelIndex: widget.levelIndex)),
    );
  }

  void _next() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GameScreen(levelIndex: widget.levelIndex + 1)),
    );
  }

  // ---- drag & drop -------------------------------------------------------
  Offset _toLocal(Offset global) {
    final box = _stackKey.currentContext?.findRenderObject();
    if (box is RenderBox) return box.globalToLocal(global);
    return global;
  }

  void _onDrop(int nestIndex, int eggId, Offset globalPointer) {
    if (_ended || _paused) return;
    final ei = _eggs.indexWhere((e) => e.id == eggId);
    if (ei < 0) return;
    final egg = _eggs[ei];
    final nest = _nests[nestIndex];
    if (egg.placed || nest.hatching || nest.hatched) return;
    final lay = _lay;
    if (lay == null) return;

    if (egg.type.id == nest.type.id) {
      _correct(egg, nestIndex);
    } else {
      final local = _toLocal(globalPointer);
      final from = Offset(local.dx - lay.eggW / 2, local.dy - lay.eggH * 0.62);
      final to = lay.eggTopLeft(ei, _jitter[ei]);
      setState(() {
        _shake[egg.id] = (_shake[egg.id] ?? 0) + 1;
        _score = math.max(0, _score - 5);
        _bounces.add(_Bounce(egg.id, egg.type, from, to));
        _floaties.add(_Floaty('Wrong!', Offset(local.dx, local.dy - 50), const Color(0xFFFF5252)));
      });
      SoundManager.instance.play('wrong');
      HapticFeedback.mediumImpact();
    }
  }

  void _correct(_EggInfo egg, int ni) {
    final nest = _nests[ni];
    setState(() {
      egg.placed = true;
      nest.count++;
      nest.popToken++;
      _score += 10;
      if (nest.count >= level.eggsPerNest) {
        nest.hatching = true;
        _hatches.add(_HatchInfo(ni));
      }
    });
    SoundManager.instance.play('pop');
    HapticFeedback.lightImpact();
  }

  void _onHatchPop(int ni) {
    final lay = _lay;
    if (lay != null) _confettiPos = lay.nestCenter(ni);
    _hatchConfetti.play();
    if (level.kind == BabyKind.dragon) _shakeCtl.forward(from: 0);
    HapticFeedback.heavyImpact();
  }

  void _onHatchDone(_HatchInfo h) {
    if (!mounted) return;
    setState(() {
      _hatches.remove(h);
      _nests[h.nest].hatching = false;
      _nests[h.nest].hatched = true;
      _seated.add(h.nest);
      _score += 50;
    });
    if (_nests.every((n) => n.hatched)) _win();
  }

  void _win() {
    _timer?.cancel();
    final left = _remaining;
    _stars = left >= 45 ? 3 : (left >= 20 ? 2 : 1);
    _bonus = left * 2;
    setState(() {
      _score += _bonus;
      _won = true;
    });
    ProgressStore.saveResult(level.number, _stars, kLevels.length);
    SoundManager.instance.pauseMusic();
    SoundManager.instance.play('win');
    _winConfetti.play();
  }

  void _gameOver() {
    _timer?.cancel();
    setState(() => _lost = true);
    SoundManager.instance.pauseMusic();
    SoundManager.instance.play('lose');
  }

  // ---- build ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, box) {
            final lay = _Layout(Size(box.maxWidth, box.maxHeight), MediaQuery.of(context).padding);
            _lay = lay;
            return Stack(
              children: [
                AnimatedBuilder(
                  animation: _shakeCtl,
                  builder: (context, child) {
                    final v = _shakeCtl.value;
                    final dx = math.sin(v * math.pi * 9) * (1 - v) * 8;
                    return Transform.translate(offset: Offset(dx, dx * 0.5), child: child);
                  },
                  child: TickerMode(
                    enabled: !_paused,
                    child: _board(lay),
                  ),
                ),
                if (_paused && !_ended)
                  PauseOverlay(
                    onResume: _resume,
                    onRestart: _restart,
                    onSettings: _openSettings,
                    onMenu: _goMenu,
                  ),
                if (_won)
                  LevelCompleteOverlay(
                    stars: _stars,
                    score: _score,
                    timeLeft: _remaining,
                    isLast: widget.levelIndex >= kLevels.length - 1,
                    onNext: _next,
                    onReplay: _restart,
                    onMenu: _goMenu,
                  ),
                if (_lost)
                  GameOverOverlay(score: _score, onRetry: _restart, onMenu: _goMenu),
                if (_won)
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _winConfetti,
                      blastDirection: math.pi / 2,
                      blastDirectionality: BlastDirectionality.explosive,
                      emissionFrequency: 0.06,
                      numberOfParticles: 14,
                      gravity: 0.2,
                      shouldLoop: false,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _board(_Layout lay) {
    final w = lay.size.width;
    final accent = level.accent;
    final eggChildren = <Widget>[];
    final bouncing = _bounces.map((b) => b.eggId).toSet();
    for (var i = 0; i < _eggs.length; i++) {
      final e = _eggs[i];
      if (e.placed || bouncing.contains(e.id)) continue;
      final p = lay.eggTopLeft(i, _jitter[i]);
      eggChildren.add(Positioned(
        key: ValueKey('egg${e.id}'),
        left: p.dx,
        top: p.dy,
        width: lay.eggW,
        height: lay.eggH,
        child: _draggableEgg(e, lay),
      ));
    }

    return Stack(
      key: _stackKey,
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        // background
        Positioned.fill(
          child: Image.asset(
            level.background,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accent, darker(accent, 0.4)],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: AmbientLayer(kind: level.ambient)),

        // home area
        Positioned(
          left: 10,
          right: 10,
          top: lay.homeY - lay.animalSize * 0.62,
          height: lay.animalSize * 1.24,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: const Color(0xAAFFFFFF), width: 3),
            ),
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(level.homeName, style: fancyText(14, color: Colors.white70)),
          ),
        ),
        for (var i = 0; i < 3 && i < _nests.length; i++)
          Positioned(
            left: lay.homeCenter(i).dx - lay.animalSize * 0.4,
            top: lay.homeY + lay.animalSize * 0.28,
            width: lay.animalSize * 0.8,
            height: lay.animalSize * 0.16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x33000000),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),

        // nests
        for (var i = 0; i < _nests.length; i++)
          Positioned(
            left: lay.nestCenter(i).dx - w / 6,
            top: lay.nestY - lay.slotH / 2,
            width: w / 3,
            height: lay.slotH,
            child: NestWidget(
              type: _nests[i].type,
              width: lay.nestW,
              slotWidth: w / 3,
              slotHeight: lay.slotH,
              eggCount: _nests[i].count,
              eggsNeeded: level.eggsPerNest,
              hatching: _nests[i].hatching,
              hatched: _nests[i].hatched,
              popToken: _nests[i].popToken,
              canAccept: !_ended && !_nests[i].hatching && !_nests[i].hatched,
              onAccept: (id, pos) => _onDrop(i, id, pos),
            ),
          ),

        // babies sitting at home
        for (final ni in _seated)
          Positioned(
            left: lay.homeCenter(ni).dx - lay.animalSize / 2,
            top: lay.homeCenter(ni).dy - lay.animalSize / 2,
            width: lay.animalSize,
            height: lay.animalSize,
            child: AnimalWidget(
              asset: level.animalAsset,
              size: lay.animalSize,
              phase: ni * 0.3,
            ),
          ),

        // eggs on the ground
        ...eggChildren,

        // eggs bouncing back
        for (final b in _bounces)
          TweenAnimationBuilder<double>(
            key: b.key,
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            onEnd: () {
              if (mounted) setState(() => _bounces.remove(b));
            },
            builder: (context, t, _) {
              final move = Curves.easeOutBack.transform(math.min(1.0, t * 1.15));
              final pos = Offset.lerp(b.from, b.to, move)!;
              final wob = math.sin(t * math.pi * 7) * (1 - t) * 0.35;
              return Positioned(
                left: pos.dx,
                top: pos.dy,
                width: lay.eggW,
                height: lay.eggH,
                child: IgnorePointer(
                  child: Transform.rotate(
                    angle: wob,
                    child: EggWidget(type: b.type, size: lay.eggW),
                  ),
                ),
              );
            },
          ),

        // hatch sequences
        for (final h in _hatches)
          HatchAnimation(
            key: h.key,
            level: level,
            eggType: _nests[h.nest].type,
            from: lay.nestCenter(h.nest).translate(0, -lay.nestH * 0.1),
            to: lay.homeCenter(h.nest),
            eggSize: lay.eggW,
            animalSize: lay.animalSize,
            onPop: () => _onHatchPop(h.nest),
            onFinished: () => _onHatchDone(h),
          ),

        // "Wrong!" labels
        for (final f in _floaties)
          TweenAnimationBuilder<double>(
            key: f.key,
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 950),
            onEnd: () {
              if (mounted) setState(() => _floaties.remove(f));
            },
            builder: (context, t, _) {
              return Positioned(
                left: f.pos.dx - 70,
                top: f.pos.dy - 40 * t,
                width: 140,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: (1 - t * t).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.8 + 0.4 * Curves.easeOutBack.transform(math.min(1.0, t * 3)),
                      child: Text(
                        f.text,
                        textAlign: TextAlign.center,
                        style: fancyText(34, color: f.color),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

        // hatch confetti
        Positioned(
          left: _confettiPos.dx,
          top: _confettiPos.dy,
          child: ConfettiWidget(
            confettiController: _hatchConfetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 26,
            maxBlastForce: 22,
            minBlastForce: 8,
            gravity: 0.25,
            colors: const [
              Color(0xFFFF5C8A), Color(0xFFFFD54F), Color(0xFF4FC3F7),
              Color(0xFF81C784), Color(0xFFBA68C8), Color(0xFFFF8A65),
            ],
          ),
        ),

        // top bar
        Positioned(
          left: 10,
          right: 10,
          top: lay.top,
          height: lay.hud,
          child: _hud(),
        ),

        // level intro banner
        if (_showIntro)
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 2400),
                onEnd: () {
                  if (mounted) setState(() => _showIntro = false);
                },
                builder: (context, t, _) {
                  final op = t < 0.15 ? t / 0.15 : (t > 0.75 ? (1 - t) / 0.25 : 1.0);
                  return Opacity(
                    opacity: op.clamp(0.0, 1.0),
                    child: Align(
                      alignment: const Alignment(0, 0.05),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: alpha(accent, 0.92),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Level ${level.number}', style: fancyText(34)),
                            Text(level.title, style: fancyText(22)),
                            Text('Hatch the baby ${level.babyName}!', style: fancyText(16, color: Colors.white70)),
                          ],
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

  Widget _hud() {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    final low = _remaining <= 10;
    return Row(
      children: [
        RoundIconButton(icon: Icons.pause_rounded, color: const Color(0xFFFF7043), onTap: _pause),
        const SizedBox(width: 8),
        Expanded(child: HudChip(icon: Icons.flag_rounded, text: 'Lv ${level.number}', color: const Color(0xFFFFE082))),
        const SizedBox(width: 6),
        Expanded(child: HudChip(icon: Icons.star_rounded, text: '$_score', color: const Color(0xFFFFD54F))),
        const SizedBox(width: 6),
        Expanded(
          child: HudChip(
            icon: Icons.timer_rounded,
            text: '$m:${s.toString().padLeft(2, '0')}',
            color: low ? Colors.white : const Color(0xFF80DEEA),
            background: low ? const Color(0xCCD32F2F) : const Color(0x66000000),
          ),
        ),
        const SizedBox(width: 8),
        RoundIconButton(icon: Icons.settings_rounded, color: const Color(0xFF8E24AA), onTap: _openSettings),
      ],
    );
  }

  Widget _draggableEgg(_EggInfo e, _Layout lay) {
    final fw = lay.eggW * 1.3;
    final fh = fw * kEggAspect;
    return Draggable<int>(
      data: e.id,
      maxSimultaneousDrags: 1,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => SoundManager.instance.play('click', volume: 0.5),
      feedback: Transform.translate(
        // the egg floats just above the finger so it stays visible
        offset: Offset(-fw / 2, -fh * 0.62),
        child: EggWidget(type: e.type, size: fw),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: EggWidget(type: e.type, size: lay.eggW),
      ),
      child: EggWidget(
        type: e.type,
        size: lay.eggW,
        shakeToken: _shake[e.id] ?? 0,
      ),
    );
  }
}
