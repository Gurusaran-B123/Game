# Deplo Hatch - Egg Sort

A portrait-first Flutter puzzle game starter project. Players drag coloured eggs
into matching nests. Each nest hatches a themed baby animal after three correct
eggs. The project includes four themed levels, a countdown timer, scoring,
pause/settings, retry/level progression, hatching animation and confetti.

## Requirements

- Flutter SDK (stable channel; Flutter 3.27 or newer recommended)
- Android Studio with Android SDK and platform tools
- A physical Android phone or Android emulator

## First-time setup

This ZIP contains the complete Dart source and assets, but does not include the
generated Android Gradle wrapper/platform folder. Generate the Android project
files once with Flutter:

1. Extract the ZIP and open a terminal in `deplo_hatch_egg_sort/`.
2. Run `flutter create --platforms=android .`
3. Run `flutter pub get`.
4. Connect an Android phone with USB debugging enabled, or start an emulator.
5. Run `flutter run`.

The app requests portrait-up orientation in `lib/main.dart`.

## Build an Android APK

```bash
flutter build apk --release
```

The APK is generated at:
`build/app/outputs/flutter-apk/app-release.apk`

For Google Play or Amazon Appstore publishing, set a unique Android
`applicationId` in `android/app/build.gradle` (or `build.gradle.kts`), add your
app icon, configure signing, and test the release APK on real devices. The
application ID should be chosen before publishing because changing it later
creates a different app identity.

## Gameplay

- **Level 1 – Sunny Farm:** white, brown and yellow eggs; baby chick.
- **Level 2 – Forest Falls:** blue, green and teal eggs; baby peacock.
- **Level 3 – Icy Adventure:** snow white, ice blue and sky blue eggs; penguin.
- **Level 4 – Dragon Volcano:** red, orange and black eggs; baby dragon.
- Three eggs of each colour are supplied per level (nine eggs total).
- Drop an egg into the matching nest. Incorrect drops do not consume the egg.
- Each nest hatches after three correct eggs.
- 90-second timer, score, pause, sound settings, retry and level progression.
- Timer pauses during the hatch animation.
- Background scenes are drawn with Flutter `CustomPainter`; no background
  image assets are required.

## Optional image assets

The game currently draws eggs with Flutter shapes and uses emoji for the baby
animals, so it runs without image files. To use custom transparent PNG/WebP art:

1. Add files under `assets/images/`.
2. Replace the egg drawing in `lib/widgets/egg_widget.dart` with an
   `Image.asset(...)`, and add the matching asset paths to `pubspec.yaml`.
3. Replace the animal emoji in `lib/widgets/nest_widget.dart` and
   `lib/widgets/hatch_animation.dart` with your animal images.

## Optional audio

Add your own licensed audio files under `assets/audio/` with these names:

| Purpose | Filename |
|---|---|
| Correct egg drop | `pop.mp3` |
| Incorrect drop | `wrong.mp3` |
| Baby chick hatch | `chick.mp3` |
| Baby peacock hatch | `peacock.mp3` |
| Baby penguin hatch | `penguin.mp3` |
| Baby dragon hatch | `dragon.mp3` |
| Farm background music | `farm_music.mp3` |
| Forest background music | `forest_music.mp3` |
| Winter background music | `winter_music.mp3` |
| Volcano background music | `dragon_music.mp3` |

Audio is optional; missing files are caught safely. The settings dialog has
separate sound-effects and background-music switches.

## Lottie animation

`assets/lottie/hatch_sparkle.json` is a small included sparkle animation used
during hatching. The animal pop/bounce and confetti are animated with Flutter
widgets and the `confetti` package. Replace the JSON with your own Lottie file
if desired, keeping the asset path or updating `pubspec.yaml`.

## Main files

- `lib/main.dart` – app setup, portrait lock and level selection.
- `lib/models/level_model.dart` – level themes, egg colours and audio names.
- `lib/screens/game_screen.dart` – drag-and-drop gameplay, timer and results.
- `lib/widgets/egg_widget.dart` – egg visuals and shake animation.
- `lib/widgets/nest_widget.dart` – matching nests and hatch progress.
- `lib/widgets/hatch_animation.dart` – hatch animation and confetti.
- `lib/utils/sound_manager.dart` – optional sound and music playback.

## Verification note

The source and asset files in this package were reviewed and the Lottie JSON was
validated. A Flutter/Dart SDK was not available in the build environment, so
`flutter analyze`, emulator testing and APK compilation still need to be run
on a machine with Flutter installed.
