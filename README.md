# Deplo Hatch - Egg Sort

Drag coloured eggs into the matching nest. Three of the same colour = the egg cracks and a baby animal hatches!
4 levels: Chick (farm), Peacock (forest), Penguin (ice), Dragon (volcano boss). 90 seconds per level.

## Build

```
bash setup.sh                    # one time: creates android/, gets packages, icon
flutter run                      # test on your phone
flutter build apk --release      # build/app/outputs/flutter-apk/app-release.apk
```
No computer? Push this folder to a GitHub repo - `.github/workflows/build.yml` builds the APK
(Actions tab -> latest run -> Artifacts -> DeploHatch-apk). Codemagic works with `codemagic.yaml`.

## Add your own pictures and sounds (no code changes)

Every picture/sound is loaded by FILE NAME. Replace a file with your own file with the SAME name
and keep the same format. That is all.

### Pictures - assets/images/
| File | What | Tip |
|---|---|---|
| egg_white / brown / yellow .png | Level 1 eggs | transparent PNG, about 220 x 270 px, egg shape |
| egg_blue / green / teal .png | Level 2 eggs | same |
| egg_white (again) / lightblue / skyblue .png | Level 3 eggs | white egg is shared with level 1 |
| egg_red / orange / black .png | Level 4 eggs | same |
| nest.png | the nest | transparent PNG, about 300 x 190 px, bowl seen slightly from above |
| animal_chick / peacock / penguin / dragon .png | baby animals | transparent PNG, square, about 256 x 256 px |
| bg_farm / forest / ice / volcano .jpg | backgrounds | portrait, about 540 x 960 px or bigger |
| icon.png | app icon | 512 x 512 px, then run `dart run flutter_launcher_icons` |

If a picture is missing or broken the game shows a simple painted egg / paw icon instead, so it never crashes.

### Sounds - assets/audio/ (mp3)
| File | When it plays |
|---|---|
| pop.mp3 | egg goes into the correct nest |
| wrong.mp3 | wrong nest (buzz) |
| crack.mp3 | egg cracks |
| hatch_chick / hatch_peacock / hatch_penguin / hatch_dragon .mp3 | baby appears (dragon roar) |
| fire.mp3 | dragon fire blast |
| win.mp3, lose.mp3, star.mp3, click.mp3 | level complete, game over, each star, buttons |
| bgm_farm / bgm_forest / bgm_ice / bgm_volcano .mp3 | level music (loops; the level menu uses bgm_farm) |

Keep music files short (10-60 s, below ~1.5 MB) so the app stays small. Use royalty-free sounds
(for example pixabay.com/sound-effects, freesound.org with CC0) and check the licence before publishing.

### Add a NEW egg colour / change a level
Open `lib/models/level_model.dart`:
1. Add the picture `assets/images/egg_pink.png`.
2. Add one line `const _pink = EggType('pink', 'Pink', Color(0xFFFF80AB), 'assets/images/egg_pink.png');`
3. Put `_pink` in a level's `eggs: [...]` list (one nest is created per egg type, 3 eggs each).
Change `timeSeconds`, `title`, `bgm`, `hatchSfx` or `animalAsset` in the same place.

### Lottie sparkle
`assets/lottie/sparkle.json` plays when an egg lands. Replace with any Lottie JSON (same name),
or delete the file contents - the game still works without it.

### Regenerate the placeholder art/sound
`python3 tools/make_assets.py` (needs pillow, numpy, ffmpeg). It overwrites assets/, so run it only if you want the originals back.

## Files
- lib/main.dart - app start + level select
- lib/models/level_model.dart - levels, egg colours, sounds, animals
- lib/screens/game_screen.dart - game rules, timer, score, drag & drop, pause, win/lose
- lib/widgets/egg_widget.dart, nest_widget.dart, hatch_animation.dart - egg, nest, hatch show
- lib/widgets/animal_widget.dart, effects.dart, ambient_effects.dart, game_overlays.dart, ui_bits.dart - helpers
- lib/utils/sound_manager.dart, progress_store.dart - audio, saved progress
