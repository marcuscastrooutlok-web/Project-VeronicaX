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


## SDK patch compatibility review (2026-11-22)

The Android reference port's SDK patches were inspected, not copied blindly.

- Its Android patch is a 52,640-character `diff -ruN` against the upstream `v0.10.0` tree. It adds Android platform files and changes core memory/threading, SDL window/surface, and CMake selection.
- Its separate performance patch is 19,907 characters and changes memory fault handling, Vulkan command processing, logging, and interrupt dispatch. Those performance changes are not assumed safe for VeronicaX.
- The VeronicaX patch changes `include/rex/system/xmemory.h`, `src/system/xmemory.cpp`, and `src/system/xthread.cpp`. The Android reference patch also changes `src/system/xmemory.cpp`, so patch order and exact hunk compatibility must be tested; silently dropping either patch would regress game-specific memory behavior.
- The fetched upstream SDK files `src/core/CMakeLists.txt`, `src/core/memory_posix.cpp`, `src/core/threading_posix.cpp`, `src/ui/CMakeLists.txt`, and `src/system/xmemory.cpp` have identical Git blob SHAs at refs `bd833a2` and `v0.10.0`. However, the top-level `CMakeLists.txt` and `src/ui/window_sdl.cpp` differ, so the Android patch is not proven to apply cleanly to `bd833a2`.
- The Android patch also contains reference-project-specific codegen template integration (including an optional Dante's Inferno hook header); that must be removed or generalized before it can be used here.

### Decision

Do not import the reference Android or performance patches as-is. The next SDK task is to derive a VeronicaX-specific Android patch from the platform-only changes, retain the existing VeronicaX memory/thread fixes, then validate both patches against a clean `bd833a2` checkout with `git apply --check` before any Android build is attempted.


## Android patch source-file inventory (2026-11-22)

The reference Android patch was enumerated by changed path. This is an inventory for selective porting, not an endorsement to copy the patch wholesale.

- Build/platform selection: `CMakeLists.txt`, `src/core/CMakeLists.txt`, `src/ui/CMakeLists.txt`, `thirdparty/CMakeLists.txt`.
- Android-only additions: `include/rex/main_android.h`, `include/rex/ui/surface_android.h`, `src/core/android_runtime.cpp`, `src/core/ucontext_android.cpp`, `src/ui/surface_android.cpp`.
- POSIX/Bionic compatibility: `include/rex/chrono/chrono.h`, `include/rex/string/numeric.h`, `include/rex/thread/jthread_compat.h`, `src/core/fiber_posix.cpp`, `src/core/filesystem_posix.cpp`, `src/core/logging.cpp`, `src/core/memory_posix.cpp`, `src/core/threading_posix.cpp`, `src/core/timer_queue.cpp`.
- Runtime and code-generation integration: `resources/templates/codegen/pch_h.inja`, `src/codegen/builders/system.cpp`, `src/ui/window_sdl.cpp`, `src/system/xmemory.cpp`.

### Required treatment for VeronicaX

- Preserve `patches/rexglue-sdk-bd833a2-veronicax.patch` as a separate, mandatory game patch. Its changes to `src/system/xmemory.cpp` overlap the Android patch's changes to that same file; a merged result must retain both the Android physical-memory offset handling and VeronicaX's GPU-data invalidation logic.
- The Android runtime, ucontext, surface, and Bionic compatibility files are candidates for porting, but their APIs and build conditions must be checked against the pinned `bd833a2` checkout.
- The codegen template and builder edits must be reviewed for hard-coded reference-game hooks. No Dante's Inferno header, manifest, XEX, or generated code belongs in this repository.
- The CMake and SDL window changes need a rebase against the actual `bd833a2` files; identical hashes in selected POSIX/core files do not establish whole-patch compatibility.

### Validation gate

Do not start the Android APK workflow until a repository-owned Android patch series exists and a clean CI job has demonstrated, in order: (1) checkout of SDK commit `bd833a2`; (2) successful application of the VeronicaX patch; (3) successful application of the derived Android patch; and (4) a clean configure/build of the Android SDK. A failed hunk is a stop condition, not a reason to skip or force-apply the game patch.


## VeronicaX SDK patch baseline validation (2026-11-22)

- GitHub Actions run [#4](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45034789630) completed successfully on branch `android-arm64`.
- The job checked out ReXGlue ref `bd833a2`, verified the exact resolved commit SHA, ran `git apply --check` and applied `patches/rexglue-sdk-bd833a2-veronicax.patch`.
- `git diff --check` passed, and the validation confirmed that all three expected game-specific files changed: `include/rex/system/xmemory.h`, `src/system/xmemory.cpp`, and `src/system/xthread.cpp`.
- The earlier failures were caused by the check script comparing the 8-character abbreviated revision returned by Git against the 7-character string `bd833a2`; the patch itself was applying. The script now compares the full resolved commit SHA to the checked-out HEAD.
- This is only a successful baseline/game-patch validation. It does **not** validate Android/Bionic changes, configure or compile the SDK, or produce an APK.

### Current verified gate

- [x] Existing VeronicaX game patch applies cleanly to the pinned ReXGlue `bd833a2` revision.
- [ ] Derive and validate the separate Android/Bionic patch while preserving the VeronicaX changes.
- [ ] Configure and build the patched Android SDK before adding the app/APK pipeline.
