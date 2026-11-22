#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="${1:-${RUNNER_TEMP:-/tmp}/rexglue-android-probe}"
REF_PATCH="${RUNNER_TEMP:-/tmp}/rexglue-reference-android.patch"
REF_REPO_COMMIT="0a79f938ab839c187d25bd7bf48e51e30a6150be"
REF_PATCH_PATH="patches/sdk/rexglue-sdk-v0.10.0-android.patch"
REF_URL="https://raw.githubusercontent.com/deivid22srk/hells-gate-recomp-android/${REF_REPO_COMMIT}/${REF_PATCH_PATH}"

if [[ -e "$SDK_DIR" ]]; then
  echo "Refusing to reuse existing SDK directory: $SDK_DIR" >&2
  exit 2
fi

git clone --no-checkout https://github.com/rexglue/rexglue-sdk.git "$SDK_DIR"
git -C "$SDK_DIR" checkout --detach bd833a2

echo "Applying the mandatory VeronicaX patch first..."
git -C "$SDK_DIR" apply "$ROOT/patches/rexglue-sdk-bd833a2-veronicax.patch"

echo "Downloading pinned Android reference patch from $REF_REPO_COMMIT..."
curl --fail --location --silent --show-error "$REF_URL" --output "$REF_PATCH"

echo "Checking reference Android patch against the already-patched bd833a2 SDK..."
if git -C "$SDK_DIR" apply --check --verbose "$REF_PATCH"; then
  echo "PASS: reference Android patch applies after the VeronicaX patch."
  echo "This is only a compatibility probe; do not treat the reference patch as production-ready."
else
  echo "::warning::Reference Android patch has conflicts against bd833a2 after the VeronicaX patch."
  echo "The diagnostics above identify files/hunks requiring a selective rebase."
  exit 1
fi
