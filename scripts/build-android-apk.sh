#!/usr/bin/env bash
# Sideload APK for device testing (boss, QA). Default: debug-signed so it
# upgrades earlier debug builds. Use "release" for Play-aligned signing.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT/pagewalker/android"
KEY_PROPS="$ANDROID_DIR/key.properties"
KEYSTORE="$ANDROID_DIR/upload-keystore.jks"
APP_DIR="$ROOT/pagewalker"
MODE="${1:-sideload}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found on PATH"
  exit 1
fi

if [[ ! -f "$APP_DIR/lib/core/config/env.dart" ]]; then
  echo "Missing $APP_DIR/lib/core/config/env.dart"
  exit 1
fi

cd "$APP_DIR"
flutter pub get

if [[ "$MODE" == "release" ]]; then
  if [[ ! -f "$KEY_PROPS" ]]; then
    echo "Missing $KEY_PROPS — run ./scripts/android-create-keystore.sh"
    exit 1
  fi
  if [[ ! -f "$KEYSTORE" ]]; then
    echo "Keystore not found at $KEYSTORE"
    exit 1
  fi
  flutter build apk --release
  OUT="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
  COPY="$ROOT/Pagewalker-release.apk"
else
  flutter build apk --debug
  OUT="$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"
  COPY="$ROOT/Pagewalker-sideload.apk"
  echo ""
  echo "Sideload build (debug-signed). Upgrades earlier debug APKs on the same phone."
  echo "If Play Protect blocks: tap Install anyway. If install fails, uninstall old Pagewalker first."
fi

cp "$OUT" "$COPY"
echo ""
echo "Done: $OUT"
echo "Copy:  $COPY"
ls -lh "$OUT" "$COPY"
