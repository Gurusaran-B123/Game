import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One colour (or pattern) of egg. To change an egg picture, replace the PNG in assets/images/.
class EggType {
  const EggType(this.id, this.name, this.color, this.asset);
  final String id;
  final String name;
  final Color color;
  final String asset;
}

/// Which baby animal hatches (decides the special animation).
enum BabyKind { chick, peacock, penguin, bunny, dino, unicorn, dragon }

/// Which ambient effect floats over the background.
enum AmbientKind { farm, forest, ice, volcano, meadow, jungle, rainbow }

/// One round of a level: [nests] nests appear, each needs [needed] matching eggs.
/// [spares] extra eggs are added because a wrong egg BREAKS.
class RoundSpec {
  const RoundSpec({
    required this.nests,
    this.needed = 3,
    this.spares = 3,
    this.golden = false,
    this.boss = false,
  });
  final int nests;
  final int needed;
  final int spares;
  final bool golden; // a golden mystery egg appears (goes in ANY nest, big bonus)
  final bool boss; // one giant nest that needs [needed] eggs
}

/// One task (stage) inside a level. Every level has 10 tasks, each with up to 3 stars.
class TaskSpec {
  const TaskSpec({
    required this.number,
    required this.title,
    required this.rule,
    required this.rounds,
    required this.timeSeconds,
    this.movingNests = false,
    this.rollingEggs = false,
    this.rotatedEggs = false,
    this.lockedNest = false,
    this.memory = false,
    this.extraMoves = -1, // -1 = unlimited moves
  });

  final int number; // 1..10
  final String title;
  final String rule; // shown when the task starts
  final List<RoundSpec> rounds;
  final int timeSeconds;
  final bool movingNests;
  final bool rollingEggs; // eggs roll / shuffle around on the floor
  final bool rotatedEggs; // eggs lie tilted or upside down
  final bool lockedNest;
  final bool memory;
  final int extraMoves;

  int get totalHatches => rounds.fold<int>(0, (a, r) => a + r.nests);
  int get maxNests => rounds.fold<int>(0, (a, r) => math.max(a, r.nests));
  int get maxEggs => rounds.fold<int>(
      0, (a, r) => math.max(a, r.nests * r.needed + r.spares + (r.golden ? 1 : 0)));

  /// null = unlimited. Otherwise every drop uses one move.
  int? get moveLimit {
    if (extraMoves < 0) return null;
    final need = rounds.fold<int>(0, (a, r) => a + r.nests * r.needed);
    return need + extraMoves;
  }
}

/// Stars can be spent to buy extra time inside a task.
const int kBuyTimeCost = 3;
const int kBuyTimeSeconds = 15;
const int kTasksPerLevel = 10;

class LevelModel {
  LevelModel({
    required this.number,
    required this.title,
    required this.tag,
    required this.babyName,
    required this.homeName,
    required this.kind,
    required this.ambient,
    required this.eggs,
    required this.background,
    required this.animalAsset,
    required this.hatchSfx,
    required this.bgm,
    required this.accent,
    required this.cardColor,
    this.spares = 3,
    this.extra = LevelExtra.none,
  });

  final int number;
  final String title;
  final String tag; // short label on the level card
  final String babyName;
  final String homeName;
  final BabyKind kind;
  final AmbientKind ambient;
  final List<EggType> eggs; // colours / patterns used by the nests (4)
  final String background;
  final String animalAsset;
  final String hatchSfx; // file name inside assets/audio (without .mp3)
  final String bgm;
  final Color accent;
  final Color cardColor;
  final int spares; // spare eggs per round
  final LevelExtra extra; // special rule of this level from task 4 on

  /// The 10 tasks of this level (built from the template below).
  late final List<TaskSpec> tasks = _buildTasks(this);
}

/// Special rule that a level adds to its later tasks (task 4 to 10).
enum LevelExtra { none, moving, locked, memory, limitedMoves, rolling }

