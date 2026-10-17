#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Cloudflare build machines do not include Flutter. Use the pinned SDK there.
if ! command -v flutter >/dev/null 2>&1; then
  sdk_dir="${FLUTTER_SDK_DIR:-$PWD/.cache/flutter}"
  flutter_version="$(tr -d '[:space:]' < .flutter-version)"
  if [ ! -x "$sdk_dir/bin/flutter" ]; then
    mkdir -p "$(dirname "$sdk_dir")"
    git clone --depth 1 --branch "$flutter_version" https://github.com/flutter/flutter.git "$sdk_dir"
  fi
  export PATH="$sdk_dir/bin:$PATH"
fi
flutter pub get --enforce-lockfile
flutter build web --release --no-web-resources-cdn
