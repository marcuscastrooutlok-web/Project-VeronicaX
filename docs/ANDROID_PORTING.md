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


## Android reference patch compatibility probe (2026-11-22)

A CI probe now tests the pinned Android reference patch from `deivid22srk/hells-gate-recomp-android` commit `0a79f938ab839c187d25bd7bf48e51e30a6150be` against ReXGlue `bd833a2`, **after** applying the mandatory VeronicaX patch.

- Probe workflow: [run #45034987859](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45034987859).
- The VeronicaX patch step passed before the Android compatibility probe.
- Most Android patch hunks passed the apply check, including the Android runtime/platform files and the overlapping `src/system/xmemory.cpp` hunks. The latter is important: the reference memory-offset changes can coexist at the patch-context level with the VeronicaX GPU invalidation patch.
- Three source files have incompatible context and require selective rebase against `bd833a2`:
  - top-level `CMakeLists.txt` (patch context around compiler options/platform detection);
  - `src/codegen/builders/system.cpp` (system barrier builder context);
  - `src/core/logging.cpp` (global logging state/context).
- The reference patch must not be force-applied. Rebase these three files manually, retain only required Android behavior, then create a repository-owned Android patch pinned to `bd833a2`.
- The reference patch is fetched at a fixed upstream commit by `scripts/probe-android-patch-compat.sh`; this script is diagnostic only and does not modify the SDK checkout or produce a distributable patch.

### Updated next gate

1. Rebase the three conflicting files against the pinned SDK, while preserving all compatible Android hunks.
2. Generate a clean repository-owned Android patch.
3. In CI, apply VeronicaX patch first and the derived Android patch second; run `git diff --check` and verify all expected Android files.
4. Only then configure and compile the Android SDK.


## Android patch rebased for the VeronicaX SDK pin (2026-11-22)

A repository-owned Android patch was derived from the reference Android implementation and rebased onto ReXGlue `bd833a2`, with the VeronicaX game patch applied first.

- Patch: `patches/rexglue-sdk-bd833a2-android.patch`.
- Probe script: `scripts/probe-android-patch-compat.sh`.
- CI run confirming clean applicability: [run #45036072235](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45036072235).
- The exact three previously conflicting files were selectively rebased:
  - `CMakeLists.txt`: Android arm64 platform selection is inserted before the generic UNIX branch; the reference's x86-only compiler-flag change was not carried into the Android branch.
  - `src/codegen/builders/system.cpp`: emits the three PPC barrier macros provided by the Android codegen precompiled-header template; this preserves the Android reference's ARM64 memory-ordering behavior on the pinned SDK, whose baseline already contains native fence generation.
  - `src/core/logging.cpp`: adds an Android logcat sink, uses the generic `ReXGlue` tag (not the reference game's Dante's Inferno tag), and retains the early sink for Android app diagnostics.
- CI confirmed the VeronicaX patch applies first, then the Android patch passes `git apply --check`. The probe was strengthened to apply the Android patch, run `git diff --check`, and verify key Android runtime source files exist.
- All other Android patch hunks checked cleanly, including the overlapping `src/system/xmemory.cpp` hunks after the VeronicaX patch.

**Important scope:** this is a clean patch-application result, not yet a successful Android SDK compile. The next gate is to run the Android NDK/CMake configure and compile against the pinned SDK and its submodules. No APK has been built.


### Patch-application gate strengthened

The probe now applies the rebased Android patch after the VeronicaX patch (not just `--check`), runs `git diff --check`, and verifies the Android runtime headers/sources. The strengthened check passed in [run #45036122669](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45036122669).

### Android SDK compile gate started

- Added `scripts/check-android-sdk-build.sh` to clone the exact SDK pin, initialize its submodules, apply both patches in order, configure the NDK toolchain for `arm64-v8a`, and compile the SDK with Vulkan.
- Added workflow `.github/workflows/android-sdk-build-check.yml`.
- First workflow attempt (#45036261967) stopped during Android SDK setup because the setup action requested the obsolete SDK package `tools`, which is no longer available in the repository.
- The workflow was changed to use the runner's preinstalled Android SDK Manager directly and install NDK 27.2.12479018 plus CMake 3.31.1. Retry: [run #45036352816](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45036352816).
- The retry is not yet confirmed as a compile pass. Do not mark the SDK build gate complete until its CMake configure and native compilation steps finish successfully.


- The direct-SDK-manager retry #45036352816 also stopped before CMake: the workflow's `yes | sdkmanager --licenses` pipeline inherited Bash `pipefail` and returned failure when the license process closed its input. The workflow now disables `pipefail` only around license acceptance, then restores it before package installation.
- Android SDK build [run #45036455268](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45036455268) completed successfully on 2026-11-22. All workflow steps passed, including Android NDK/CMake installation, CMake configuration, and native compilation of ReXGlue for `arm64-v8a` with Vulkan.
- The successful run used repository commit `e079ef230a17484727bf4f5048e9c7d80a84ff9d` and SDK pin `bd833a2`, applying the VeronicaX patch first and the Android patch second.
- [x] Configure and compile the patched ReXGlue SDK for Android `arm64-v8a`.
- [x] Add the initial Android Gradle application structure, Android manifest, SDLActivity bridge, SAF folder-selection screen, native entry point, and ARM64/Vulkan CMake target.
- [x] Add `scripts/setup-android.sh` to reproduce the exact SDK checkout (`bd833a2)), initialize its submodules, apply the VeronicaX patch followed by the Android patch, and stage SDL3 Java glue.
- [x] Add `scripts/build-android.sh` with explicit generated-code precondition and APK checks for `libmain.so` plus the Xenos Vulkan plugin.
- [ ] Validate the Android app CMake/Gradle integration with real generated code. The current project still has no Android APK build result.
- [ ] Add a private CI input for the user's own `game/extracted/Default.xex`, run host-side ReXGlue code generation, and build the APK without publishing game files.
- [ ] Inspect the APK and test startup, rendering, audio, and controller input on the Motorola Edge 30 Pro.


## Android application scaffold (2026-11-22)

The first Android application layer is now present on `android-arm64`:

- Gradle project: `android/settings.gradle.kts`, `android/build.gradle.kts`, `android/gradle.properties`, and `android/app/build.gradle.kts`.
- Manifest: `android/app/src/main/AndroidManifest.xml`; package/application ID `org.veronicax.android`; ARM64 only, Vulkan feature requirement, Android API 28 minimum.
- Setup screen: `android/app/src/main/java/org/veronicax/android/SetupActivity.java`. It requests Android's all-files access where needed, opens the Storage Access Framework folder picker, resolves primary shared-storage paths, validates `Default.xex`, and writes `game_root.txt` in the app's external files directory.
- SDL activity bridge: `android/app/src/main/java/org/veronicax/android/MainActivity.java`; loads the statically linked SDL3 application library `main` and exposes the `openContentFd` JNI bridge required by the SDK.
- Native entry point: `android/app/src/main/cpp/android_main.cpp`; initializes Android runtime glue, resolves the app-private external files directory and game root, and launches the registered `veronicax` application.
- Android native CMake: `android/app/src/main/cpp/CMakeLists.txt`; compiles the generated guest code, VeronicaX application sources, ReXGlue runtime and Xenos GPU plugin for `arm64-v8a` with Vulkan.
- Reproducible SDK setup: `scripts/setup-android.sh`; APK packaging gate: `scripts/build-android.sh`.

The folder picker currently resolves the primary shared-storage volume path. It does not copy the user's game files into the repository or APK. The SDK setup script downloads the pinned SDK and SDL3 Java glue during CI/local setup; those generated third-party files are not committed.

**Remaining gate:** the app scaffold has not yet been compiled as an Android app. Host-side code generation still requires the user's own `Default.xex` at `game/extracted/Default.xex`. No APK is claimed at this stage.
