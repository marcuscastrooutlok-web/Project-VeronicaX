# Android ARM64 port — Project Veronica X

Target branch: `android-arm64`  
Desktop baseline: `master` (kept unchanged)  
Target ABI: `arm64-v8a`  
Graphics target: Vulkan (Android)

## Current source facts

- The project is generated against ReXGlue `0.10.0.24-dev.gbd833a2` (commit `bd833a2`).
- `scripts/build-rexglue.sh` builds patched desktop Linux and Windows SDKs only.
- `patches/rexglue-sdk-bd833a2-veronicax.patch` contains game-specific runtime fixes and must remain applied to the Android SDK too.
- `CMakeLists.txt` currently creates a desktop executable and calls `rexglue_setup_target(veronicax)`; it is not an Android application target.
- `src/main.cpp` registers `VeronicaxApp::Create`. The Android entry point must preserve this app/runtime registration while using SDL's Android activity/JNI lifecycle.
- `src/launcher/launcher_dialog.cpp` currently uses Win32 file dialogs on Windows and `SDL_ShowOpenFileDialog` elsewhere. Android requires a Storage Access Framework (SAF) document picker and persisted URI permissions; a filesystem path cannot be assumed for a selected document.
- The launcher extracts game files into `options_.game_dir` and validates the expected XEX fingerprint before extraction. Android storage must provide a writable app-owned destination and must preserve the same validation.
- The repository does not currently contain an Android Gradle project, Android manifest, Android CMake entry point, or Android GitHub Actions workflow.

## Porting constraints

1. Keep all desktop presets and packaging behavior intact.
2. Build the SDK from the exact `bd833a2` source revision, apply the existing VeronicaX patch, then add a separately maintained Android/Bionic/NDK patch. Do not transplant patches written for ReXGlue v0.10.0 without rebasing and checking every hunk/API.
3. Build host codegen on the Linux CI runner against the user's own `game/extracted/Default.xex`; never commit game dumps, extracted copyrighted assets, or generated game code to this public repository.
4. Build the Android runtime and Xenos GPU plugin for `arm64-v8a` with the Android NDK. Android must use Vulkan; desktop D3D12 paths must not leak into the Android target.
5. Add a Java/Kotlin activity and SDL3 glue, a native Android CMake target, Gradle packaging, and a SAF bridge for selecting ISO/GOD content. Persist read access only as required and copy/extract into app-private storage.
6. Preserve gamepad support, including Android key/controller events, and add touch controls only after the native input path is verified.
7. The CI workflow must fail clearly if the private XEX input is absent, verify the generated source manifest and both `libmain.so` and the runtime-loaded Xenos plugin in the APK, and upload an APK artifact only after those checks pass.

## Implementation sequence

- [x] Create isolated `android-arm64` branch from the desktop baseline.
- [x] Audit the current CMake, SDK pin/patch, app registration, and launcher file-access assumptions.
- [ ] Add and validate the Android/Bionic patch against ReXGlue `bd833a2`.
- [ ] Add Android native entry point, Gradle project, manifest, SDL3 Java glue, and SAF bridge.
- [ ] Add CI codegen/build pipeline with private game-input handling.
- [ ] Build and inspect the APK artifact; install/runtime testing is still required on a physical Android device.

## Important status

This document records the verified starting point and implementation requirements. It does **not** claim that Android support or an APK already exists. The Android target is not considered complete until a CI-produced APK passes packaging checks and is tested on device.
