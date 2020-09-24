--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        cxxfeatures.lua
--

-- set features
function _set(feature, condition)
    _g.features = _g.features or {}
    _g.features[feature] = condition
end

-- get features
--
-- http://gcc.gnu.org/projects/cxx0x.html
-- http://gcc.gnu.org/projects/cxx1y.html
--
-- porting from Modules/Compiler/GNU-CXX-FeatureTests.cmake
--
function main()

    -- init conditions
    local gcc_minver        = "(__GNUC__ * 100 + __GNUC_MINOR__) >= 404"
    local gcc50_cxx14       = "(__GNUC__ * 100 + __GNUC_MINOR__) >= 500 && __cplusplus >= 201402L"
    local gcc49_cxx14       = "(__GNUC__ * 100 + __GNUC_MINOR__) >= 409 && __cplusplus > 201103L"
    local gcc481_cxx11      = "((__GNUC__ * 10000 + __GNUC_MINOR__ * 100 + __GNUC_PATCHLEVEL__) >= 40801) && __cplusplus >= 201103L"
    local gcc48_cxx11       = "(__GNUC__ * 100 + __GNUC_MINOR__) >= 408 && __cplusplus >= 201103L"
    local gcc47_cxx11       = "(__GNUC__ * 100 + __GNUC_MINOR__) >= 407 && __cplusplus >= 201103L"
    local gcc_cxx0x_defined = "(__cplusplus >= 201103L || (defined(__GXX_EXPERIMENTAL_CXX0X__) && __GXX_EXPERIMENTAL_CXX0X__))"
    local gcc46_cxx11       = "(__GNUC__ * 100 + __GNUC_MINOR__) >= 406 && " .. gcc_cxx0x_defined
    local gcc45_cxx11       = "(__GNUC__ * 100 + __GNUC_MINOR__) >= 405 && " .. gcc_cxx0x_defined
    local gcc44_cxx11       = "(__GNUC__ * 100 + __GNUC_MINOR__) >= 404 && " .. gcc_cxx0x_defined
    local gcc43_cxx11       = gcc_minver .. " && " .. gcc_cxx0x_defined

    -- set features
    _set("cxx_variable_templates",             gcc50_cxx14)
    _set("cxx_relaxed_constexpr",              gcc50_cxx14)
    _set("cxx_aggregate_default_initializers", gcc50_cxx14)

    -- GNU 4.9 in c++14 mode sets __cplusplus to 201300L, so don't test for the
    -- correct value of it below.
    -- https://patchwork.ozlabs.org/patch/382470/
    _set("cxx_contextual_conversions", gcc49_cxx14)
    _set("cxx_attribute_deprecated",   gcc49_cxx14)
    _set("cxx_decltype_auto",          gcc49_cxx14)
    _set("cxx_digit_separators",       gcc49_cxx14)
    _set("cxx_generic_lambdas",        gcc49_cxx14)
    _set("cxx_lambda_init_captures",   gcc49_cxx14)

    -- GNU 4.3 supports binary literals as an extension, but may warn about
    -- use of extensions prior to GNU 4.9
    -- http://stackoverflow.com/questions/16334024/difference-between-gcc-binary-literals-and-c14-ones
    _set("cxx_binary_literals", gcc49_cxx14)

    -- The feature below is documented as available in GNU 4.8 (by implementing an
    -- earlier draft of the standard paper), but that version of the compiler
    -- does not set __cplusplus to a value greater than 201103L until GNU 4.9:
    -- http://gcc.gnu.org/onlinedocs/gcc-4.8.2/cpp/Standard-Predefined-Macros.html#Standard-Predefined-Macros
    -- http://gcc.gnu.org/onlinedocs/gcc-4.9.0/cpp/Standard-Predefined-Macros.html#Standard-Predefined-Macros
    -- So, CMake only reports availability for it with GNU 4.9 or later.
    _set("cxx_return_type_deduction", gcc49_cxx14)

    -- Introduced in GCC 4.8.1
    _set("cxx_decltype_incomplete_return_types", gcc481_cxx11)
    _set("cxx_reference_qualified_functions",    gcc481_cxx11)

    -- The alignof feature works with GNU 4.7 and -std=c++11, but it is documented
    -- as available with GNU 4.8, so treat that as true.
    _set("cxx_alignas",                 gcc48_cxx11)
    _set("cxx_alignof",                 gcc48_cxx11)
    _set("cxx_attributes",              gcc48_cxx11)
    _set("cxx_inheriting_constructors", gcc48_cxx11)
    _set("cxx_thread_local",            gcc48_cxx11)

    _set("cxx_alias_templates",              gcc47_cxx11)
    _set("cxx_delegating_constructors",      gcc47_cxx11)
    _set("cxx_extended_friend_declarations", gcc47_cxx11)
    _set("cxx_final",                        gcc47_cxx11)
    _set("cxx_nonstatic_member_init",        gcc47_cxx11)
    _set("cxx_override",                     gcc47_cxx11)
    _set("cxx_user_literals",                gcc47_cxx11)

    -- NOTE: C++11 was ratified in September 2011. GNU 4.7 is the first minor
    -- release following that (March 2012), and the first minor release to
    -- support -std=c++11. Prior to that, support for C++11 features is technically
    -- experiemental and possibly incomplete (see for example the note below about
    -- cxx_variadic_template_template_parameters)
    -- GNU does not define __cplusplus correctly before version 4.7.
    -- https://gcc.gnu.org/bugzilla/show_bug.cgi?id=1773
    -- __GXX_EXPERIMENTAL_CXX0X__ is defined in prior versions, but may not be
    -- defined in the future.
    _set("cxx_constexpr",                   gcc46_cxx11)
    _set("cxx_defaulted_move_initializers", gcc46_cxx11)
    _set("cxx_enum_forward_declarations",   gcc46_cxx11)
    _set("cxx_noexcept",                    gcc46_cxx11)
    _set("cxx_nullptr",                     gcc46_cxx11)
    _set("cxx_range_for",                   gcc46_cxx11)
    _set("cxx_unrestricted_unions",         gcc46_cxx11)

    _set("cxx_explicit_conversions",     gcc45_cxx11)
    _set("cxx_lambdas",                  gcc45_cxx11)
    _set("cxx_local_type_template_args", gcc45_cxx11)
    _set("cxx_raw_string_literals",      gcc45_cxx11)

    _set("cxx_auto_type",                gcc44_cxx11)
    _set("cxx_defaulted_functions",      gcc44_cxx11)
    _set("cxx_deleted_functions",        gcc44_cxx11)
    _set("cxx_generalized_initializers", gcc44_cxx11)
    _set("cxx_inline_namespaces",        gcc44_cxx11)
    _set("cxx_sizeof_member",            gcc44_cxx11)
    _set("cxx_strong_enums",             gcc44_cxx11)
    _set("cxx_trailing_return_types",    gcc44_cxx11)
    _set("cxx_unicode_literals",         gcc44_cxx11)
    _set("cxx_uniform_initialization",   gcc44_cxx11)
    _set("cxx_variadic_templates",       gcc44_cxx11)

    -- TODO: If features are ever recorded for GNU 4.3, there should possibly
    -- be a new feature added like cxx_variadic_template_template_parameters,
    -- which is implemented by GNU 4.4, but not 4.3. cxx_variadic_templates is
    -- actually implemented by GNU 4.3, but variadic template template parameters
    -- 'completes' it, so that is the version we record as having the variadic
    -- templates capability in CMake. See
    -- http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2008/n2555.pdf
    -- TODO: Should be supported by GNU 4.3
    _set("cxx_decltype",                       gcc43_cxx11)
    _set("cxx_default_function_template_args", gcc43_cxx11)
    _set("cxx_long_long_type",                 gcc43_cxx11)
    _set("cxx_right_angle_brackets",           gcc43_cxx11)
    _set("cxx_rvalue_references",              gcc43_cxx11)
    _set("cxx_static_assert",                  gcc43_cxx11)

    -- TODO: Should be supported since GNU 3.4?
    _set("cxx_extern_templates", gcc_minver .. " && " .. gcc_cxx0x_defined)

    -- TODO: Should be supported forever?
    _set("cxx_func_identifier", gcc_minver .. " && " .. gcc_cxx0x_defined)
    _set("cxx_variadic_macros", gcc_minver .. " && " .. gcc_cxx0x_defined)
    _set("cxx_template_template_parameters", gcc_minver .. " && __cplusplus")

    -- get features
    return _g.features
end