int _time(List<RoundSpec> rounds, int levelIdx, int bonus) {
  final eggs = rounds.fold<int>(
      0, (a, r) => a + r.nests * r.needed + r.spares + (r.golden ? 1 : 0));
  final t = (25 + eggs * 3.4 + bonus) * (1 - 0.03 * levelIdx);
  return ((t / 5).round() * 5).clamp(40, 400).toInt();
}

List<RoundSpec> _rs(LevelModel l, List<int> nests, {List<int> golden = const [], int extraSpares = 0}) {
  final sp = l.spares + extraSpares;
  return [
    for (var i = 0; i < nests.length; i++)
      RoundSpec(nests: nests[i], spares: sp, golden: golden.contains(i)),
  ];
}

List<TaskSpec> _buildTasks(LevelModel l) {
  final i = l.number - 1;
  final ex = l.extra;
  bool later(int t) => t >= 3; // tasks 4..10
  TaskSpec mk(int n, String title, String rule, List<RoundSpec> rounds,
      {bool moving = false, bool rolling = false, bool rotated = false, bool locked = false,
       bool memory = false, int bonus = 0, bool boss = false}) {
    final t = n - 1;
    final m = moving || (later(t) && ex == LevelExtra.moving);
    final r = rolling || (later(t) && ex == LevelExtra.rolling);
    final lk = locked || (later(t) && ex == LevelExtra.locked);
    final me = memory || (later(t) && ex == LevelExtra.memory);
    final lim = later(t) && ex == LevelExtra.limitedMoves ? 10 : -1;
    var extra = bonus;
    if (m) extra += 15;
    if (r) extra += 20;
    if (rotated) extra += 12;
    if (lk) extra += 10;
    if (me) extra += 15;
    var text = rule;
    if (later(t) && ex != LevelExtra.none && !boss) {
      text += switch (ex) {
        LevelExtra.moving => '\nThe nests are sliding!',
        LevelExtra.locked => '\nAn ice lock covers one nest.',
        LevelExtra.memory => '\nEggs get covered after 3 seconds!',
        LevelExtra.limitedMoves => '\nYou have limited moves!',
        LevelExtra.rolling => '\nThe eggs are rolling!',
        LevelExtra.none => '',
      };
    }
    return TaskSpec(
      number: n,
      title: title,
      rule: text,
      rounds: rounds,
      timeSeconds: _time(rounds, i, extra),
      movingNests: m,
      rollingEggs: r,
      rotatedEggs: rotated,
      lockedNest: lk,
      memory: me,
      extraMoves: lim,
    );
  }

  const same = 'Drag each egg to the nest of the same colour.\nA different one BREAKS the egg!';
  final pattern = l.eggs.first.id.startsWith('p_');
  final base = pattern ? 'Match the PATTERN on the egg to the nest.\nA different one BREAKS the egg!' : same;
  return [
    mk(1, 'Basics', base, _rs(l, [3])),
    mk(2, 'Two Rounds', 'Two rounds. Hatch all babies in both!', _rs(l, [2, 3])),
    mk(3, 'Three Rounds', 'Three rounds. A golden egg may appear!', _rs(l, [2, 3, 3], golden: [1])),
    mk(4, 'Four Rounds', 'Four rounds. Take your time and look carefully.', _rs(l, [3, 3, 3, 4])),
    mk(5, 'Rolling Eggs', 'The eggs are rolling and shuffling on the floor!\nCatch them.', _rs(l, [3, 3]), rolling: true),
    mk(6, 'Upside Down', 'The eggs are tilted and upside down.\nLook at the colour!', _rs(l, [3, 4], golden: [0]), rotated: true),
    mk(7, 'Sliding Nests', 'The nests are sliding left and right!', _rs(l, [3, 3, 4]), moving: true),
    mk(8, 'Ice Lock', 'One nest is locked in ice.\nHatch another nest to melt it.', _rs(l, [3, 3, 4]), locked: true),
    mk(9, 'Memory', 'Remember the eggs!\nThey are covered after 3 seconds.', _rs(l, [3, 3, 4], extraSpares: 2), memory: true),
    TaskSpec(
      number: 10,
      title: 'Boss Task',
      rule: 'BOSS! Rolling, tilted eggs and a GIANT nest at the end.',
      rounds: [
        ..._rs(l, [3, 3, 4], golden: [1]),
        const RoundSpec(nests: 1, needed: 5, spares: 4, boss: true),
      ],
      timeSeconds: _time([
        ..._rs(l, [3, 3, 4], golden: [1]),
        const RoundSpec(nests: 1, needed: 5, spares: 4, boss: true),
      ], i, 50),
      rollingEggs: true,
      rotatedEggs: true,
      movingNests: false,
    ),
  ];
}

