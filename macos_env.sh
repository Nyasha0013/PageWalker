#!/bin/bash
# Use this so CocoaPods (Ruby) can verify HTTPS. Run from project root:
#   source macos_env.sh
#   flutter run -d macos
export SSL_CERT_FILE="${HOME}/.rbenv/cacert.pem"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH="${HOME}/.rbenv/shims:${PATH}"
eval "$(rbenv init -)" 2>/dev/null || true
