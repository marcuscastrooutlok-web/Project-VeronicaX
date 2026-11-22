#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="${1:-${RUNNER_TEMP:-/tmp}/rexglue-sdk-bd833a2}"

if [[ -e "$SDK_DIR" ]]; then
  echo "Refusing to reuse existing SDK directory: $SDK_DIR" >&2
  exit 2
fi

git clone --no-checkout https://github.com/rexglue/rexglue-sdk.git "$SDK_DIR"
git -C "$SDK_DIR" checkout --detach bd833a2

echo "Checking the pinned VeronicaX SDK patch against ReXGlue bd833a2..."
git -C "$SDK_DIR" apply --check "$ROOT/patches/rexglue-sdk-bd833a2-veronicax.patch"
git -C "$SDK_DIR" apply "$ROOT/patches/rexglue-sdk-bd833a2-veronicax.patch"

test "$(git -C "$SDK_DIR" rev-parse --short HEAD)" = "bd833a2"
git -C "$SDK_DIR" diff --check

changed_files="$(git -C "$SDK_DIR" diff --name-only)"
for expected in include/rex/system/xmemory.h src/system/xmemory.cpp src/system/xthread.cpp; do
  if ! grep -Fxq "$expected" <<<"$changed_files"; then
    echo "Expected VeronicaX patch change missing: $expected" >&2
    exit 1
  fi
done

echo "PASS: VeronicaX game patch applies cleanly to ReXGlue bd833a2."
echo "NOTE: This validates only the existing game patch, not Android/Bionic support."