// ---- Egg types ---------------------------------------------------------
const _white = EggType('white', 'White', Color(0xFFFAF8F0), 'assets/images/egg_white.png');
const _brown = EggType('brown', 'Brown', Color(0xFFB07040), 'assets/images/egg_brown.png');
const _yellow = EggType('yellow', 'Light Yellow', Color(0xFFFFEC8C), 'assets/images/egg_yellow.png');
const _blue = EggType('blue', 'Blue', Color(0xFF4678EB), 'assets/images/egg_blue.png');
const _green = EggType('green', 'Green', Color(0xFF50BE5A), 'assets/images/egg_green.png');
const _teal = EggType('teal', 'Teal', Color(0xFF1EAAAA), 'assets/images/egg_teal.png');
const _lightBlue = EggType('lightblue', 'Light Blue', Color(0xFFAAD7FA), 'assets/images/egg_lightblue.png');
const _skyBlue = EggType('skyblue', 'Sky Blue', Color(0xFF5AB9F5), 'assets/images/egg_skyblue.png');
const _red = EggType('red', 'Red', Color(0xFFEB3C3C), 'assets/images/egg_red.png');
const _orange = EggType('orange', 'Orange', Color(0xFFFF9628), 'assets/images/egg_orange.png');
const _black = EggType('black', 'Black', Color(0xFF32323C), 'assets/images/egg_black.png');
const _pink = EggType('pink', 'Pink', Color(0xFFFF82B4), 'assets/images/egg_pink.png');
const _purple = EggType('purple', 'Purple', Color(0xFF965AD2), 'assets/images/egg_purple.png');

// Pattern eggs: all the same colour, so the PATTERN decides (the nest ring is neutral).
const _patDots = EggType('p_dots', 'Dots', Color(0xFFD7C4A3), 'assets/images/egg_pat_dots.png');
const _patStripes = EggType('p_stripes', 'Stripes', Color(0xFFD7C4A3), 'assets/images/egg_pat_stripes.png');
const _patZig = EggType('p_zig', 'Zigzag', Color(0xFFD7C4A3), 'assets/images/egg_pat_zig.png');
const _patStars = EggType('p_stars', 'Stars', Color(0xFFD7C4A3), 'assets/images/egg_pat_stars.png');

/// Golden mystery egg: fits in ANY nest and gives a big bonus.
const EggType kGoldenEgg = EggType('golden', 'Golden', Color(0xFFFFD54F), 'assets/images/egg_golden.png');

/// Picture used for eggs that are "covered" in the memory level.
const EggType kMysteryEgg = EggType('mystery', 'Mystery', Color(0xFF6E6E8C), 'assets/images/egg_mystery.png');

