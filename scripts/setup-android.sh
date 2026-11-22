#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SDK_DIR="thirdparty/rexglue-sdk"
SDK_URL="https://github.com/rexglue/rexglue-sdk.git"
SDK_COMMIT="bd833a2"
if [[ -f "$SDK_DIR/.veronicax-android-patched" ]]; then
  echo "ReXGlue SDK already prepared."
  exit 0
fi
mkdir -p thirdparty
rm -rf "$SDK_DIR"
git clone "$SDK_URL" "$SDK_DIR"
git -C "$SDK_DIR" checkout "$SDK_COMMIT"
git -C "$SDK_DIR" submodule update --init --depth 1
git -C "$SDK_DIR" apply "$ROOT/patches/rexglue-sdk-bd833a2-veronicax.patch"
git -C "$SDK_DIR" apply "$ROOT/patches/rexglue-sdk-bd833a2-android.patch"
git -C "$SDK_DIR" diff --check
SDL_JAVA_SRC="$SDK_DIR/thirdparty/sdl3/android-project/app/src/main/java/org/libsdl/app"
SDL_JAVA_DST="$ROOT/android/app/src/main/java/org/libsdl/app"
if [[ ! -d "$SDL_JAVA_SRC" ]]; then
  echo "SDL3 Android Java glue not found at $SDL_JAVA_SRC" >&2
  exit 1
fi
mkdir -p "$SDL_JAVA_DST"
cp "$SDL_JAVA_SRC"/*.java "$SDL_JAVA_DST/"
touch "$SDK_DIR/.veronicax-android-patched"
echo "Android SDK prepared at $SDK_DIR (bd833a2)."
