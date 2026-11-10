#!/usr/bin/env bash
# One-time setup: creates the Android folder around the Dart code, installs
# packages, patches Android config and generates the launcher icon.
# Usage:  cd deplo_hatch && bash setup.sh
set -euo pipefail

command -v flutter >/dev/null || { echo "Flutter not found. Install it from https://docs.flutter.dev/get-started/install"; exit 1; }

BACKUP="$(mktemp -d)"
cp -r lib assets pubspec.yaml analysis_options.yaml "$BACKUP"/
flutter create --org com.deplofree --project-name deplo_hatch --platforms=android .
rm -rf lib assets pubspec.yaml analysis_options.yaml
cp -r "$BACKUP"/lib "$BACKUP"/assets "$BACKUP"/pubspec.yaml "$BACKUP"/analysis_options.yaml .
rm -rf "$BACKUP" test

flutter pub get
python3 tools/patch_android.py
dart run flutter_launcher_icons

echo
echo "Done. Next:"
echo "  flutter run                      (test on a phone)"
echo "  flutter build apk --release      (APK -> build/app/outputs/flutter-apk/app-release.apk)"
