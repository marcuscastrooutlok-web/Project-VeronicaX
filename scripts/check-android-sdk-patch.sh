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

PINNED_SHA="$(git -C "$SDK_DIR" rev-parse 'bd833a2^{commit}')"
CHECKED_OUT_SHA="$(git -C "$SDK_DIR" rev-parse HEAD)"
if [[ "$CHECKED_OUT_SHA" != "$PINNED_SHA" ]]; then
  echo "Unexpected SDK revision: $CHECKED_OUT_SHA (expected $PINNED_SHA)" >&2
  exit 1
fi

echo "Checking the pinned VeronicaX SDK patch against ReXGlue $PINNED_SHA..."
git -C "$SDK_DIR" apply --check --verbose "$ROOT/patches/rexglue-sdk-bd833a2-veronicax.patch"
git -C "$SDK_DIR" apply "$ROOT/patches/rexglue-sdk-bd833a2-veronicax.patch"

git -C "$SDK_DIR" diff --check

changed_files="$(git -C "$SDK_DIR" diff --name-only)"
for expected in include/rex/system/xmemory.h src/system/xmemory.cpp src/system/xthread.cpp; do
  if ! grep -Fxq "$expected" <<<"$changed_files"; then
    echo "Expected VeronicaX patch change missing: $expected" >&2
    exit 1
  fi
done

echo "PASS: VeronicaX game patch applies cleanly to ReXGlue $PINNED_SHA."
echo "NOTE: This validates only the existing game patch, not Android/Bionic support."
