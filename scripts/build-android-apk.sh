#!/usr/bin/env bash
# Build a signed release APK for sideload / device testing before Play AAB.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT/pagewalker/android"
KEY_PROPS="$ANDROID_DIR/key.properties"
KEYSTORE="$ANDROID_DIR/upload-keystore.jks"
APP_DIR="$ROOT/pagewalker"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found on PATH"
  exit 1
fi

if [[ ! -f "$KEY_PROPS" ]]; then
  echo "Missing $KEY_PROPS — run ./scripts/android-create-keystore.sh"
  exit 1
fi

if [[ ! -f "$KEYSTORE" ]]; then
  echo "Keystore not found at $KEYSTORE"
  exit 1
fi

if [[ ! -f "$APP_DIR/lib/core/config/env.dart" ]]; then
  echo "Missing $APP_DIR/lib/core/config/env.dart"
  exit 1
fi

cd "$APP_DIR"
flutter pub get
flutter build apk --release

OUT="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "Done: $OUT"
ls -lh "$OUT"
