#!/usr/bin/env bash
# Play upload keystore (back it up)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT/pagewalker/android"
KEYSTORE="$ANDROID_DIR/upload-keystore.jks"
PROPS="$ANDROID_DIR/key.properties"

if [[ -f "$KEYSTORE" ]]; then
  echo "Keystore already exists: $KEYSTORE"
  exit 0
fi

read -r -s -p "Keystore password (store): " STORE_PW
echo
read -r -s -p "Key password (Enter for same as store): " KEY_PW
echo
KEY_PW="${KEY_PW:-$STORE_PW}"

keytool -genkeypair -v \
  -keystore "$KEYSTORE" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storepass "$STORE_PW" \
  -keypass "$KEY_PW" \
  -dname "CN=Pagewalker, OU=Mobile, O=Pagewalker, L=Unknown, ST=Unknown, C=US"

cat > "$PROPS" <<EOF
storePassword=$STORE_PW
keyPassword=$KEY_PW
keyAlias=upload
storeFile=upload-keystore.jks
EOF
chmod 600 "$PROPS"

echo ""
echo "Created:"
echo "  $KEYSTORE"
echo "  $PROPS"
echo ""
echo "Back up both files somewhere safe (password manager + offline copy)."
echo "Play Console → App integrity → App signing will show the upload certificate SHA-1"
echo "after your first AAB upload (needed for Google Books / OAuth Android restrictions)."
