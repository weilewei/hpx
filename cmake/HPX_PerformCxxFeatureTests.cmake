# Copyright (c) 2007-2017 Hartmut Kaiser
# Copyright (c) 2011-2014 Thomas Heller
# Copyright (c) 2013-2016 Agustin Berge
# Copyright (c)      2017 Taeguk Kwon
#
# SPDX-License-Identifier: BSL-1.0
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

################################################################################
# C++ feature tests
################################################################################
function(hpx_perform_cxx_feature_tests)

  # Check the availability of certain C++11 language features
  hpx_check_for_cxx11_alias_templates(
    REQUIRED "HPX needs support for C++11 alias templates")

  hpx_check_for_cxx11_alignas(
    DEFINITIONS HPX_HAVE_CXX11_ALIGNAS)

  hpx_check_for_cxx11_auto(
    REQUIRED "HPX needs support for C++11 auto")

  hpx_check_for_cxx11_constexpr(
    DEFINITIONS HPX_HAVE_CXX11_CONSTEXPR)

  hpx_check_for_cxx11_decltype(
    REQUIRED "HPX needs support for C++11 decltype")
  hpx_add_config_cond_define(BOOST_RESULT_OF_USE_DECLTYPE)

  hpx_check_for_cxx11_sfinae_expression(
    DEFINITIONS HPX_HAVE_CXX11_SFINAE_EXPRESSION)

  hpx_check_for_cxx11_defaulted_functions(
    REQUIRED "HPX needs support for C++11 defaulted functions")

  hpx_check_for_cxx11_deleted_functions(
    REQUIRED "HPX needs support for C++11 deleted functions")

  hpx_check_for_cxx11_explicit_cvt_ops(
    REQUIRED "HPX needs support for C++11 explicit conversion operators")

  hpx_check_for_cxx11_explicit_variadic_templates(
    DEFINITIONS HPX_HAVE_CXX11_EXPLICIT_VARIADIC_TEMPLATES)

  hpx_check_for_cxx11_extended_friend_declarations(
    DEFINITIONS HPX_HAVE_CXX11_EXTENDED_FRIEND_DECLARATIONS)

  hpx_check_for_cxx11_function_template_default_args(
    REQUIRED "HPX needs support for C++11 defaulted function template arguments")

  hpx_check_for_cxx11_inline_namespaces(
    REQUIRED "HPX needs support for C++11 inline namespaces")

  hpx_check_for_cxx11_lambdas(
    REQUIRED "HPX needs support for C++11 lambdas")

  hpx_check_for_cxx11_noexcept(
    REQUIRED "HPX needs support for C++11 noexcept")

  hpx_check_for_cxx11_nullptr(
    REQUIRED "HPX needs support for C++11 nullptr")

  hpx_check_for_cxx11_nsdmi(
    DEFINITIONS HPX_HAVE_CXX11_NSDMI)

  hpx_check_for_cxx11_range_based_for(
    REQUIRED "HPX needs support for C++11 range-based for-loop")

  hpx_check_for_cxx11_rvalue_references(
    REQUIRED "HPX needs support for C++11 rvalue references")

  hpx_check_for_cxx11_scoped_enums(
    REQUIRED "HPX needs support for C++11 scoped enums")

  hpx_check_for_cxx11_static_assert(
    REQUIRED "HPX needs support for C++11 static_assert")

  hpx_check_for_cxx11_variadic_macros(
    REQUIRED "HPX needs support for C++11 variadic macros")

  hpx_check_for_cxx11_variadic_templates(
    REQUIRED "HPX needs support for C++11 variadic templates")

  hpx_check_for_cxx11_override(
    REQUIRED "HPX needs support for C++11 override")

  # Check the availability of certain C++11 library features
  hpx_check_for_cxx11_std_array(
    REQUIRED "HPX needs support for C++11 std::array")

  hpx_check_for_cxx11_std_atomic(
    REQUIRED "HPX needs support for C++11 std::atomic")

  # Separately check for 128 bit atomics
  hpx_check_for_cxx11_std_atomic_128bit(
    DEFINITIONS HPX_HAVE_CXX11_STD_ATOMIC_128BIT)

  hpx_check_for_cxx11_std_chrono(
    REQUIRED "HPX needs support for C++11 std::chrono")

  hpx_check_for_cxx11_std_cstdint(
    REQUIRED "HPX needs support for C++11 std::[u]intX_t")

  hpx_check_for_cxx11_std_exception_ptr(
    REQUIRED "HPX needs support for C++11 std::exception_ptr")

  hpx_check_for_cxx11_std_forward_list(
    REQUIRED "HPX needs support for C++11 std::forward_list")

  hpx_check_for_cxx11_std_initializer_list(
    REQUIRED "HPX needs support for C++11 std::initializer_list")

  hpx_check_for_cxx11_std_is_bind_expression(
    DEFINITIONS HPX_HAVE_CXX11_STD_IS_BIND_EXPRESSION)

  hpx_check_for_cxx11_std_is_placeholder(
    DEFINITIONS HPX_HAVE_CXX11_STD_IS_PLACEHOLDER)

  hpx_check_for_cxx11_std_is_trivially_copyable(
    DEFINITIONS HPX_HAVE_CXX11_STD_IS_TRIVIALLY_COPYABLE)

  hpx_check_for_cxx11_std_lock_guard(
    REQUIRED "HPX needs support for C++11 std::lock_guard")

  hpx_check_for_cxx11_std_quick_exit(
    DEFINITIONS HPX_HAVE_CXX11_STD_QUICK_EXIT)

  hpx_check_for_cxx11_std_random(
    DEFINITIONS HPX_HAVE_CXX11_STD_RANDOM)

  hpx_check_for_cxx11_std_range_access(
    REQUIRED "HPX needs support for C++11 std::begin/end")

  hpx_check_for_cxx11_std_reference_wrapper(
    REQUIRED "HPX needs support for C++11 std::ref and std::reference_wrapper")

  hpx_check_for_cxx11_std_regex(
    REQUIRED "HPX needs support for C++11 std::regex")

  hpx_check_for_cxx11_std_shared_ptr(
    REQUIRED "HPX needs support for C++11 std::shared_ptr")

  hpx_check_for_cxx11_std_shared_ptr_lwg3018(
    DEFINITIONS HPX_HAVE_CXX11_SHARED_PTR_LWG3018)

  hpx_check_for_cxx11_std_shuffle(
    DEFINITIONS HPX_HAVE_CXX11_STD_SHUFFLE)

  hpx_check_for_cxx11_std_thread(
    DEFINITIONS HPX_HAVE_CXX11_STD_THREAD)

  hpx_check_for_cxx11_std_to_string(
    REQUIRED "HPX needs support for C++11 std::to_string")

  hpx_check_for_cxx11_std_unique_lock(
    REQUIRED "HPX needs support for C++11 std::unique_lock")

  hpx_check_for_cxx11_std_unique_ptr(
    REQUIRED "HPX needs support for C++11 std::unique_ptr")

  hpx_check_for_cxx11_std_unordered_map(
    REQUIRED "HPX needs support for C++11 std::unordered_map")

  hpx_check_for_cxx11_std_unordered_set(
    REQUIRED "HPX needs support for C++11 std::unordered_set")

  hpx_check_for_cxx11_thread_local(
    DEFINITIONS HPX_HAVE_CXX11_THREAD_LOCAL)

  hpx_check_for_cxx11_noreturn_attribute(
    DEFINITIONS HPX_HAVE_CXX11_NORETURN_ATTRIBUTE)

  if(HPX_WITH_CXX1Y OR HPX_WITH_CXX14 OR HPX_WITH_CXX1Z OR HPX_WITH_CXX17 OR HPX_WITH_CXX2A)
    # Check the availability of certain C++14 language features
    hpx_check_for_cxx14_constexpr(
      DEFINITIONS HPX_HAVE_CXX14_CONSTEXPR)

    hpx_check_for_cxx14_lambdas(
      DEFINITIONS HPX_HAVE_CXX14_LAMBDAS)

    # Check the availability of certain C++14 library features
    hpx_check_for_cxx14_std_integer_sequence(
      DEFINITIONS HPX_HAVE_CXX14_STD_INTEGER_SEQUENCE)

    hpx_check_for_cxx14_std_is_final(
      DEFINITIONS HPX_HAVE_CXX14_STD_IS_FINAL)

    hpx_check_for_cxx14_std_is_null_pointer(
      DEFINITIONS HPX_HAVE_CXX14_STD_IS_NULL_POINTER)

    hpx_check_for_cxx14_std_result_of_sfinae(
      DEFINITIONS HPX_HAVE_CXX14_STD_RESULT_OF_SFINAE)

    hpx_check_for_cxx14_variable_templates(
      DEFINITIONS HPX_HAVE_CXX14_VARIABLE_TEMPLATES)

    hpx_check_for_cxx14_deprecated_attribute(
      DEFINITIONS HPX_HAVE_CXX14_DEPRECATED_ATTRIBUTE)

    hpx_check_for_cxx14_return_type_deduction()
  endif()

  if(HPX_WITH_CXX1Z OR HPX_WITH_CXX17 OR HPX_WITH_CXX2A)
    # Check the availability of certain C++17 language features
    hpx_check_for_cxx17_filesystem(
      DEFINITIONS HPX_HAVE_CXX17_FILESYSTEM)

    hpx_check_for_cxx17_fold_expressions(
      DEFINITIONS HPX_HAVE_CXX17_FOLD_EXPRESSIONS)

    hpx_check_for_cxx17_fallthrough_attribute(
      DEFINITIONS HPX_HAVE_CXX17_FALLTHROUGH_ATTRIBUTE)

    hpx_check_for_cxx17_hardware_destructive_interference_size(
      DEFINITIONS HPX_HAVE_CXX17_HARDWARE_DESTRUCTIVE_INTERFERENCE_SIZE)

    hpx_check_for_cxx17_structured_bindings(
      DEFINITIONS HPX_HAVE_CXX17_STRUCTURED_BINDINGS)

    hpx_check_for_cxx17_if_constexpr(
      DEFINITIONS HPX_HAVE_CXX17_IF_CONSTEXPR)

    hpx_check_for_cxx17_aligned_new(
      DEFINITIONS HPX_HAVE_CXX17_ALIGNED_NEW)

    hpx_check_for_cxx17_std_in_place_type_t(
      DEFINITIONS HPX_HAVE_CXX17_STD_IN_PLACE_TYPE_T)

  endif()

  # we deliberately check for this functionality even for non-C++17
  # configurations as some compilers (notable gcc V7.x) require for noexcept
  # function specializations for actions even in C++11/14 mode
  hpx_check_for_cxx17_noexcept_functions_as_nontype_template_arguments(
    DEFINITIONS HPX_HAVE_CXX17_NOEXCEPT_FUNCTIONS_AS_NONTYPE_TEMPLATE_ARGUMENTS)

  # Check the availability of certain C++ builtins
  hpx_check_for_builtin_integer_pack(
    DEFINITIONS HPX_HAVE_BUILTIN_INTEGER_PACK)

  hpx_check_for_builtin_make_integer_seq(
    DEFINITIONS HPX_HAVE_BUILTIN_MAKE_INTEGER_SEQ)

  hpx_check_for_builtin_type_pack_element(
    DEFINITIONS HPX_HAVE_BUILTIN_TYPE_PACK_ELEMENT)

endfunction()
