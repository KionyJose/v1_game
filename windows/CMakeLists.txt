# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(v1_game LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "v1_game")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)
if(POLICY CMP0175)
  # Some Flutter plugins still call add_custom_command(TARGET ...) without an
  # explicit PRE_BUILD/PRE_LINK/POST_BUILD. Keep CMake's compatibility behavior
  # for third-party plugin subdirectories until those plugins update upstream.
  set(CMAKE_POLICY_DEFAULT_CMP0175 OLD)
endif()

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
find_program(NUGET nuget)
if(NOT NUGET)
  set(V1_NUGET_PATH "${CMAKE_BINARY_DIR}/tools/nuget.exe")
  file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/tools")
  if(NOT EXISTS "${V1_NUGET_PATH}")
    file(DOWNLOAD
      "https://dist.nuget.org/win-x86-commandline/v6.12.1/nuget.exe"
      "${V1_NUGET_PATH}"
      TLS_VERIFY ON STATUS V1_NUGET_STATUS)
    list(GET V1_NUGET_STATUS 0 V1_NUGET_ERROR)
    if(NOT V1_NUGET_ERROR EQUAL 0)
      file(REMOVE "${V1_NUGET_PATH}")
      message(FATAL_ERROR "Não foi possível obter NuGet para WebView2: ${V1_NUGET_STATUS}")
    endif()
  endif()
  set(NUGET "${V1_NUGET_PATH}" CACHE FILEPATH "NuGet usado pelo WebView2" FORCE)
endif()
include(flutter/generated_plugins.cmake)

if(MSVC AND TARGET flutter_inappwebview_windows_plugin)
  # WebView2 currently uses /await and the experimental coroutine headers.
  # Allow this plugin to compile with newer MSVC versions until it migrates.
  target_compile_definitions(flutter_inappwebview_windows_plugin PRIVATE
    _SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS
  )
  # Serialize writes to the plugin's debug symbol database during compilation.
  target_compile_options(flutter_inappwebview_windows_plugin PRIVATE /FS)
endif()

if(TARGET flutter_soloud_plugin)
  target_compile_options(flutter_soloud_plugin PRIVATE
    /wd4018 # signed/unsigned mismatch
    /wd4189 # local variable initialized but not referenced
    /wd4244 # conversion: possible loss of data
    /wd4245 # signed/unsigned mismatch
    /wd4267 # size_t conversion
    /wd4305 # truncation
    /wd4389 # signed/unsigned mismatch
    /wd4456 # declaration hides previous local declaration
    /wd4457 # declaration hides function parameter
    /wd4458 # declaration hides class member
    /wd4459 # declaration hides global declaration
    /wd4701 # potentially uninitialized local variable
    /wd4996 # deprecated POSIX name
  )
endif()

if(TARGET permission_handler_windows_plugin)
  target_compile_definitions(permission_handler_windows_plugin PRIVATE
    _SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS
  )
endif()


# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)
