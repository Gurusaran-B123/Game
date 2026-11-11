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
import '../widgets/effects.dart';
import '../widgets/egg_widget.dart';
import '../widgets/game_overlays.dart';
import '../widgets/hatch_animation.dart';
import '../widgets/nest_widget.dart';
import '../widgets/ui_bits.dart';

class _EggInfo {
  _EggInfo(this.id, this.type, this.slot);
  final int id;
  final EggType type;
  final int slot; // place in the egg grid
  bool placed = false;
  bool broken = false;
  bool get gone => placed || broken;
}

class _NestInfo {
  _NestInfo(this.type, this.needed, {this.boss = false, this.locked = false});
  final EggType type;
  final int needed;
  final bool boss;
  bool locked;
  int count = 0;
  bool hatching = false;
  bool hatched = false;
  int popToken = 0;
  double frozenDx = 0; // sliding nests stop where they are when hatching
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

class _Splat {
  _Splat(this.type, this.pos);
  final EggType type;
  final Offset pos;
  final Key key = UniqueKey();
}

class _HatchInfo {
  _HatchInfo(this.nest, this.slot);
  final int nest;
  final int slot; // seat in the home area
  final Key key = UniqueKey();
}

/// Sizes and positions of everything on the board. Built from the WHOLE level
/// (largest round) so nothing jumps around between rounds.
class _Layout {
  _Layout(this.size, EdgeInsets pad, LevelModel level) {
    top = pad.top + 8;
    y0 = top + hud + 2 + info + 8;
    bottomY = size.height - pad.bottom - 8;
    final w = size.width;
    final avail = bottomY - y0;

    nestRows = level.maxNests <= 3 ? 1 : 2;
    final total = level.totalHatches;
    homeRows = total <= 5 ? 1 : 2;
    homeCols = total <= 5 ? total : (total + 1) ~/ 2;
    eggCols = level.maxEggs <= 9 ? 3 : (level.maxEggs <= 16 ? 4 : 5);
    eggRows = (level.maxEggs / eggCols).ceil();

    final nestW0 = math.min(w / 3 - 14, 128.0);
    final home0 = math.min(96.0, (w - 20) / homeCols);
    var nw = nestW0;
    var hs = home0;
    var rowH = nw * kNestAspect * 1.45 + 18;
    for (final sc in const [1.0, 0.92, 0.84, 0.76, 0.68, 0.6]) {
      nw = nestW0 * sc;
      hs = home0 * sc;
      rowH = nw * kNestAspect * 1.45 + 18;
      final homeH = homeRows * hs + 12;
      final eggRegion = avail - nestRows * rowH - homeH - 16;
      if (eggRegion >= eggRows * 54.0) break;
    }
    nestW = nw;
    homeSlot = hs;
    nestRowH = rowH;
    animalBig = math.min(w / 3.6, 96.0) * (nw / nestW0);

    homeTop = y0 + nestRows * nestRowH + 8;
    homePadH = homeRows * homeSlot + 12;
    eggTop = homeTop + homePadH + 8;
    cellW = (w - 20) / eggCols;
    cellH = (bottomY - eggTop) / eggRows;
    eggW = math.max(30.0, math.min(58.0, math.min(cellW - 6, (cellH - 4) / kEggAspect)));
    eggH = eggW * kEggAspect;
  }

  final Size size;
  final double hud = 56;
  final double info = 30;
  late final double top;
  late final double y0;
  late final double bottomY;
  late final int nestRows;
  late final int homeRows;
  late final int homeCols;
  late final int eggCols;
  late final int eggRows;
  late final double nestW;
  late final double nestRowH;
  late final double homeSlot;
  late final double animalBig;
  late final double homeTop;
  late final double homePadH;
  late final double eggTop;
  late final double cellW;
  late final double cellH;
  late final double eggW;
  late final double eggH;

  /// (row, nests in that row, index inside the row)
  (int, int, int) rc(int i, int count) {
    if (count <= 3) return (0, count, i);
    final first = (count + 1) ~/ 2;
    if (i < first) return (0, first, i);
    return (1, count ~/ 2, i - first);
  }

  Offset nestCenter(int i, int count) {
    final (row, per, idx) = rc(i, count);
    final rows = count <= 3 ? 1 : 2;
    final regionH = nestRows * nestRowH;
    final yStart = y0 + (regionH - rows * nestRowH) / 2;
    return Offset(size.width * (idx + 0.5) / per, yStart + (row + 0.5) * nestRowH);
  }

