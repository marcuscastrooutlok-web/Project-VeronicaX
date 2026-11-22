#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="${RUNNER_TEMP:-/tmp}/rexglue-sdk-android-build"
BUILD_DIR="${RUNNER_TEMP:-/tmp}/rexglue-android-build"
NDK_DIR="${ANDROID_NDK_HOME:-${ANDROID_HOME:-}/ndk/27.2.12479018}"
CMAKE_BIN="${ANDROID_HOME:-}/cmake/3.31.1/bin/cmake"

if [[ ! -x "${NDK_DIR}/build/cmake/android.toolchain.cmake" ]]; then
  echo "Android NDK 27.2.12479018 not found at ${NDK_DIR}" >&2
  exit 2
fi
if [[ ! -x "${CMAKE_BIN}" ]]; then
  echo "CMake 3.31.1 not found at ${CMAKE_BIN}" >&2
  exit 2
fi

git clone --no-checkout https://github.com/rexglue/rexglue-sdk.git "${SDK_DIR}"
git -C "${SDK_DIR}" checkout --detach bd833a2
git -C "${SDK_DIR}" submodule update --init --depth 1

echo "Checking and applying VeronicaX patch..."
git -C "${SDK_DIR}" apply --check "${ROOT}/patches/rexglue-sdk-bd833a2-veronicax.patch"
git -C "${SDK_DIR}" apply "${ROOT}/patches/rexglue-sdk-bd833a2-veronicax.patch"

echo "Checking and applying Android/Bionic patch..."
git -C "${SDK_DIR}" apply --check "${ROOT}/patches/rexglue-sdk-bd833a2-android.patch"
git -C "${SDK_DIR}" apply "${ROOT}/patches/rexglue-sdk-bd833a2-android.patch"
git -C "${SDK_DIR}" diff --check

echo "Configuring ReXGlue for Android arm64-v8a..."
"${CMAKE_BIN}" -S "${SDK_DIR}" -B "${BUILD_DIR}" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="${NDK_DIR}/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-28 \
  -DANDROID_STL=c++_shared \
  -DCMAKE_BUILD_TYPE=Release \
  -DREXGLUE_ENABLE_TRACY=OFF \
  -DREXGLUE_BUILD_TESTS=OFF \
  -DREXGLUE_USE_VULKAN=ON \
  -DREXGLUE_USE_D3D12=OFF \
  -DREXGLUE_ENABLE_DESKTOP_SDL_BACKENDS=OFF

echo "Compiling the complete patched ReXGlue SDK for Android arm64-v8a..."
"${CMAKE_BIN}" --build "${BUILD_DIR}" --parallel 2
echo "PASS: patched ReXGlue SDK compiled for Android arm64-v8a."
