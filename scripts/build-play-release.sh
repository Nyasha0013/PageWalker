#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/pagewalker"
PROPS="$APP/android/key.properties"
OUT="$APP/build/app/outputs/bundle/release"

if [[ ! -f "$PROPS" ]]; then
  echo "Missing $PROPS"
  echo "Run: ./scripts/android-create-keystore.sh"
  exit 1
fi

if [[ ! -f "$APP/lib/core/config/env.dart" ]]; then
  echo "Missing $APP/lib/core/config/env.dart (Supabase + API keys for release)."
  echo "Copy from a teammate or create from env.dart.example if present."
  exit 1
fi

cd "$APP"
flutter pub get
flutter build appbundle --release

AAB="$OUT/app-release.aab"
if [[ -f "$AAB" ]]; then
  echo ""
  echo "Upload this file in Play Console → Release → Production (or Internal testing):"
  echo "  $AAB"
  ls -lh "$AAB"
else
  echo "Build finished but AAB not found at $AAB"
  exit 1
fi
