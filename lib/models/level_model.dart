import 'package:flutter/material.dart';

/// One colour of egg. To change an egg picture, replace the PNG in assets/images/.
class EggType {
  const EggType(this.id, this.name, this.color, this.asset);
  final String id;
  final String name;
  final Color color;
  final String asset;
}

/// Which baby animal hatches (decides the special animation).
enum BabyKind { chick, peacock, penguin, dragon }

/// Which ambient effect floats over the background.
enum AmbientKind { farm, forest, ice, volcano }

class LevelModel {
  const LevelModel({
    required this.number,
    required this.title,
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
    this.timeSeconds = 90,
    this.eggsPerNest = 3,
  });

  final int number;
  final String title;
  final String babyName;
  final String homeName;
  final BabyKind kind;
  final AmbientKind ambient;
  final List<EggType> eggs; // one nest per egg type
  final String background;
  final String animalAsset;
  final String hatchSfx; // file name inside assets/audio (without .mp3)
  final String bgm;
  final Color accent;
  final Color cardColor;
  final int timeSeconds;
  final int eggsPerNest;
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

/// The 4 levels. Change times, colours, sounds and pictures here.
const List<LevelModel> kLevels = [
  LevelModel(
    number: 1,
    title: 'Koli Kunju Farm',
    babyName: 'Chick',
    homeName: 'Farm Yard',
    kind: BabyKind.chick,
    ambient: AmbientKind.farm,
    eggs: [_white, _brown, _yellow],
    background: 'assets/images/bg_farm.jpg',
    animalAsset: 'assets/images/animal_chick.png',
    hatchSfx: 'hatch_chick',
    bgm: 'bgm_farm',
    accent: Color(0xFFFFB300),
    cardColor: Color(0xFF8BD16B),
  ),
  LevelModel(
    number: 2,
    title: 'Waterfall Forest',
    babyName: 'Peacock',
    homeName: 'Forest Nest',
    kind: BabyKind.peacock,
    ambient: AmbientKind.forest,
    eggs: [_blue, _green, _teal],
    background: 'assets/images/bg_forest.jpg',
    animalAsset: 'assets/images/animal_peacock.png',
    hatchSfx: 'hatch_peacock',
    bgm: 'bgm_forest',
    accent: Color(0xFF26A69A),
    cardColor: Color(0xFF3FA66B),
  ),
  LevelModel(
    number: 3,
    title: 'Ice World',
    babyName: 'Penguin',
    homeName: 'Ice Home',
    kind: BabyKind.penguin,
    ambient: AmbientKind.ice,
    eggs: [_white, _lightBlue, _skyBlue],
    background: 'assets/images/bg_ice.jpg',
    animalAsset: 'assets/images/animal_penguin.png',
    hatchSfx: 'hatch_penguin',
    bgm: 'bgm_ice',
    accent: Color(0xFF42A5F5),
    cardColor: Color(0xFF7FC4F0),
  ),
  LevelModel(
    number: 4,
    title: 'Dragon Volcano',
    babyName: 'Dragon',
    homeName: 'Lava Cave',
    kind: BabyKind.dragon,
    ambient: AmbientKind.volcano,
    eggs: [_red, _orange, _black],
    background: 'assets/images/bg_volcano.jpg',
    animalAsset: 'assets/images/animal_dragon.png',
    hatchSfx: 'hatch_dragon',
    bgm: 'bgm_volcano',
    accent: Color(0xFFFF5722),
    cardColor: Color(0xFFD9533B),
  ),
];