  Offset homeCenter(int slot) {
    final row = slot ~/ homeCols;
    final col = slot % homeCols;
    final cw = (size.width - 20) / homeCols;
    return Offset(10 + cw * (col + 0.5), homeTop + 6 + (row + 0.5) * homeSlot);
  }

  /// Top-left corner of egg slot [slot] with a small random shift.
  Offset eggTopLeft(int slot, Offset jitter) {
    final col = slot % eggCols;
    final row = slot ~/ eggCols;
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

  // ---- current round ----
  int _round = 0;
  List<_EggInfo> _eggs = [];
  List<_NestInfo> _nests = [];
  List<Offset> _jitter = [];
  List<double> _phase = [];
  final Map<int, int> _shake = {};
  final List<_Bounce> _bounces = [];
  final List<_Floaty> _floaties = [];
  final List<_Splat> _splats = [];
  final List<_HatchInfo> _hatches = [];
  final List<int> _seated = [];

  // ---- whole level ----
  late int _remaining = level.timeSeconds;
  int _score = 0;
  int _stars = 0;
  int _slotCounter = 0;
  int _hatchedTotal = 0;
  int _moves = 0;
  int _broken = 0;
  int _streak = 0;
  int _hintsLeft = 3;
  int _hintEgg = -1;
  int _hintNest = -1;
  int _hintLeft = 0;
  int _memoryLeft = 0;
  bool _memoryHidden = false;
  bool _paused = false;
  bool _won = false;
  bool _lost = false;
  String _failReason = "Time's up!";
  Timer? _timer;

  // banner
  bool _bannerOn = false;
  String _bannerTitle = '';
  String _bannerSub = '';
  String _bannerRule = '';
  Key _bannerKey = UniqueKey();

  late final AnimationController _shakeCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final AnimationController _roamCtl =
      AnimationController(vsync: this, duration: const Duration(seconds: 9));
  final ConfettiController _hatchConfetti =
      ConfettiController(duration: const Duration(milliseconds: 1500));
  final ConfettiController _winConfetti =
      ConfettiController(duration: const Duration(seconds: 4));
  Offset _confettiPos = Offset.zero;
  _Layout? _lay;

  bool get _ended => _won || _lost;
  bool get _roams => level.movingNests || level.rollingEggs;
  int? get _moveLimit => level.moveLimit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _buildRound();
    _showBanner('Level ${level.number}', level.title, level.rule);
    _timer = Timer.periodic(const Duration(seconds: 1), _onSecond);
    if (_roams) _roamCtl.repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SoundManager.instance.playMusic(level.bgm);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _shakeCtl.dispose();
    _roamCtl.dispose();
    _hatchConfetti.dispose();
    _winConfetti.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  void _showBanner(String title, String sub, String rule) {
    _bannerTitle = title;
    _bannerSub = sub;
    _bannerRule = rule;
    _bannerKey = UniqueKey();
    _bannerOn = true;
  }

  // ---- rounds ----------------------------------------------------------------
  void _buildRound() {
    final spec = level.rounds[_round];
    final pool = List<EggType>.from(level.eggs)..shuffle(_rnd);
    final n = spec.nests;
    final nestTypes = pool.take(n).toList();
    _nests = [
      for (var i = 0; i < n; i++)
        _NestInfo(
          nestTypes[i],
          spec.needed,
          boss: spec.boss,
          locked: level.lockedNest && n >= 3 && i == n - 1,
        ),
    ];
    final types = <EggType>[];
    for (final t in nestTypes) {
      for (var k = 0; k < spec.needed; k++) {
        types.add(t);
      }
    }
    for (var k = 0; k < spec.spares; k++) {
      types.add(nestTypes[_rnd.nextInt(n)]);
    }
    if (spec.golden) types.add(kGoldenEgg);
    types.shuffle(_rnd);
    final slots = List<int>.generate(level.maxEggs, (i) => i)..shuffle(_rnd);
    _eggs = [for (var i = 0; i < types.length; i++) _EggInfo(i, types[i], slots[i])];
    _jitter = [
      for (var i = 0; i < _eggs.length; i++)
        Offset(_rnd.nextDouble() * 2 - 1, _rnd.nextDouble() * 2 - 1)
    ];
    _phase = [for (var i = 0; i < _eggs.length; i++) _rnd.nextDouble() * math.pi * 2];
    _shake.clear();
    _bounces.clear();
    _hintEgg = -1;
    _hintNest = -1;
    _hintLeft = 0;
    _memoryHidden = false;
    _memoryLeft = level.memory ? 3 : 0;
  }

  void _nextRound() {
    setState(() {
      _round++;
      _buildRound();
      _showBanner('Round ${_round + 1}/${level.rounds.length}', '',
          level.rounds[_round].boss ? 'BOSS! Fill the giant nest with ${level.rounds[_round].needed} matching eggs!' : 'Hatch ${level.rounds[_round].nests} more babies!');
    });
    SoundManager.instance.play('combo');
  }

  // ---- timer / pause ----------------------------------------------------------
  void _onSecond(Timer t) {
    if (!mounted || _paused || _ended) return;
    if (_memoryLeft > 0) {
      setState(() {
        _memoryLeft--;
        if (_memoryLeft == 0) _memoryHidden = true;
      });
      return; // the clock waits while you memorise
    }
    setState(() {
      if (_remaining > 0) _remaining--;
      if (_hintLeft > 0) {
        _hintLeft--;
        if (_hintLeft == 0) {
          _hintEgg = -1;
          _hintNest = -1;
        }
      }
    });
    if (_remaining <= 0) {
      // If everything is already sorted, let the last hatch finish.
      if (_eggs.isNotEmpty && _round == level.rounds.length - 1 && _nests.every((n) => n.hatching || n.hatched)) return;
      _gameOver("Time's up!");
    }
  }

  void _pause() {
    if (!mounted || _ended || _paused) return;
    setState(() => _paused = true);
    _roamCtl.stop();
    SoundManager.instance.pauseMusic();
  }

  void _resume() {
    if (!mounted) return;
    setState(() => _paused = false);
    if (_roams && !_ended) _roamCtl.repeat();
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

  // ---- geometry helpers ---------------------------------------------------------
  Offset _toLocal(Offset global) {
    final box = _stackKey.currentContext?.findRenderObject();
    if (box is RenderBox) return box.globalToLocal(global);
    return global;
  }

  double _nestDx(int i, _Layout lay) {
    final n = _nests[i];
    if (n.hatching || n.hatched) return n.frozenDx;
    if (!level.movingNests || n.boss) return 0;
    final (row, _, _) = lay.rc(i, _nests.length);
    final amp = math.min(lay.size.width * 0.10, 36.0);
    return math.sin((_roamCtl.value + row * 0.5) * math.pi * 2) * amp;
  }

  double _nestWidth(_Layout lay, int i) {
    final (_, per, _) = lay.rc(i, _nests.length);
    final base = math.min(lay.nestW, lay.size.width / per - 8);
    return _nests[i].boss ? math.min(base * 1.5, lay.size.width * 0.62) : base;
  }

  Offset _nestCenterNow(_Layout lay, int i) =>
      lay.nestCenter(i, _nests.length).translate(_nestDx(i, lay), 0);

  Offset _eggPos(int i, _Layout lay) {
    final base = lay.eggTopLeft(_eggs[i].slot, _jitter[i]);
    if (!level.rollingEggs) return base;
    final t = _roamCtl.value * math.pi * 2;
    final ph = _phase[i];
    return base + Offset(math.sin(t + ph) * lay.cellW * 0.42, math.cos(t * 2 + ph) * lay.cellH * 0.10);
  }

  void _floaty(String text, Offset pos, Color color) {
    _floaties.add(_Floaty(text, pos, color));
  }

  // ---- drag & drop -----------------------------------------------------------------
  void _onDrop(int nestIndex, int eggId, Offset globalPointer) {
    if (_ended || _paused) return;
    final ei = _eggs.indexWhere((e) => e.id == eggId);
    if (ei < 0) return;
    final egg = _eggs[ei];
    if (egg.gone) return;
    if (nestIndex >= _nests.length) return;
    final nest = _nests[nestIndex];
    if (nest.hatching || nest.hatched) return;
    final lay = _lay;
    if (lay == null) return;
    final local = _toLocal(globalPointer);

    // Locked nest: the egg just bounces back (nothing breaks, no move used).
    if (nest.locked) {
      final from = Offset(local.dx - lay.eggW / 2, local.dy - lay.eggH * 0.62);
      setState(() {
        _bounces.add(_Bounce(egg.id, egg.type, from, _eggPos(ei, lay)));
        _floaty('Locked!', Offset(local.dx, local.dy - 50), const Color(0xFF4FC3F7));
      });
      SoundManager.instance.play('wrong', volume: 0.6);
      return;
    }

    if (egg.type.id != 'golden') _moves++;
    if (egg.type.id == 'golden') {
      _golden(egg, nestIndex);
    } else if (egg.type.id == nest.type.id) {
      _correct(egg, nestIndex);
    } else {
      _breakEgg(egg, nestIndex);
    }
    _checkMoves();
  }

  void _correct(_EggInfo egg, int ni) {
    final nest = _nests[ni];
    final lay = _lay;
    var bonus = 0;
    setState(() {
      egg.placed = true;
      nest.count++;
      nest.popToken++;
      _streak++;
      _score += 10;
      if (_streak >= 2) {
        bonus = math.min(30, 5 * (_streak - 1));
        _score += bonus;
        if (lay != null) {
          _floaty('Combo x$_streak! +$bonus', _nestCenterNow(lay, ni).translate(0, -60), const Color(0xFFFFC107));
        }
      }
      if (_hintEgg == egg.id) {
        _hintEgg = -1;
        _hintNest = -1;
      }
      if (nest.count >= nest.needed) {
        if (lay != null) nest.frozenDx = _nestDx(ni, lay);
        nest.hatching = true;
        _hatches.add(_HatchInfo(ni, _slotCounter++));
      }
    });
    SoundManager.instance.play(bonus > 0 ? 'combo' : 'pop');
    HapticFeedback.lightImpact();
  }

  void _breakEgg(_EggInfo egg, int ni) {
    final lay = _lay;
    setState(() {
      egg.broken = true;
      _broken++;
      _streak = 0;
      _score = math.max(0, _score - 10);
      if (lay != null) {
        final c = _nestCenterNow(lay, ni);
        _splats.add(_Splat(egg.type, c));
        _floaty('Broken!', c.translate(0, -60), const Color(0xFFFF5252));
      }
    });
    SoundManager.instance.play('wrong');
    SoundManager.instance.play('crack', volume: 0.7);
    HapticFeedback.mediumImpact();
    if (!_feasible()) {
      final bad = _nests.firstWhere(
        (n) => !n.hatched && !n.hatching && _eggs.where((e) => !e.gone && e.type.id == n.type.id).length < n.needed - n.count,
        orElse: () => _nests.first,
      );
      _gameOver('No ${bad.type.name} eggs left for the nest!');
    }
  }

  void _golden(_EggInfo egg, int ni) {
    final lay = _lay;
    setState(() {
      egg.placed = true;
      _score += 100;
      _remaining += 10;
      _nests[ni].popToken++;
      if (lay != null) {
        _floaty('Golden! +100', _nestCenterNow(lay, ni).translate(0, -60), const Color(0xFFFFD54F));
        _floaty('+10 sec', _nestCenterNow(lay, ni).translate(0, -20), const Color(0xFF80DEEA));
        _confettiPos = _nestCenterNow(lay, ni);
      }
    });
    _hatchConfetti.play();
    SoundManager.instance.play('golden');
    HapticFeedback.mediumImpact();
  }

  bool _feasible() {
    for (final n in _nests) {
      if (n.hatched || n.hatching) continue;
      final need = n.needed - n.count;
      final avail = _eggs.where((e) => !e.gone && e.type.id == n.type.id).length;
      if (avail < need) return false;
    }
    return true;
  }

  void _checkMoves() {
    final limit = _moveLimit;
    if (limit == null || _ended) return;
    if (limit - _moves > 0) return;
    final stillNeeds = _nests.any((n) => !n.hatched && !n.hatching && n.count < n.needed) ||
        _round < level.rounds.length - 1;
    if (stillNeeds) _gameOver('Out of moves!');
  }

  void _useHint() {
    if (_ended || _paused || _hintsLeft <= 0 || _hintLeft > 0) return;
    final options = <int>[];
    for (var i = 0; i < _eggs.length; i++) {
      final e = _eggs[i];
      if (e.gone || e.type.id == 'golden') continue;
      final ni = _nests.indexWhere((n) =>
          n.type.id == e.type.id && !n.locked && !n.hatching && !n.hatched && n.count < n.needed);
      if (ni >= 0) options.add(i);
    }
    if (options.isEmpty) return;
    final ei = options[_rnd.nextInt(options.length)];
    final e = _eggs[ei];
    final ni = _nests.indexWhere((n) =>
        n.type.id == e.type.id && !n.locked && !n.hatching && !n.hatched && n.count < n.needed);
    setState(() {
      _hintsLeft--;
      _hintEgg = e.id;
      _hintNest = ni;
      _hintLeft = 4;
    });
    SoundManager.instance.play('click');
  }

  // ---- hatching --------------------------------------------------------------------
  void _onHatchPop(_HatchInfo h) {
    final lay = _lay;
    if (lay != null && h.nest < _nests.length) {
      _confettiPos = _nestCenterNow(lay, h.nest);
    }
    _hatchConfetti.play();
    if (level.kind == BabyKind.dragon || level.kind == BabyKind.dino) _shakeCtl.forward(from: 0);
    HapticFeedback.heavyImpact();
  }

  void _onHatchDone(_HatchInfo h) {
    if (!mounted) return;
    final lay = _lay;
    setState(() {
      _hatches.remove(h);
      final n = _nests[h.nest];
      n.hatching = false;
      n.hatched = true;
      _seated.add(h.slot);
      _hatchedTotal++;
      _score += n.boss ? 150 : 50;
      for (var i = 0; i < _nests.length; i++) {
        if (_nests[i].locked) {
          _nests[i].locked = false;
          if (lay != null) _floaty('Unlocked!', _nestCenterNow(lay, i).translate(0, -40), const Color(0xFF4FC3F7));
          SoundManager.instance.play('golden', volume: 0.6);
        }
      }
    });
    ProgressStore.addToAlbum(level.babyName);
    if (_nests.every((n) => n.hatched)) {
      if (_round < level.rounds.length - 1) {
        _nextRound();
      } else {
        _win();
      }
    }
  }

  void _win() {
    _timer?.cancel();
    _roamCtl.stop();
    final left = _remaining;
    final frac = left / level.timeSeconds;
    var stars = frac >= 0.5 ? 3 : (frac >= 0.25 ? 2 : 1);
    if (_broken > 4) stars = math.max(1, stars - 1);
    _stars = stars;
    setState(() {
      _score += left * 2;
      _won = true;
    });
    ProgressStore.saveResult(level.number, _stars, kLevels.length);
    SoundManager.instance.pauseMusic();
    SoundManager.instance.play('win');
    _winConfetti.play();
  }

  void _gameOver(String reason) {
    if (_ended) return;
    _timer?.cancel();
    _roamCtl.stop();
    setState(() {
      _lost = true;
      _failReason = reason;
    });
    SoundManager.instance.pauseMusic();
    SoundManager.instance.play('lose');
  }

  // ---- build -------------------------------------------------------------------------
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
            final lay = _Layout(Size(box.maxWidth, box.maxHeight), MediaQuery.of(context).padding, level);
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
                  GameOverOverlay(score: _score, reason: _failReason, onRetry: _restart, onMenu: _goMenu),
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

  Widget _nestLayer(int i, _Layout lay) {
    final n = _nests[i];
    final count = _nests.length;
    final nw = _nestWidth(lay, i);
    final (_, per, _) = lay.rc(i, count);
    final slotW = lay.size.width / per;
    final slotH = lay.nestRowH * (n.boss ? 1.6 : 1.0);
    return AnimatedBuilder(
      animation: _roamCtl,
      builder: (context, _) {
        final c = lay.nestCenter(i, count).translate(_nestDx(i, lay), 0);
        return Positioned(
          left: c.dx - slotW / 2,
          top: c.dy - slotH / 2,
          width: slotW,
          height: slotH,
          child: NestWidget(
            type: n.type,
            width: nw,
            slotWidth: slotW,
            slotHeight: slotH,
            eggCount: n.count,
            eggsNeeded: n.needed,
            hatching: n.hatching,
            hatched: n.hatched,
            popToken: n.popToken,
            hint: _hintNest == i,
            locked: n.locked,
            canAccept: !_ended && !n.hatching && !n.hatched,
            onAccept: (id, pos) => _onDrop(i, id, pos),
          ),
        );
      },
    );
  }

  Widget _eggLayer(int i, _Layout lay) {
    final e = _eggs[i];
    return AnimatedBuilder(
      key: ValueKey('egg${_round}_${e.id}'),
      animation: _roamCtl,
      builder: (context, _) {
        final p = _eggPos(i, lay);
        final tilt = level.rollingEggs ? math.cos(_roamCtl.value * math.pi * 2 + _phase[i]) * 0.5 : 0.0;
        return Positioned(
          left: p.dx,
          top: p.dy,
          width: lay.eggW,
          height: lay.eggH,
          child: Transform.rotate(angle: tilt, child: _draggableEgg(e, lay)),
        );
      },
    );
  }

  Widget _board(_Layout lay) {
    final accent = level.accent;
    final bouncing = _bounces.map((b) => b.eggId).toSet();
    final home = lay.homeSlot;
    final totalSlots = level.totalHatches;

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

        // home area: one seat for every baby of the level
        Positioned(
          left: 10,
          right: 10,
          top: lay.homeTop,
          height: lay.homePadH,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xAAFFFFFF), width: 3),
            ),
          ),
        ),
        for (var s = 0; s < totalSlots; s++)
          Positioned(
            left: lay.homeCenter(s).dx - home * 0.4,
            top: lay.homeCenter(s).dy + home * 0.28,
            width: home * 0.8,
            height: home * 0.14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x33000000),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),

        // nests
        for (var i = 0; i < _nests.length; i++) _nestLayer(i, lay),

        // babies sitting at home
        for (final s in _seated)
          Positioned(
            left: lay.homeCenter(s).dx - home * 0.48,
            top: lay.homeCenter(s).dy - home * 0.48,
            width: home * 0.96,
            height: home * 0.96,
            child: AnimalWidget(
              asset: level.animalAsset,
              size: home * 0.96,
              phase: (s % 5) * 0.2,
            ),
          ),

        // eggs on the ground
        for (var i = 0; i < _eggs.length; i++)
          if (!_eggs[i].gone && !bouncing.contains(_eggs[i].id)) _eggLayer(i, lay),

        // eggs bouncing back (locked nest)
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

        // broken eggs
        for (final sp in _splats) _splatFx(sp, lay),

        // hatch sequences
        for (final h in _hatches) _hatchLayer(h, lay),

        // floating labels
        for (final f in _floaties)
          TweenAnimationBuilder<double>(
            key: f.key,
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1100),
            onEnd: () {
              if (mounted) setState(() => _floaties.remove(f));
            },
            builder: (context, t, _) {
              return Positioned(
                left: f.pos.dx - 90,
                top: f.pos.dy - 40 * t,
                width: 180,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: (1 - t * t).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.8 + 0.4 * Curves.easeOutBack.transform(math.min(1.0, t * 3)),
                      child: Text(
                        f.text,
                        textAlign: TextAlign.center,
                        style: fancyText(28, color: f.color),
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

        // top bars
        Positioned(left: 10, right: 10, top: lay.top, height: lay.hud, child: _hud()),
        Positioned(left: 10, right: 10, top: lay.top + lay.hud + 2, height: lay.info, child: _infoBar()),

        // memory countdown
        if (_memoryLeft > 0)
          Positioned(
            left: 0,
            right: 0,
            top: lay.eggTop - 34,
            child: IgnorePointer(
              child: Text('Remember! $_memoryLeft',
                  textAlign: TextAlign.center, style: fancyText(34, color: const Color(0xFFFFEB3B))),
            ),
          ),

        // level / round banner
        if (_bannerOn) _banner(accent),
      ],
    );
  }

  Widget _splatFx(_Splat sp, _Layout lay) {
    final w = lay.nestW * 0.5;
    final h = w * kEggAspect;
    return TweenAnimationBuilder<double>(
      key: sp.key,
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      onEnd: () {
        if (mounted) setState(() => _splats.remove(sp));
      },
      builder: (context, t, _) {
        final e = Curves.easeOut.transform(t);
        final halves = <Widget>[];
        for (final top in [true, false]) {
          final dir = top ? -1.0 : 1.0;
          halves.add(Positioned(
            left: sp.pos.dx - w / 2 + dir * w * 0.6 * e,
            top: sp.pos.dy - h / 2 + (top ? -h * 0.2 * e : h * 0.1 * e) + h * 0.8 * t * t,
            width: w,
            height: h,
            child: IgnorePointer(
              child: Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: dir * 0.9 * e,
                  child: ClipPath(
                    clipper: EggHalfClipper(top: top),
                    child: EggWidget(type: sp.type, size: w, crack: 1),
                  ),
                ),
              ),
            ),
          ));
        }
        return Stack(clipBehavior: Clip.none, children: halves);
      },
    );
  }

  Widget _hatchLayer(_HatchInfo h, _Layout lay) {
    final n = _nests[h.nest];
    final nw = _nestWidth(lay, h.nest);
    final nh = nw * kNestAspect;
    final from = lay.nestCenter(h.nest, _nests.length).translate(n.frozenDx, -nh * 0.1);
    final boss = n.boss;
    return HatchAnimation(
      key: h.key,
      level: level,
      eggType: n.type,
      from: from,
      to: lay.homeCenter(h.slot),
      eggSize: nw * 0.5 * (boss ? 1.5 : 1.0),
      animalSize: lay.animalBig * (boss ? 1.5 : 1.0),
      endSize: lay.homeSlot * 0.96,
      onPop: () => _onHatchPop(h),
      onFinished: () => _onHatchDone(h),
    );
  }

  Widget _banner(Color accent) {
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: _bannerKey,
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 3200),
          onEnd: () {
            if (mounted) setState(() => _bannerOn = false);
          },
          builder: (context, t, _) {
            final op = t < 0.1 ? t / 0.1 : (t > 0.8 ? (1 - t) / 0.2 : 1.0);
            return Opacity(
              opacity: op.clamp(0.0, 1.0),
              child: Align(
                alignment: const Alignment(0, 0.05),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 310),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: alpha(accent, 0.94),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_bannerTitle, style: fancyText(34)),
                      if (_bannerSub.isNotEmpty) Text(_bannerSub, style: fancyText(22)),
                      if (_bannerRule.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(_bannerRule,
                            textAlign: TextAlign.center,
                            style: fancyText(16, color: Colors.white)),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
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

  Widget _infoBar() {
    final limit = _moveLimit;
    final movesLeft = limit == null ? 0 : math.max(0, limit - _moves);
    return Row(
      children: [
        Expanded(
          child: HudChip(
            icon: Icons.layers_rounded,
            text: 'Round ${_round + 1}/${level.rounds.length}',
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: HudChip(
            icon: Icons.egg_alt_rounded,
            text: '$_hatchedTotal/${level.totalHatches}',
            fontSize: 14,
            color: const Color(0xFFFFF59D),
          ),
        ),
        if (limit != null) ...[
          const SizedBox(width: 5),
          Expanded(
            child: HudChip(
              icon: Icons.touch_app_rounded,
              text: '$movesLeft',
              fontSize: 14,
              color: movesLeft <= 5 ? const Color(0xFFFF8A80) : Colors.white,
            ),
          ),
        ],
        const SizedBox(width: 5),
        Expanded(
          child: HudChip(
            icon: Icons.heart_broken_rounded,
            text: '$_broken',
            fontSize: 14,
            color: _broken > 0 ? const Color(0xFFFF8A80) : Colors.white,
          ),
        ),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: _useHint,
          child: HudChip(
            icon: Icons.lightbulb_rounded,
            text: 'x$_hintsLeft',
            fontSize: 14,
            color: _hintsLeft > 0 ? const Color(0xFF3E2723) : Colors.white54,
            background: _hintsLeft > 0 ? const Color(0xFFFFD54F) : const Color(0x66000000),
          ),
        ),
      ],
    );
  }

  Widget _draggableEgg(_EggInfo e, _Layout lay) {
    final fw = lay.eggW * 1.3;
    final fh = fw * kEggAspect;
    final golden = e.type.id == 'golden';
    final glow = golden || _hintEgg == e.id;
    return Draggable<int>(
      data: e.id,
      maxSimultaneousDrags: 1,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => SoundManager.instance.play('click', volume: 0.5),
      feedback: Transform.translate(
        // the egg floats just above the finger so it stays visible
        offset: Offset(-fw / 2, -fh * 0.62),
        child: EggWidget(type: e.type, size: fw, hidden: _memoryHidden && !golden),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: EggWidget(type: e.type, size: lay.eggW, hidden: _memoryHidden && !golden),
      ),
      child: EggWidget(
        type: e.type,
        size: lay.eggW,
        hidden: _memoryHidden && !golden,
        glow: glow,
        shakeToken: _shake[e.id] ?? 0,
      ),
    );
  }
}
