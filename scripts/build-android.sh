#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
VARIANT="${1:-debug}"

./scripts/setup-android.sh
if [[ ! -f generated/default/sources.cmake ]]; then
  echo "Android APK build blocked: generated/default/sources.cmake is missing." >&2
  echo "Run host ReXGlue codegen using your own game/extracted/Default.xex first." >&2
  exit 2
fi
if ! command -v gradle >/dev/null 2>&1; then
  echo "Gradle 8.9+ is required (Android Gradle Plugin 8.7.3)." >&2
  exit 2
fi
gradle -p android "assemble${VARIANT^}" --no-daemon --stacktrace
APK="android/app/build/outputs/apk/$VARIANT/app-$VARIANT.apk"
test -s "$APK"
unzip -l "$APK" | grep -q 'lib/arm64-v8a/libmain.so'
unzip -l "$APK" | grep -Eq 'lib/arm64-v8a/librexgpu-xenos.*\.so'
echo "APK verified: $APK"
