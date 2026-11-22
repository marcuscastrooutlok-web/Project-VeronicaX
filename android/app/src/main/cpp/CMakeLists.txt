cmake_minimum_required(VERSION 3.25)
project(veronicax_android LANGUAGES C CXX ASM)

if(NOT DEFINED REX_PROJECT_ROOT)
  get_filename_component(REX_PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../../.." ABSOLUTE)
endif()
set(REXSDK_DIR "${REX_PROJECT_ROOT}/thirdparty/rexglue-sdk" CACHE PATH "Patched ReXGlue SDK")
set(REX_GEN_DIR "${REX_PROJECT_ROOT}/generated/default")

if(NOT EXISTS "${REXSDK_DIR}/CMakeLists.txt")
  message(FATAL_ERROR "Patched ReXGlue SDK missing. Run scripts/setup-android.sh.")
endif()
if(NOT EXISTS "${REX_GEN_DIR}/sources.cmake")
  message(FATAL_ERROR "generated/default/sources.cmake missing. Host code generation from your own Default.xex is required.")
endif()

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(REXGLUE_ENABLE_TRACY OFF CACHE BOOL "" FORCE)
set(REXGLUE_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(REXGLUE_USE_VULKAN ON CACHE BOOL "" FORCE)
set(REXGLUE_USE_D3D12 OFF CACHE BOOL "" FORCE)
set(REXGLUE_ENABLE_DESKTOP_SDL_BACKENDS OFF CACHE BOOL "" FORCE)

add_subdirectory("${REXSDK_DIR}" rexglue-sdk)

include("${REX_GEN_DIR}/sources.cmake")
set(REX_GEN_SOURCES "")
foreach(src IN LISTS GENERATED_SOURCES)
  if(IS_ABSOLUTE "${src}")
    list(APPEND REX_GEN_SOURCES "${src}")
  else()
    list(APPEND REX_GEN_SOURCES "${REX_GEN_DIR}/${src}")
  endif()
endforeach()

add_library(recomp STATIC ${REX_GEN_SOURCES})
target_include_directories(recomp PRIVATE
  "${REX_PROJECT_ROOT}" "${REX_PROJECT_ROOT}/src" "${REX_GEN_DIR}")
if(EXISTS "${REX_GEN_DIR}/veronicax_pch.h")
  target_precompile_headers(recomp PRIVATE "${REX_GEN_DIR}/veronicax_pch.h")
endif()
target_compile_options(recomp PRIVATE -Wno-unused-variable)
target_link_libraries(recomp PUBLIC rex::runtime rexui)

add_library(main SHARED
  android_main.cpp
  "${REX_PROJECT_ROOT}/src/main.cpp"
  "${REX_PROJECT_ROOT}/src/game_hooks.cpp"
  "${REX_PROJECT_ROOT}/src/launcher/launcher_dialog.cpp"
  "${REX_PROJECT_ROOT}/src/launcher/xdvdfs.cpp"
  "${REXSDK_DIR}/src/ui/rex_app.cpp")
target_include_directories(main PRIVATE
  "${REX_PROJECT_ROOT}" "${REX_PROJECT_ROOT}/src" "${REX_GEN_DIR}"
  "${REXSDK_DIR}/include" "${REXSDK_DIR}/src/ui")
target_compile_definitions(main PRIVATE REXGLUE_BUILD_CONFIG="$<CONFIG>")
target_compile_options(main PRIVATE -Wno-unused-variable)
target_link_libraries(main PRIVATE recomp rex::runtime rexui)
target_link_options(main PRIVATE -Wl,--export-dynamic)
add_dependencies(main rexgpu-xenos)
set_target_properties(main PROPERTIES CXX_VISIBILITY_PRESET default VISIBILITY_INLINES_HIDDEN OFF)
