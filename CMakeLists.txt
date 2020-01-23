# Copyright (c) 2007-2019 Hartmut Kaiser
# Copyright (c) 2011-2014 Thomas Heller
# Copyright (c) 2007-2008 Chirag Dekate
# Copyright (c)      2011 Bryce Lelbach
# Copyright (c)      2011 Vinay C Amatya
# Copyright (c)      2013 Jeroen Habraken
# Copyright (c) 2014-2016 Andreas Schaefer
# Copyright (c) 2017      Abhimanyu Rawat
# Copyright (c) 2017      Google
# Copyright (c) 2017      Taeguk Kwon
#
# SPDX-License-Identifier: BSL-1.0
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

# We require at least CMake V3.6.3
cmake_minimum_required(VERSION 3.6.3 FATAL_ERROR)

if (HPX_WITH_CUDA AND CMAKE_VERSION VERSION_LESS 3.9)
  message(FATAL_ERROR "CUDA support requires at least CMake 3.9.")
endif()

# Overrides must go before the project() statement, otherwise they are ignored.

################################################################################
# C++ overrides
################################################################################
set(CMAKE_USER_MAKE_RULES_OVERRIDE_CXX
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/HPX_CXXOverrides.cmake")

################################################################################
# Fortran overrides
################################################################################
set(CMAKE_USER_MAKE_RULES_OVERRIDE_Fortran
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/HPX_FortranOverrides.cmake")

################################################################################
# Build type (needs to be handled before project command below)
################################################################################
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Configuration type (one of Debug, RelWithDebInfo, Release, MinSizeRel)" FORCE)
endif()

################################################################################
# project metadata
################################################################################
project(HPX CXX C)

set(HPX_VERSION_MAJOR 1)
set(HPX_VERSION_MINOR 4)
set(HPX_VERSION_SUBMINOR 0)
set(HPX_VERSION_DATE 20200115)
set(HPX_VERSION_TAG "")

set(HPX_VERSION "${HPX_VERSION_MAJOR}.${HPX_VERSION_MINOR}.${HPX_VERSION_SUBMINOR}")
set(HPX_LIBRARY_VERSION "${HPX_VERSION}")
set(HPX_SOVERSION ${HPX_VERSION_MAJOR})
set(HPX_PACKAGE_NAME HPX)
# To keep track of the hpx_root when other subprojects are declared
set(HPX_SOURCE_DIR "${PROJECT_SOURCE_DIR}")
set(HPX_BINARY_DIR "${PROJECT_BINARY_DIR}")

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

################################################################################
# CMake configuration
################################################################################
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${PROJECT_SOURCE_DIR}/cmake")

# To fix the windows link bug (need to be included only once!)
include(HPX_FilterLibrariesMSVC)

include(GNUInstallDirs)
include(HPX_Utils)

# explicitly set certain policies
cmake_policy(VERSION 3.6.3)
hpx_set_cmake_policy(CMP0042 NEW)
if(${CMAKE_VERSION} VERSION_LESS "3.11.0")
  # the old behavior not supported for newer cmake versions anymore
  hpx_set_cmake_policy(CMP0054 OLD)
endif()
hpx_set_cmake_policy(CMP0060 NEW)

# If we have a cmake version older than 3.12, we can't rely on CONFIGURE_DEPENDS
if(${CMAKE_VERSION} VERSION_LESS "3.12")
  set(DO_CONFIGURE_DEPENDS)
else()
  set(DO_CONFIGURE_DEPENDS CONFIGURE_DEPENDS)
endif()

# We save the passed compiler flag to a special variable. This is needed for our
# build system unit tests. Some flags might influence the created symbols
# (_GLIBCXX_DEBUG i look at you)
set(CMAKE_CXX_FLAGS_SAFE ${CMAKE_CXX_FLAGS})

include(CheckCXXCompilerFlag)
include(CMakeDependentOption)

# include additional macro definitions
include(HPX_AddConfigTest)
include(HPX_AddDefinitions)
include(HPX_CreateSymbolicLink)

hpx_force_out_of_tree_build("This project requires an out-of-source-tree build. See README.rst. Clean your CMake cache and CMakeFiles if this message persists.")

if(NOT HPX_CMAKE_LOGLEVEL)
  set(HPX_CMAKE_LOGLEVEL "WARN")
endif()

# print initial diagnostics
hpx_info("CMake version: ${CMAKE_VERSION}")
hpx_info("HPX version: ${HPX_VERSION}")

################################################################################
# reset cached variables that need to be re-filled
unset(HPX_COMPONENTS CACHE)
unset(HPX_EXPORT_TARGETS CACHE)
unset(HPX_EXPORT_MODULES_TARGETS CACHE)
unset(HPX_LIBS CACHE)
unset(HPX_STATIC_PARCELPORT_PLUGINS CACHE)

################################################################################
# Fortran compiler detection
#
hpx_option(HPX_WITH_FORTRAN
        BOOL
        "Enable or disable the compilation of Fortran examples using HPX"
        OFF ADVANCED)

if (HPX_WITH_FORTRAN)
  include(HPX_FortranCompiler)
endif()

################################################################################

################################################################################
# Setup platform for which HPX should be compiled for.
#
include(HPX_SetPlatform)
if("${HPX_PLATFORM_UC}" STREQUAL "ANDROID")
  unset(HPX_LIBRARY_VERSION)
  unset(HPX_SOVERSION)
endif()

# Adjust a couple of build-system settings, if HPX is to be built using vcpkg
if(MSVC)
  set(_with_vcpkg_default OFF)
  if(VCPKG_TOOLCHAIN)
    set(_with_vcpkg_default ON)
  endif()
  hpx_option(HPX_WITH_VCPKG BOOL
          "Build HPX in the context of the vcpkg build and configuration tool (default: OFF)."
          ${_with_vcpkg_default} ADVANCED)
  if(HPX_WITH_VCPKG)
    hpx_add_config_define(HPX_HAVE_VCPKG)
  endif()

  hpx_option(HPX_WITH_VS_STARTUP_PROJECT STRING
          "Define the startup project for the HPX solution (default: ALL_BUILD)."
          "ALL_BUILD" ADVANCED)
  if(HPX_WITH_VS_STARTUP_PROJECT)
    set(VS_STARTUP_PROJECT ${HPX_WITH_VS_STARTUP_PROJECT})
  endif()
endif()

################################################################################

################################################################################
# Set our build options cache variables which are customizable by users
#

hpx_option(HPX_WITH_DEPRECATION_WARNINGS
        BOOL "Enable warnings for deprecated facilities. (default: ON)"
        ON ADVANCED)
if(HPX_WITH_DEPRECATION_WARNINGS)
  hpx_add_config_define(HPX_HAVE_DEPRECATION_WARNINGS)
endif()

## Generic build options
set(DEFAULT_MALLOC "system")
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
  set(DEFAULT_MALLOC "tcmalloc")
endif()

if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
  set(HPX_WITH_STACKOVERFLOW_DETECTION_DEFAULT OFF)
  string(TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE_UC)
  if("${CMAKE_BUILD_TYPE_UC}" STREQUAL "DEBUG")
    set(HPX_WITH_STACKOVERFLOW_DETECTION_DEFAULT ON)
  endif()
  hpx_option(HPX_WITH_STACKOVERFLOW_DETECTION
          BOOL
          "Enable stackoverflow detection for HPX threads/coroutines. (default: OFF, debug: ON)"
          ${HPX_WITH_STACKOVERFLOW_DETECTION_DEFAULT} ADVANCED)
  if(HPX_WITH_STACKOVERFLOW_DETECTION)
    hpx_add_config_define(HPX_HAVE_STACKOVERFLOW_DETECTION)
  endif()
endif()

hpx_option(HPX_WITH_MALLOC
        STRING
        "Define which allocator should be linked in. Options are: system, tcmalloc, jemalloc, mimalloc, tbbmalloc, and custom (default is: tcmalloc)"
        ${DEFAULT_MALLOC}
        STRINGS "system;tcmalloc;jemalloc;mimalloc;tbbmalloc;custom")

# On some systems jemalloc requires an explicit prefix for the API functions
# (i.e. 'malloc' is called 'je_malloc', etc.)
if(${HPX_WITH_MALLOC} STREQUAL "jemalloc")
  if(MSVC)
    set(HPX_WITH_JEMALLOC_PREFIX_DEFAULT "je_")
  else()
    set(HPX_WITH_JEMALLOC_PREFIX_DEFAULT "<none>")
  endif()
  hpx_option(HPX_WITH_JEMALLOC_PREFIX
          STRING
          "Optional naming prefix for jemalloc API functions"
          ${HPX_WITH_JEMALLOC_PREFIX_DEFAULT}
          ADVANCED)
endif()

# Logging configuration
hpx_option(HPX_WITH_LOGGING BOOL
        "Build HPX with logging enabled (default: ON)."
        ON ADVANCED)

hpx_option(HPX_WITH_FAULT_TOLERANCE BOOL
        "Build HPX to tolerate failures of nodes, i.e. ignore errors in active communication channels (default: OFF)"
        OFF ADVANCED)
if(HPX_WITH_FAULT_TOLERANCE)
  hpx_add_config_define(HPX_HAVE_FAULT_TOLERANCE)
endif()

if(HPX_WITH_LOGGING)
  hpx_add_config_define(HPX_HAVE_LOGGING)
endif()

## Compiler related build options
hpx_option(HPX_WITH_GCC_VERSION_CHECK BOOL
        "Don't ignore version reported by gcc (default: ON)"
        ON ADVANCED)

hpx_option(HPX_WITH_DEFAULT_TARGETS BOOL
        "Associate the core HPX library with the default build target (default: ON)."
        ON ADVANCED CATEGORY "Build Targets")

hpx_option(HPX_WITH_COMPILER_WARNINGS BOOL
        "Enable compiler warnings (default: ON)"
        ON ADVANCED)

hpx_option(HPX_WITH_COMPILER_WARNINGS_AS_ERRORS BOOL
        "Turn compiler warnings into errors (default: OFF)"
        OFF ADVANCED)

hpx_option(HPX_WITH_EXECUTABLE_PREFIX STRING
        "Executable prefix (default none), 'hpx_' useful for system install."
        "" CATEGORY "Build Targets")

hpx_option(HPX_WITH_DOCUMENTATION BOOL
        "Build the HPX documentation (default OFF)."
        OFF CATEGORY "Build Targets")

if(HPX_WITH_DOCUMENTATION)
  set(valid_output_formats html singlehtml latexpdf man)
  hpx_option(HPX_WITH_DOCUMENTATION_OUTPUT_FORMATS STRING
          "List of documentation output formats to generate. Valid options are ${valid_output_formats}. Multiple values can be separated with semicolons. (default html)."
          "html" CATEGORY "Build Targets")

  foreach(output_format ${HPX_WITH_DOCUMENTATION_OUTPUT_FORMATS})
    if(NOT ${output_format} IN_LIST valid_output_formats)
      hpx_error("${output_format} is not a valid value for HPX_WITH_DOCUMENTATION_OUTPUT_FORMATS. Valid output format are: ${valid_output_formats}.")
    endif()
  endforeach()
endif()

if(MSVC)
  hpx_option(HPX_WITH_PSEUDO_DEPENDENCIES BOOL
          "Force creating pseudo targets and pseudo dependencies (default OFF)."
          OFF CATEGORY "Build Targets")
else()
  hpx_option(HPX_WITH_PSEUDO_DEPENDENCIES BOOL
          "Force creating pseudo targets and pseudo dependencies (default ON)."
          ON CATEGORY "Build Targets")
endif()

hpx_option(HPX_WITH_DYNAMIC_HPX_MAIN BOOL
        "Enable dynamic overload of system ``main()`` (Linux only, default: ON)"
        ON ADVANCED)
if(HPX_WITH_DYNAMIC_HPX_MAIN)
  hpx_add_config_cond_define(HPX_HAVE_DYNAMIC_HPX_MAIN 1)
endif()

################################################################################
# Some platforms do not support dynamic linking. Enable this to link all
# libraries statically. This also changes some of the internals of HPX related
# to how components are loaded.
################################################################################
hpx_option(HPX_WITH_STATIC_LINKING BOOL
        "Compile HPX statically linked libraries (Default: OFF)" OFF ADVANCED)
if(HPX_WITH_STATIC_LINKING)
  hpx_add_config_define(HPX_HAVE_STATIC_LINKING)
  set(hpx_library_link_mode STATIC)
  set(CMAKE_SHARED_LIBS OFF)
  set(CMAKE_FIND_LIBRARY_SUFFIXES .a ${CMAKE_FIND_LIBRARY_SUFFIXES})

  if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    hpx_option(HPX_WITH_STATIC_EXE_LINKING BOOL
            "Compile HPX statically linked executables (Default: OFF)" OFF ADVANCED)

    if(HPX_WITH_STATIC_EXE_LINKING)
      set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
    endif()
  endif()
else()
  set(hpx_library_link_mode SHARED)
endif()

################################################################################

hpx_option(HPX_WITH_EXAMPLES BOOL "Build the HPX examples (default ON)" ON CATEGORY "Build Targets")
hpx_option(HPX_WITH_TESTS BOOL "Build the HPX tests (default ON)" ON CATEGORY "Build Targets")
hpx_option(HPX_WITH_TESTS_BENCHMARKS BOOL "Build HPX benchmark tests (default: ON)" ON ADVANCED CATEGORY "Build Targets")
hpx_option(HPX_WITH_TESTS_REGRESSIONS BOOL "Build HPX regression tests (default: ON)" ON ADVANCED CATEGORY "Build Targets")
hpx_option(HPX_WITH_TESTS_UNIT BOOL "Build HPX unit tests (default: ON)" ON ADVANCED CATEGORY "Build Targets")
hpx_option(HPX_WITH_TESTS_HEADERS BOOL "Build HPX header tests (default: OFF)" OFF ADVANCED CATEGORY "Build Targets")
hpx_option(HPX_WITH_TESTS_EXTERNAL_BUILD BOOL "Build external cmake build tests (default: ON)" ON ADVANCED CATEGORY "Build Targets")
hpx_option(HPX_WITH_TESTS_EXAMPLES BOOL "Add HPX examples as tests (default: ON)" ON ADVANCED CATEGORY "Build Targets")
hpx_option(HPX_WITH_TOOLS BOOL "Build HPX tools (default: OFF)" OFF ADVANCED CATEGORY "Build Targets")

hpx_option(HPX_WITH_COMPILE_ONLY_TESTS BOOL
        "Create build system support for compile time only HPX tests (default ON)"
        ON CATEGORY "Build Targets")
hpx_option(HPX_WITH_FAIL_COMPILE_TESTS BOOL
        "Create build system support for fail compile HPX tests (default ON)"
        ON CATEGORY "Build Targets")

################################################################################
# Set our build options cache variables which are customizable by users
#

hpx_option(HPX_WITH_DEPRECATION_WARNINGS
        BOOL "Enable warnings for deprecated facilities. (default: ON)"
        ON ADVANCED)
if(HPX_WITH_DEPRECATION_WARNINGS)
  hpx_add_config_define(HPX_HAVE_DEPRECATION_WARNINGS)
endif()

## Generic build options
set(DEFAULT_MALLOC "system")
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
  set(DEFAULT_MALLOC "tcmalloc")
endif()

if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
  set(HPX_WITH_STACKOVERFLOW_DETECTION_DEFAULT OFF)
  string(TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE_UC)
  if("${CMAKE_BUILD_TYPE_UC}" STREQUAL "DEBUG")
    set(HPX_WITH_STACKOVERFLOW_DETECTION_DEFAULT ON)
  endif()
  hpx_option(HPX_WITH_STACKOVERFLOW_DETECTION
          BOOL
          "Enable stackoverflow detection for HPX threads/coroutines. (default: OFF, debug: ON)"
          ${HPX_WITH_STACKOVERFLOW_DETECTION_DEFAULT} ADVANCED)
  if(HPX_WITH_STACKOVERFLOW_DETECTION)
    hpx_add_config_define(HPX_HAVE_STACKOVERFLOW_DETECTION)
  endif()
endif()

hpx_option(HPX_WITH_MALLOC
        STRING
        "Define which allocator should be linked in. Options are: system, tcmalloc, jemalloc, mimalloc, tbbmalloc, and custom (default is: tcmalloc)"
        ${DEFAULT_MALLOC}
        STRINGS "system;tcmalloc;jemalloc;mimalloc;tbbmalloc;custom")

# On some systems jemalloc requires an explicit prefix for the API functions
# (i.e. 'malloc' is called 'je_malloc', etc.)
if(${HPX_WITH_MALLOC} STREQUAL "jemalloc")
  if(MSVC)
    set(HPX_WITH_JEMALLOC_PREFIX_DEFAULT "je_")
  else()
    set(HPX_WITH_JEMALLOC_PREFIX_DEFAULT "<none>")
  endif()
  hpx_option(HPX_WITH_JEMALLOC_PREFIX
          STRING
          "Optional naming prefix for jemalloc API functions"
          ${HPX_WITH_JEMALLOC_PREFIX_DEFAULT}
          ADVANCED)
endif()

# Logging configuration
hpx_option(HPX_WITH_LOGGING BOOL
        "Build HPX with logging enabled (default: ON)."
        ON ADVANCED)

hpx_option(HPX_WITH_FAULT_TOLERANCE BOOL
        "Build HPX to tolerate failures of nodes, i.e. ignore errors in active communication channels (default: OFF)"
        OFF ADVANCED)
if(HPX_WITH_FAULT_TOLERANCE)
  hpx_add_config_define(HPX_HAVE_FAULT_TOLERANCE)
endif()

if(HPX_WITH_LOGGING)
  hpx_add_config_define(HPX_HAVE_LOGGING)
endif()

# disable all tests if HPX_WITH_TESTS=OFF
if(NOT HPX_WITH_TESTS)
  hpx_set_option(HPX_WITH_TESTS_BENCHMARKS VALUE OFF FORCE)
  hpx_set_option(HPX_WITH_TESTS_REGRESSIONS VALUE OFF FORCE)
  hpx_set_option(HPX_WITH_TESTS_UNIT VALUE OFF FORCE)
  hpx_set_option(HPX_WITH_TESTS_HEADERS VALUE OFF FORCE)
  hpx_set_option(HPX_WITH_TESTS_EXTERNAL_BUILD VALUE OFF FORCE)
  hpx_set_option(HPX_WITH_TESTS_EXAMPLES VALUE OFF FORCE)
endif()

# Enable IO-counters on linux systems only
set(HPX_WITH_IO_COUNTERS_DEFAULT OFF)
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
  set(HPX_WITH_IO_COUNTERS_DEFAULT ON)
endif()

hpx_option(HPX_WITH_IO_COUNTERS BOOL
        "Enable IO counters (default: ${HPX_WITH_IO_COUNTERS_DEFAULT})"
        ${HPX_WITH_IO_COUNTERS_DEFAULT} ADVANCED CATEGORY "Build Targets")
if(HPX_WITH_IO_COUNTERS)
  hpx_add_config_define(HPX_HAVE_IO_COUNTERS)
endif()

set(HPX_FULL_RPATH_DEFAULT ON)
if(APPLE OR WIN32)
  set(HPX_FULL_RPATH_DEFAULT OFF)
endif()
hpx_option(HPX_WITH_FULL_RPATH BOOL
        "Build and link HPX libraries and executables with full RPATHs (default: ${HPX_FULL_RPATH_DEFAULT})"
        ${HPX_FULL_RPATH_DEFAULT} ADVANCED)

#############################
# We create a target to contain libraries like rt, dl etc. in order to remove
# global variables
add_library(hpx_base_libraries INTERFACE)

if(HPX_WITH_STACKTRACES OR HPX_WITH_THREAD_BACKTRACE_ON_SUSPENSION)
  hpx_info("Stack traces are enabled.")
  hpx_add_config_define(HPX_HAVE_STACKTRACES)
  if(WIN32)
    target_link_libraries(hpx_base_libraries INTERFACE dbghelp)
  endif()

  hpx_option(HPX_WITH_THREAD_BACKTRACE_DEPTH STRING
          "Thread stack back trace depth being captured (default: 5)"
          "5"
          CATEGORY "Thread Manager" ADVANCED)
  hpx_add_config_define(HPX_HAVE_THREAD_BACKTRACE_DEPTH
          ${HPX_WITH_THREAD_BACKTRACE_DEPTH})
endif()

#############################

hpx_option(HPX_WITH_ATTACH_DEBUGGER_ON_TEST_FAILURE BOOL
        "Break the debugger if a test has failed  (default: OFF)"
        OFF
        CATEGORY "Debugging" ADVANCED)
if(HPX_WITH_ATTACH_DEBUGGER_ON_TEST_FAILURE)
  hpx_add_config_define(HPX_HAVE_ATTACH_DEBUGGER_ON_TEST_FAILURE)
endif()

hpx_option(HPX_WITH_TESTS_DEBUG_LOG BOOL
        "Turn on debug logs (--hpx:debug-hpx-log) for tests (default: OFF)"
        OFF
        CATEGORY "Debugging" ADVANCED)

hpx_option(HPX_WITH_TESTS_DEBUG_LOG_DESTINATION STRING
        "Destination for test debug logs (default: cout)"
        "cout"
        CATEGORY "Debugging" ADVANCED)
################################################################################
# Some special handling of the compilation is need on build infrastructure for
# generating packages for target architecture, see issue #3575

hpx_option(HPX_WITH_BUILD_BINARY_PACKAGE BOOL
        "Build HPX on the build infrastructure on any LINUX distribution (default: OFF)."
        OFF ADVANCED)

################################################################################
# Add necessary compiler flags. Flags added here include flags to disable/enable
# certain warnings, enabling C++11 mode and disabling asserts. Setting of
# optimization flags is not handled here and is left to the responsibility of
# the user to avoid conflicts in the resulting binaries

hpx_add_target_compile_definition(_DEBUG PUBLIC CONFIGURATIONS Debug)
hpx_add_target_compile_definition(DEBUG PUBLIC CONFIGURATIONS Debug)
hpx_add_target_compile_definition(HPX_DISABLE_ASSERTS PUBLIC
        CONFIGURATIONS Release RelWithDebInfo MinSizeRelease)
hpx_add_target_compile_definition(BOOST_DISABLE_ASSERTS PUBLIC
        CONFIGURATIONS Release RelWithDebInfo MinSizeRelease)

# Make sure we compile in proper C++xx mode (MSVC uses it automatically)
include(HPX_DetectCppDialect)
hpx_detect_cpp_dialect()

# Store option value passed by an user for HPX_WITH_CXX14_RETURN_TYPE_DEDUCTION.
if(HPX_WITH_CXX14_RETURN_TYPE_DEDUCTION)
  set(HPX_WITH_CXX14_RETURN_TYPE_DEDUCTION_ADVANCED )
  set(HPX_WITH_CXX14_RETURN_TYPE_DEDUCTION_GIVEN ON)
else()
  set(HPX_WITH_CXX14_RETURN_TYPE_DEDUCTION_ADVANCED ADVANCED)
  set(HPX_WITH_CXX14_RETURN_TYPE_DEDUCTION_GIVEN OFF)
endif()
################################################################################
# C++ feature tests
################################################################################
include(HPX_PerformCxxFeatureTests)
hpx_perform_cxx_feature_tests()

# Exceptional handling for non-clang CUDA.
if(HPX_WITH_CXX14_RETURN_TYPE_DEDUCTION)
  if(HPX_WITH_CUDA AND NOT HPX_WITH_CUDA_CLANG)
    # means using default value (given value).
    unset(HPX_WITH_CXX14_RETURN_TYPE_DEDUCTION)
  endif()
endif()

# HPX_WITH_CXX14_RETURN_TYPE_DEDUCTION
# Default value is used only when HPX_WITH_CXX14_RETURN_TYPE_DEDUCTION is not defined.
hpx_option(HPX_WITH_CXX14_RETURN_TYPE_DEDUCTION BOOL
        "Enable the use of auto as a return value in some places. Overriding this flag is only necessary if the C++ compiler is not standard compliant, e.g. nvcc."
        ${HPX_WITH_CXX14_RETURN_TYPE_DEDUCTION_GIVEN}
        ${HPX_WITH_CXX14_RETURN_TYPE_DEDUCTION_ADVANCED})
if(HPX_WITH_CXX14_RETURN_TYPE_DEDUCTION)
  hpx_add_config_define(HPX_HAVE_CXX14_RETURN_TYPE_DEDUCTION)
endif()

################################################################################
# Set configuration option to use Boost.Context or not. This depends on the
# platform.
set(__use_generic_coroutine_context OFF)
if(APPLE)
  set(__use_generic_coroutine_context ON)
endif()
if("${HPX_PLATFORM_UC}" STREQUAL "BLUEGENEQ")
  set(__use_generic_coroutine_context ON)
endif()
hpx_option(HPX_WITH_GENERIC_CONTEXT_COROUTINES BOOL
        "Use Boost.Context as the underlying coroutines context switch implementation."
        ${__use_generic_coroutine_context} ADVANCED)

################################################################################
# check for miscellaneous things
################################################################################

hpx_check_for_mm_prefetch(
        DEFINITIONS HPX_HAVE_MM_PREFETCH)

hpx_check_for_stable_inplace_merge(
        DEFINITIONS HPX_HAVE_STABLE_INPLACE_MERGE)

if(NOT HPX_WITH_STABLE_INPLACE_MERGE)
  hpx_warn("The standard library you are using (libc++ version < 6) does not have a stable inplace_merge implementation.")
endif()

################################################################################
# Check for misc system headers
################################################################################

hpx_check_for_unistd_h(
        DEFINITIONS HPX_HAVE_UNISTD_H)

if(NOT WIN32)
  ##############################################################################
  # Macro definitions for system headers
  ##############################################################################
  add_definitions(-D_GNU_SOURCE)
  if(APPLE)
    hpx_add_config_define(BOOST_HAS_INT128)
  endif()

  ##############################################################################
  # System libraries
  ##############################################################################
  if(NOT MSVC)
    hpx_add_compile_flag_if_available(-pthread)
    if(HPX_HAVE_LIBATOMIC)
      target_link_libraries(hpx_base_libraries INTERFACE atomic)
    endif()
  endif()

  if(HPX_HAVE_LIBSUPCPP)
    target_link_libraries(hpx_base_libraries INTERFACE supc++)
  endif()

  if(NOT ${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
    target_link_libraries(hpx_base_libraries INTERFACE dl)
  endif()

  if(NOT APPLE AND NOT ("${HPX_PLATFORM_UC}" STREQUAL "ANDROID"))
    target_link_libraries(hpx_base_libraries INTERFACE rt)
  endif()

  if("${HPX_PLATFORM_UC}" STREQUAL "ANDROID")
    target_link_libraries(hpx_base_libraries INTERFACE log)
  endif()

  if(APPLE)
    hpx_add_compile_flag_if_available(-ftemplate-depth=256 LANGUAGES CXX)
  endif()
endif()

if(WIN32)
  if(MSVC)
    hpx_add_target_compile_option(-Ox PUBLIC CONFIGURATIONS Release)

    # even VS2017 has an ICE when compiling with -Ob2
    hpx_add_target_compile_option(-Ob1 PUBLIC CONFIGURATIONS Release)

    # /RTC1 is incompatible with /await
    if(NOT HPX_WITH_AWAIT)
      hpx_add_target_compile_option(/RTC1 PUBLIC CONFIGURATIONS Debug)
    else()
      hpx_remove_target_compile_option(/RTC1 PUBLIC CONFIGURATIONS Debug)
    endif()

    # VS2012 and above has a special flag for improving the debug experience by
    # adding more symbol information to the build (-d2Zi)
    hpx_add_target_compile_option(-d2Zi+ PUBLIC CONFIGURATIONS RelWithDebInfo)

    # VS2013 and above know how to do link time constant data segment folding
    # VS2013 update 2 and above know how to remove debug information for
    #     non-referenced functions and data (-Zc:inline)
    hpx_add_target_compile_option(-Zc:inline PUBLIC)
    hpx_add_target_compile_option(-Gw PUBLIC
            CONFIGURATIONS Release RelWithDebInfo MinSizeRelease)
    hpx_add_target_compile_option(-Zo PUBLIC CONFIGURATIONS RelWithDebInfo)
    if(HPX_WITH_DATAPAR_VC)
      hpx_add_target_compile_option(-std:c++latest PUBLIC)
      hpx_add_config_cond_define(_HAS_AUTO_PTR_ETC 1)
    endif()

    # Exceptions
    hpx_add_target_compile_option(-EHsc)
    if(MSVC_VERSION GREATER_EQUAL 1900)
      # assume conforming (throwing) operator new implementations
      hpx_add_target_compile_option(-Zc:throwingNew PUBLIC)

      # enable faster linking (requires VS2015 Update1)
      # disabled for now as this flag crashes debugger
      # hpx_remove_link_flag(/debug CONFIGURATIONS Debug)
      # hpx_add_link_flag(/debug:fastlink CONFIGURATIONS Debug)

      # Update 2 requires to set _ENABLE_ATOMIC_ALIGNMENT_FIX for it to compile
      # atomics
      hpx_add_config_cond_define(_ENABLE_ATOMIC_ALIGNMENT_FIX)

      # Update 3 allows to flag rvalue misuses and enforces strict string const-
      # qualification conformance
      hpx_add_target_compile_option(-Zc:rvalueCast PUBLIC)
      hpx_add_target_compile_option(-Zc:strictStrings PUBLIC)

      # Update 8 requires to set _ENABLE_EXTENDED_ALIGNED_STORAGE for it to
      # compile atomics
      hpx_add_config_cond_define(_ENABLE_EXTENDED_ALIGNED_STORAGE)

      # Make sure that __cplusplus is properly defined
      hpx_add_target_compile_option(-Zc:__cplusplus)
    endif()

    # Runtime type information
    hpx_add_target_compile_option(-GR PUBLIC)
    # Multiprocessor build
    hpx_add_target_compile_option(-MP PUBLIC)
    # Increase the maximum size of object file sections
    hpx_add_target_compile_option(-bigobj PUBLIC)
  endif()

  target_link_libraries(hpx_base_libraries INTERFACE psapi shlwapi)

  ##############################################################################
  # Macro definitions for system headers
  ##############################################################################
  add_definitions(-D_WINDOWS)
  add_definitions(-D_WIN32)
  hpx_add_config_cond_define(_WIN32_WINNT 0x0601)
  hpx_add_config_cond_define(_SCL_SECURE_NO_WARNINGS)
  hpx_add_config_cond_define(_CRT_SECURE_NO_WARNINGS)
  hpx_add_config_cond_define(_SCL_SECURE_NO_DEPRECATE)
  hpx_add_config_cond_define(_CRT_SECURE_NO_DEPRECATE)
  hpx_add_config_cond_define(_CRT_NONSTDC_NO_WARNINGS)
  hpx_add_config_cond_define(_WINSOCK_DEPRECATED_NO_WARNINGS)
  hpx_add_config_cond_define(_CRT_NON_CONFORMING_SWPRINTFS)
  hpx_add_config_cond_define(_SILENCE_FPOS_SEEKPOS_DEPRECATION_WARNING)

  ##############################################################################
  # Boost
  ##############################################################################

  hpx_add_config_cond_define(BOOST_USE_WINDOWS_H)
  if (NOT Boost_USE_STATIC_LIBS)
    hpx_add_config_cond_define(BOOST_SERIALIZATION_DYN_LINK)
  endif()
  if(NOT CMAKE_CL_64)
    hpx_add_config_cond_define(BOOST_NO_ALIGNMENT)
  endif()
  if(NOT HPX_WITH_GENERIC_CONTEXT_COROUTINES)
    hpx_add_config_define(HPX_HAVE_FIBER_BASED_COROUTINES)
  endif()
  hpx_add_config_cond_define(PSAPI_VERSION 1)
endif()

# Configure Warnings
if(HPX_WITH_COMPILER_WARNINGS)
  if(MSVC) # Adding special warning settings for the MSVC compiler ...
    hpx_add_compile_flag(-W3 LANGUAGES C CXX)
    # According to the ifort Windows manual, W3 isn't supported
    hpx_add_compile_flag(-W1 LANGUAGES Fortran)

    # MSVC2012/2013 are overeager to report 'qualifier applied to function type
    # has no meaning; ignored'
    hpx_add_compile_flag(-wd4180)

    # Boost.Lockfree triggers 'warning C4307: '+' : integral constant overflow'
    # which is benign
    hpx_add_compile_flag(-wd4307)

    # object allocated on the heap may not be aligned
    hpx_add_compile_flag(-wd4316)

    # max symbol length exceeded
    hpx_add_compile_flag(-wd4503)

    # 'int': forcing value to bool 'true' or 'false' (performance warning)
    hpx_add_compile_flag(-wd4800)

    # vcpkg enables the /utf-8 option which causes (benign) warnings in the
    # Spirit headers
    if(HPX_WITH_VCPKG)
      # The file contains a character starting at offset ... that is illegal in
      # the current source character set
      hpx_add_compile_flag(-wd4828)
    endif()

    if(HPX_WITH_DATAPAR_VC)
      # unary minus operator applied to unsigned type, result still unsigned
      hpx_add_compile_flag(-wd4146)

      # '<=': signed/unsigned mismatch
      hpx_add_compile_flag(-wd4018)

      # 'return': conversion from 'short' to 'Vc_1::schar', possible loss of data
      hpx_add_compile_flag(-wd4244)
    endif()

  else() # Trial and error approach for any other compiler ...
    hpx_add_compile_flag_if_available(-Wall LANGUAGES CXX C Fortran)
    hpx_add_compile_flag_if_available(-Wextra LANGUAGES CXX C Fortran)
    # This is a new warning popping up from the boost headers with no particular meaning
    hpx_add_compile_flag_if_available(-Wno-unused-local-typedefs LANGUAGES CXX C Fortran)
    hpx_add_compile_flag_if_available(-Wno-strict-aliasing LANGUAGES CXX C Fortran)
    hpx_add_compile_flag_if_available(-Wno-sign-promo LANGUAGES CXX)
    hpx_add_compile_flag_if_available(-Wno-attributes LANGUAGES CXX)
    hpx_add_compile_flag_if_available(-Wno-cast-align LANGUAGES CXX)

    # These are usually benign and can't be suppressed because of
    # interface requirements
    hpx_add_compile_flag_if_available(-Wno-unused-parameter)

    # Be extra strict about format checks
    # Boost.Logging is built on fprintf, sadly
    hpx_add_compile_flag_if_available(-Wformat=2)
    hpx_add_compile_flag_if_available(-Wno-format-nonliteral)

    # Self initialization is dangerous
    hpx_add_compile_flag_if_available(-Winit-self)

    # For portability
    hpx_add_compile_flag_if_available(-Wdouble-promotion)

    # Warn about casting that violates qualifiers or alignment
    hpx_add_compile_flag_if_available(-Wcast-qual)
    if(NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
      # Clang is overeager in reporting cast alignment problems in Boost
      hpx_add_compile_flag_if_available(-Wcast-align)
    endif()

    hpx_add_compile_flag_if_available(-Werror=trampolines)
    hpx_add_compile_flag_if_available(-Werror=parentheses)
    hpx_add_compile_flag_if_available(-Werror=reorder)
    hpx_add_compile_flag_if_available(-Werror=return-type)
    hpx_add_compile_flag_if_available(-Werror=sequence-point)
    hpx_add_compile_flag_if_available(-Werror=uninitialized)
    hpx_add_compile_flag_if_available(-Werror=format)
    hpx_add_compile_flag_if_available(-Werror=missing-braces)
    hpx_add_compile_flag_if_available(-Werror=sign-compare)
  endif()
endif()

# Configure compiler warnings as errors
if(HPX_WITH_COMPILER_WARNINGS_AS_ERRORS)
  if(MSVC)
    hpx_add_compile_flag(-WX LANGUAGES C CXX Fortran)
  else()
    hpx_add_compile_flag_if_available(-Werror LANGUAGES CXX C Fortran)
  endif()
endif()

# Diagnostics
if(MSVC)
  # Display full paths in diagnostics
  hpx_add_compile_flag(-FC LANGUAGES C CXX)
  if(CMAKE_CL_64)
    set(__target_arch "x86_64")
  else()
    set(__target_arch "x86")
  endif()
  hpx_info("Architecture detected: ${__target_arch}")
else()
  # Show the flags that toggle each warning
  hpx_add_compile_flag_if_available(-fdiagnostics-show-option LANGUAGES CXX C Fortran)

  # VLAs are a GNU extensions that we forbid as they are not supported on MSVC
  hpx_add_compile_flag_if_available(-Werror=vla)
  # No return statement in a non-void function can lead to garbage return values
  # in GCC.
  hpx_add_compile_flag_if_available(-Werror=return-type LANGUAGES CXX C)

  # We get false positives all over the place with this.
  if(CMAKE_COMPILER_IS_GNUCXX)
    hpx_add_compile_flag_if_available(-Wno-unused-but-set-parameter LANGUAGES CXX C)
    hpx_add_compile_flag_if_available(-Wno-unused-but-set-variable LANGUAGES CXX C)
    # Uninitialized variables are bad, earlier compilers issue spurious warnings
    hpx_add_compile_flag_if_available(-Werror=uninitialized LANGUAGES CXX C)
    hpx_add_compile_flag_if_available(-Wno-unused-local-typedefs LANGUAGES CXX C)
    # -Werror=maybe-uninitialized leads to false positives.
    hpx_add_compile_flag_if_available(-Wno-maybe-uninitialized LANGUAGES CXX C)
  endif()

  # Silence warning about __sync_fetch_and_nand changing semantics
  hpx_add_compile_flag_if_available(-Wno-sync-nand LANGUAGES CXX C)

  # Silence warnings about deleting polymorphic objects with non-virtual dtors.
  # These come from within Boost.
  if(CMAKE_COMPILER_IS_GNUCXX)
    hpx_add_compile_flag_if_available(-Wno-delete-non-virtual-dtor LANGUAGES CXX)
  endif()

  # Check if our libraries have unresolved symbols
  #if(NOT APPLE AND NOT HPX_WITH_APEX)
  if(NOT APPLE AND NOT WIN32 AND NOT HPX_WITH_SANITIZERS)
    hpx_add_link_flag_if_available(-Wl,-z,defs TARGETS SHARED EXE)
  endif()
  if(WIN32)
    target_link_libraries(hpx_base_libraries INTERFACE psapi WS2_32 mswsock)
  endif()

  if("${HPX_PLATFORM_UC}" STREQUAL "BLUEGENEQ")
    hpx_add_compile_flag_if_available(-Wno-deprecated-register LANGUAGES CXX C)
  endif()

  if(HPX_WITH_HIDDEN_VISIBILITY)
    hpx_add_compile_flag_if_available(-fvisibility=hidden LANGUAGES CXX C Fortran)
    hpx_add_link_flag_if_available(-fvisibility=hidden TARGETS SHARED EXE)
    hpx_add_config_define(HPX_HAVE_ELF_HIDDEN_VISIBILITY)
    hpx_add_config_define(HPX_HAVE_COROUTINE_GCC_HIDDEN_VISIBILITY)
    hpx_add_config_define(HPX_HAVE_PLUGIN_GCC_HIDDEN_VISIBILITY)
  endif()

  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    hpx_add_compile_flag_if_available(-Wno-cast-align)
  endif()

  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")
    # Disable the following warnings:
    # #1170: invalid redeclaration of nested class
    hpx_add_compile_flag_if_available(-wd1170)
    # #858: type qualifier on return type is meaningless
    hpx_add_compile_flag_if_available(-wd858)
    # #1098: the qualifier on this friend declaration is ignored
    hpx_add_compile_flag_if_available(-wd1098)
    # #488: template parameter not used in declaring the parameter type
    hpx_add_compile_flag_if_available(-wd488)
    # #2203: cast discards qualifiers from target type (needed for mvapich2
    #        mpi header)
    hpx_add_compile_flag_if_available(-wd2203)
    # #2536: cannot specify explicit initializer for arrays
    hpx_add_compile_flag_if_available(-wd2536)
  endif()

  set(__has_timestamp_support OFF)
  include(TargetArch)

  target_architecture(__target_arch)
  if("${__target_arch}" STREQUAL "i386" OR
          "${__target_arch}" STREQUAL "ix86" OR
          "${__target_arch}" STREQUAL "x86_64" OR
          "${__target_arch}" STREQUAL "ia64")

    # rdtsc is an x86 instruction that reads the value of a CPU time stamp
    # counter. rdtscp is an extension to rdtsc. The difference is that rdtscp is
    # a serializing instruction.
    hpx_cpuid("rdtsc" HPX_WITH_RDTSC DEFINITIONS HPX_HAVE_RDTSC)

    # One can not assume if RDTSCP is available on the hardware
    # of the build infrastructure, that it will be available on
    # all potential target hardware, see Issue  #3575
    if(NOT ${HPX_WITH_BUILD_BINARY_PACKAGE})

      # XeonPhi's do not support RDTSCP
      if(NOT ("${HPX_PLATFORM_UC}" STREQUAL "XEONPHI"))
        hpx_cpuid("rdtscp" HPX_WITH_RDTSCP DEFINITIONS HPX_HAVE_RDTSCP)
      endif()

    endif()
    if(HPX_WITH_RDTSC OR HPX_WITH_RDTSCP)
      set(__has_timestamp_support ON)
    endif()
  elseif("${__target_arch}" STREQUAL "arm" OR
          "${__target_arch}" STREQUAL "armv5" OR
          "${__target_arch}" STREQUAL "armv6" OR
          "${__target_arch}" STREQUAL "armv7")
    set(__has_timestamp_support ON)
  elseif("${__target_arch}" STREQUAL "ppc" OR
          "${__target_arch}" STREQUAL "ppc64")
    set(__has_timestamp_support ON)
  elseif("${__target_arch}" STREQUAL "bgq")
    set(__has_timestamp_support ON)
  elseif("${__target_arch}" STREQUAL "s390x")
    set(__has_timestamp_support ON)
  endif()

  hpx_info("Architecture detected: ${__target_arch}")
  if(NOT __has_timestamp_support)
    hpx_warn("No timestamp support is available; some performance counters may report incorrect results")
  endif()
endif()

# store target architecture for later use
set(HPX_WITH_TARGET_ARCHITECTURE ${__target_arch} CACHE INTERNAL "" FORCE)

# Compatibility with using Boost.ProgramOptions, introduced in V1.4.0
hpx_option(HPX_PROGRAM_OPTIONS_WITH_BOOST_PROGRAM_OPTIONS_COMPATIBILITY
        BOOL "Enable Boost.ProgramOptions compatibility. (default: ON)"
        ON ADVANCED CATEGORY "Modules")

# Compatibility with using Boost.FileSystem, introduced in V1.4.0
set(__filesystem_compatibility_default ON)
if(HPX_WITH_CXX17_FILESYSTEM)
  set(__filesystem_compatibility_default OFF)
endif()
hpx_option(HPX_FILESYSTEM_WITH_BOOST_FILESYSTEM_COMPATIBILITY
        BOOL "Enable Boost.FileSystem compatibility. (default: ${__filesystem_compatibility_default})"
        ${__filesystem_compatibility_default} ADVANCED CATEGORY "Modules")

################################################################################
# Find Our dependencies:
#   These are all dependencies needed to build the core library. Dependencies
#   that are only needed by plugins, examples or tests should be found
#   seperately in the appropriate subdirectory.

# Setup our required Boost libraries.
include(HPX_SetupBoost)
include(HPX_SetupBoostFilesystem)
include(HPX_SetupBoostIostreams)
include(HPX_SetupBoostProgramOptions)
# Find all allocators which are currently supported.
include(HPX_SetupAllocator)
include(HPX_SetupHwloc)

# reset external source lists
add_hpx_library_sources_noglob(hpx_external)
add_hpx_library_headers_noglob(hpx_external)

# Setup packages and subprojects
include(HPX_SetupCUDA) # CUDA needs to come before Apex, to have cuda_add_library available
include(HPX_SetupApex)
include(HPX_SetupPapi)
include(HPX_SetupHpxmp)
include(HPX_SetupGooglePerfTools)
include(HPX_SetupValgrind)
# Setup plugins
# (set here cause if we include it inside plugins, it will not be defined in
# src/CMakeLists.txt where we call add_static_parcelports)
include(HPX_SetupMPI)

if(HPX_WITH_SANITIZERS)
  hpx_add_config_define(HPX_HAVE_SANITIZERS)
endif()

if(HPX_WITH_VIM_YCM)
  SET(CMAKE_EXPORT_COMPILE_COMMANDS ON)
endif()

################################################################################
# Check Build Options based on the found dependencies. We also check for errors
# with incompatible options with the currently selected platform.
#

if(HPX_WITH_GENERIC_CONTEXT_COROUTINES)
  # Check if we can use generic coroutine contexts without any problems
  if(NOT Boost_CONTEXT_FOUND)
    hpx_error("The usage of Boost.Context was selected but Boost.Context was not found.")
  endif()
  hpx_add_config_define(HPX_HAVE_GENERIC_CONTEXT_COROUTINES)
endif()

################################################################################
# Emulation of SwapContext on Windows
################################################################################
if(WIN32)
  if(HPX_WITH_SWAP_CONTEXT_EMULATION)
    if(NOT CMAKE_ASM_MASM_COMPILER)
      hpx_error("SwitchToFiber emulation can not be enabled. The masm compiler \
      could not be found. Try setting the ASM_MASM environment variable to the \
      assembler executable (ml.exe/ml64.exe) or disable the emulation by setting \
      HPX_WITH_SWAP_CONTEXT_EMULATION to Off")
    else()
      hpx_info("SwitchToFiber emulation is enabled, using compiler: '${CMAKE_ASM_MASM_COMPILER}'")
      hpx_add_config_define(HPX_HAVE_SWAP_CONTEXT_EMULATION)
    endif()
  endif()
endif()

################################################################################

################################################################################
# HPX_PREFIX
# The prefix is the default search path for HPX plugins
################################################################################
if("${HPX_PLATFORM_UC}" STREQUAL "ANDROID")
  set(HPX_PREFIX "lib")
  set(HPX_BUILD_PREFIX "lib")
else()
  set(HPX_PREFIX "${CMAKE_INSTALL_PREFIX}")
  set(HPX_BUILD_PREFIX "${PROJECT_BINARY_DIR}")
endif()


################################################################################
# search path configuration
################################################################################
if(HPX_WITH_FULL_RPATH)
  include(HPX_SetFullRPATH)
endif()

################################################################################
# Git commit detection
################################################################################
include(HPX_GitCommit)
hpx_add_config_define(HPX_HAVE_GIT_COMMIT "\"${HPX_WITH_GIT_COMMIT}\"")

hpx_include(SetOutputPaths)

################################################################################
# Add custom targets for tests
################################################################################
if (HPX_WITH_TESTS)
  add_hpx_pseudo_target(tests)
  if (HPX_WITH_TESTS_UNIT)
    add_hpx_pseudo_target(tests.unit)
    add_hpx_pseudo_dependencies(tests tests.unit)
  endif()
  if (HPX_WITH_TESTS_REGRESSIONS)
    add_hpx_pseudo_target(tests.regressions)
    add_hpx_pseudo_dependencies(tests tests.regressions)
  endif()
  if (HPX_WITH_TESTS_BENCHMARKS)
    add_hpx_pseudo_target(tests.performance)
    add_hpx_pseudo_dependencies(tests tests.performance)
  endif()
  if (HPX_WITH_TESTS_HEADERS)
    add_hpx_pseudo_target(tests.headers)
    add_hpx_pseudo_dependencies(tests tests.headers)
  endif()
  if (HPX_WITH_EXAMPLES AND HPX_WITH_TESTS_EXAMPLES)
    add_hpx_pseudo_target(tests.examples)
    add_hpx_pseudo_dependencies(tests tests.examples)
  endif()

  enable_testing()
  include(CTest)
endif()

###############################################################################
# Tests
###############################################################################
if(HPX_WITH_TESTS)
  find_package(PythonInterp)

  if(NOT PYTHONINTERP_FOUND)
    hpx_warn("A python interpreter could not be found. The test suite can not be run automatically.")
  endif()

  # pseudo_target added above
  add_subdirectory(tests)
endif()

if(HPX_WITH_EXAMPLES)
  add_subdirectory(examples)
endif()

if(HPX_WITH_DOCUMENTATION)
  add_subdirectory(docs)
endif()

# Configure hpxrun.py
configure_file("${PROJECT_SOURCE_DIR}/cmake/templates/hpxrun.py.in"
        "${PROJECT_BINARY_DIR}/bin/hpxrun.py"
        @ONLY)