/// All levels. Each one has 10 tasks that are built automatically (see _buildTasks).
/// Change pictures, sounds, colours and extra rules here.
final List<LevelModel> kLevels = [
  LevelModel(
    number: 1,
    title: 'Koli Kunju Farm',
    tag: 'Farm basics',
    babyName: 'Chick',
    homeName: 'Farm Yard',
    kind: BabyKind.chick,
    ambient: AmbientKind.farm,
    eggs: [_white, _brown, _yellow, _orange],
    background: 'assets/images/bg_farm.jpg',
    animalAsset: 'assets/images/animal_chick.png',
    hatchSfx: 'hatch_chick',
    bgm: 'bgm_farm',
    accent: const Color(0xFFFFB300),
    cardColor: const Color(0xFF8BD16B),
  ),
  LevelModel(
    number: 2,
    title: 'Waterfall Forest',
    tag: 'Sliding nests',
    babyName: 'Peacock',
    homeName: 'Forest Nest',
    kind: BabyKind.peacock,
    ambient: AmbientKind.forest,
    eggs: [_blue, _green, _teal, _yellow],
    background: 'assets/images/bg_forest.jpg',
    animalAsset: 'assets/images/animal_peacock.png',
    hatchSfx: 'hatch_peacock',
    bgm: 'bgm_forest',
    accent: const Color(0xFF26A69A),
    cardColor: const Color(0xFF3FA66B),
    extra: LevelExtra.moving,
  ),
  LevelModel(
    number: 3,
    title: 'Ice World',
    tag: 'Ice lock',
    babyName: 'Penguin',
    homeName: 'Ice Home',
    kind: BabyKind.penguin,
    ambient: AmbientKind.ice,
    eggs: [_white, _lightBlue, _skyBlue, _blue],
    background: 'assets/images/bg_ice.jpg',
    animalAsset: 'assets/images/animal_penguin.png',
    hatchSfx: 'hatch_penguin',
    bgm: 'bgm_ice',
    accent: const Color(0xFF42A5F5),
    cardColor: const Color(0xFF7FC4F0),
    extra: LevelExtra.locked,
  ),
  LevelModel(
    number: 4,
    title: 'Bunny Meadow',
    tag: 'Pattern eggs',
    babyName: 'Bunny',
    homeName: 'Meadow',
    kind: BabyKind.bunny,
    ambient: AmbientKind.meadow,
    eggs: [_patDots, _patStripes, _patZig, _patStars],
    background: 'assets/images/bg_meadow.jpg',
    animalAsset: 'assets/images/animal_bunny.png',
    hatchSfx: 'hatch_bunny',
    bgm: 'bgm_meadow',
    accent: const Color(0xFFEC407A),
    cardColor: const Color(0xFFF48FB1),
    spares: 3,
  ),
  LevelModel(
    number: 5,
    title: 'Dino Valley',
    tag: 'Memory',
    babyName: 'Dino',
    homeName: 'Dino Den',
    kind: BabyKind.dino,
    ambient: AmbientKind.jungle,
    eggs: [_red, _blue, _green, _yellow],
    background: 'assets/images/bg_dino.jpg',
    animalAsset: 'assets/images/animal_dino.png',
    hatchSfx: 'hatch_dino',
    bgm: 'bgm_dino',
    accent: const Color(0xFF7CB342),
    cardColor: const Color(0xFFE59A4A),
    spares: 4,
    extra: LevelExtra.memory,
  ),
  LevelModel(
    number: 6,
    title: 'Rainbow Hills',
    tag: 'Limited moves',
    babyName: 'Unicorn',
    homeName: 'Rainbow Stable',
    kind: BabyKind.unicorn,
    ambient: AmbientKind.rainbow,
    eggs: [_pink, _purple, _lightBlue, _yellow],
    background: 'assets/images/bg_rainbow.jpg',
    animalAsset: 'assets/images/animal_unicorn.png',
    hatchSfx: 'hatch_unicorn',
    bgm: 'bgm_rainbow',
    accent: const Color(0xFF8E24AA),
    cardColor: const Color(0xFFB388EB),
    extra: LevelExtra.limitedMoves,
  ),
  LevelModel(
    number: 7,
    title: 'Dragon Volcano',
    tag: 'BOSS world',
    babyName: 'Dragon',
    homeName: 'Lava Cave',
    kind: BabyKind.dragon,
    ambient: AmbientKind.volcano,
    eggs: [_red, _orange, _black, _brown],
    background: 'assets/images/bg_volcano.jpg',
    animalAsset: 'assets/images/animal_dragon.png',
    hatchSfx: 'hatch_dragon',
    bgm: 'bgm_volcano',
    accent: const Color(0xFFFF5722),
    cardColor: const Color(0xFFD9533B),
    spares: 3,
    extra: LevelExtra.rolling,
  ),
];
