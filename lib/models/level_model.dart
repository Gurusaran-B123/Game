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

class LevelModel {
  const LevelModel({
    required this.number,
    required this.title,
    required this.tag,
    required this.rule,
    required this.babyName,
    required this.homeName,
    required this.kind,
    required this.ambient,
    required this.eggs,
    required this.rounds,
    required this.background,
    required this.animalAsset,
    required this.hatchSfx,
    required this.bgm,
    required this.accent,
    required this.cardColor,
    this.timeSeconds = 150,
    this.movingNests = false,
    this.rollingEggs = false,
    this.lockedNest = false,
    this.memory = false,
    this.extraMoves = -1, // -1 = unlimited moves
  });

  final int number;
  final String title;
  final String tag; // short label on the level card
  final String rule; // shown when the level starts
  final String babyName;
  final String homeName;
  final BabyKind kind;
  final AmbientKind ambient;
  final List<EggType> eggs; // colours / patterns used by the nests
  final List<RoundSpec> rounds;
  final String background;
  final String animalAsset;
  final String hatchSfx; // file name inside assets/audio (without .mp3)
  final String bgm;
  final Color accent;
  final Color cardColor;
  final int timeSeconds;
  final bool movingNests;
  final bool rollingEggs;
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

/// All levels. Change times, rounds, colours, sounds and pictures here.
const List<LevelModel> kLevels = [
  LevelModel(
    number: 1,
    title: 'Koli Kunju Farm',
    tag: 'Easy start',
    rule: 'Drag each egg to the nest with the same colour.\nA different colour BREAKS the egg!',
    babyName: 'Chick',
    homeName: 'Farm Yard',
    kind: BabyKind.chick,
    ambient: AmbientKind.farm,
    eggs: [_white, _brown, _yellow],
    rounds: [
      RoundSpec(nests: 2),
      RoundSpec(nests: 3),
      RoundSpec(nests: 3),
      RoundSpec(nests: 2),
    ],
    background: 'assets/images/bg_farm.jpg',
    animalAsset: 'assets/images/animal_chick.png',
    hatchSfx: 'hatch_chick',
    bgm: 'bgm_farm',
    accent: Color(0xFFFFB300),
    cardColor: Color(0xFF8BD16B),
    timeSeconds: 150,
  ),
  LevelModel(
    number: 2,
    title: 'Waterfall Forest',
    tag: 'Sliding nests',
    rule: 'The nests are sliding!\nDrop the egg in the nest with the same colour.',
    babyName: 'Peacock',
    homeName: 'Forest Nest',
    kind: BabyKind.peacock,
    ambient: AmbientKind.forest,
    eggs: [_blue, _green, _teal],
    rounds: [
      RoundSpec(nests: 2),
      RoundSpec(nests: 3),
      RoundSpec(nests: 3),
      RoundSpec(nests: 2),
    ],
    background: 'assets/images/bg_forest.jpg',
    animalAsset: 'assets/images/animal_peacock.png',
    hatchSfx: 'hatch_peacock',
    bgm: 'bgm_forest',
    accent: Color(0xFF26A69A),
    cardColor: Color(0xFF3FA66B),
    timeSeconds: 160,
    movingNests: true,
  ),
  LevelModel(
    number: 3,
    title: 'Ice World',
    tag: 'Ice lock',
    rule: 'One nest is locked in ice.\nHatch another nest to melt it. Careful: the blues look alike!',
    babyName: 'Penguin',
    homeName: 'Ice Home',
    kind: BabyKind.penguin,
    ambient: AmbientKind.ice,
    eggs: [_white, _lightBlue, _skyBlue, _blue],
    rounds: [
      RoundSpec(nests: 3),
      RoundSpec(nests: 3),
      RoundSpec(nests: 4),
    ],
    background: 'assets/images/bg_ice.jpg',
    animalAsset: 'assets/images/animal_penguin.png',
    hatchSfx: 'hatch_penguin',
    bgm: 'bgm_ice',
    accent: Color(0xFF42A5F5),
    cardColor: Color(0xFF7FC4F0),
    timeSeconds: 170,
    lockedNest: true,
  ),
  LevelModel(
    number: 4,
    title: 'Bunny Meadow',
    tag: 'Pattern eggs',
    rule: 'All eggs are the same colour!\nMatch the PATTERN on the egg to the pattern in the nest.',
    babyName: 'Bunny',
    homeName: 'Meadow',
    kind: BabyKind.bunny,
    ambient: AmbientKind.meadow,
    eggs: [_patDots, _patStripes, _patZig, _patStars],
    rounds: [
      RoundSpec(nests: 3),
      RoundSpec(nests: 3, golden: true),
      RoundSpec(nests: 4),
    ],
    background: 'assets/images/bg_meadow.jpg',
    animalAsset: 'assets/images/animal_bunny.png',
    hatchSfx: 'hatch_bunny',
    bgm: 'bgm_meadow',
    accent: Color(0xFFEC407A),
    cardColor: Color(0xFFF48FB1),
    timeSeconds: 170,
  ),
  LevelModel(
    number: 5,
    title: 'Dino Valley',
    tag: 'Memory',
    rule: 'Remember the eggs!\nAfter 3 seconds they are covered with a ? mark.',
    babyName: 'Dino',
    homeName: 'Dino Den',
    kind: BabyKind.dino,
    ambient: AmbientKind.jungle,
    eggs: [_red, _blue, _green, _yellow],
    rounds: [
      RoundSpec(nests: 3, spares: 4),
      RoundSpec(nests: 3, spares: 4),
      RoundSpec(nests: 4, spares: 4),
    ],
    background: 'assets/images/bg_dino.jpg',
    animalAsset: 'assets/images/animal_dino.png',
    hatchSfx: 'hatch_dino',
    bgm: 'bgm_dino',
    accent: Color(0xFF7CB342),
    cardColor: Color(0xFFE59A4A),
    timeSeconds: 190,
    memory: true,
  ),
  LevelModel(
    number: 6,
    title: 'Rainbow Hills',
    tag: 'Limited moves',
    rule: 'You only have a few moves!\nEvery drop counts. Catch the golden egg for a bonus.',
    babyName: 'Unicorn',
    homeName: 'Rainbow Stable',
    kind: BabyKind.unicorn,
    ambient: AmbientKind.rainbow,
    eggs: [_pink, _purple, _lightBlue, _yellow],
    rounds: [
      RoundSpec(nests: 3, golden: true),
      RoundSpec(nests: 3),
      RoundSpec(nests: 4, golden: true),
    ],
    background: 'assets/images/bg_rainbow.jpg',
    animalAsset: 'assets/images/animal_unicorn.png',
    hatchSfx: 'hatch_unicorn',
    bgm: 'bgm_rainbow',
    accent: Color(0xFF8E24AA),
    cardColor: Color(0xFFB388EB),
    timeSeconds: 190,
    extraMoves: 8,
  ),
  LevelModel(
    number: 7,
    title: 'Dragon Volcano',
    tag: 'BOSS',
    rule: 'The eggs are rolling around!\nAt the end, hatch the GIANT dragon egg.',
    babyName: 'Dragon',
    homeName: 'Lava Cave',
    kind: BabyKind.dragon,
    ambient: AmbientKind.volcano,
    eggs: [_red, _orange, _black, _brown],
    rounds: [
      RoundSpec(nests: 3),
      RoundSpec(nests: 3, golden: true),
      RoundSpec(nests: 4),
      RoundSpec(nests: 1, needed: 5, spares: 4, boss: true),
    ],
    background: 'assets/images/bg_volcano.jpg',
    animalAsset: 'assets/images/animal_dragon.png',
    hatchSfx: 'hatch_dragon',
    bgm: 'bgm_volcano',
    accent: Color(0xFFFF5722),
    cardColor: Color(0xFFD9533B),
    timeSeconds: 220,
    rollingEggs: true,
  ),
];
