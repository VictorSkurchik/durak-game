#!/usr/bin/env bash
set -euo pipefail

git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter_sdk
export PATH="$PWD/_flutter_sdk/bin:$PATH"

flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release --dart-define=DURAK_SERVER_URL="${DURAK_SERVER_URL:-https://durak-game-nuh4.onrender.com}"
