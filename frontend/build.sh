#!/bin/bash
set -e

git clone --depth 1 -b stable https://github.com/flutter/flutter.git /tmp/flutter

export PATH="/tmp/flutter/bin:$PATH"

flutter doctor
flutter pub get

flutter build web --release \
  --dart-define=API_BASE_URL=https://bookora-backend-d4dj.onrender.com
