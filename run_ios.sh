#!/bin/bash
# Run Pagewalker on iOS Simulator. Uses SSL cert so CocoaPods works.
# Usage: ./run_ios.sh
cd "$(dirname "$0")"
export SSL_CERT_FILE="$HOME/.rbenv/cacert.pem"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH="$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init -)" 2>/dev/null || true
flutter run -d "iPad Pro (12.9-inch) (6th generation)"
