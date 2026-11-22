#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="${1:-${RUNNER_TEMP:-/tmp}/rexglue-android-probe}"
ANDROID_PATCH="${RUNNER_TEMP:-/tmp}/rexglue-veronicax-android.patch"
ANDROID_PATCH_COMMIT="a3ab2855091d2879c02672f838bddf67c8f6c95a"
ANDROID_PATCH_URL="https://raw.githubusercontent.com/marcuscastrooutlok-web/Project-VeronicaX/${ANDROID_PATCH_COMMIT}/patches/rexglue-sdk-bd833a2-android.patch"

if [[ -e "$SDK_DIR" ]]; then
  echo "Refusing to reuse existing SDK directory: $SDK_DIR" >&2
  exit 2
fi

git clone --no-checkout https://github.com/rexglue/rexglue-sdk.git "$SDK_DIR"
git -C "$SDK_DIR" checkout --detach bd833a2

echo "Applying the mandatory VeronicaX patch first..."
git -C "$SDK_DIR" apply "$ROOT/patches/rexglue-sdk-bd833a2-veronicax.patch"

echo "Downloading repository-owned Android patch from $ANDROID_PATCH_COMMIT..."
curl --fail --location --silent --show-error "$ANDROID_PATCH_URL" --output "$ANDROID_PATCH"

echo "Checking rebased Android patch against the already-patched bd833a2 SDK..."
if git -C "$SDK_DIR" apply --check --verbose "$ANDROID_PATCH"; then
  echo "PASS: repository-owned Android patch applies after the VeronicaX patch."
else
  echo "::warning::Repository-owned Android patch still has conflicts against bd833a2 after the VeronicaX patch."
  echo "The diagnostics above identify files/hunks requiring a selective rebase."
  exit 1
fi
