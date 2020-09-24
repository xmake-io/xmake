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

-- imports
import("detect.tools.gcc.cxxfeatures")

-- set features
function _set(feature, condition)
    _g.features[feature] = condition
end

-- get features
--
-- porting from Modules/Compiler/Clang-CXX-FeatureTests.cmake
--
function main()

    -- init features
    _g.features = cxxfeatures()

    -- init conditions
    local clang_minver  = "((__clang_major__ * 100) + __clang_minor__) >= 301"
    local clang34_cxx14 = "((__clang_major__ * 100) + __clang_minor__) >= 304 && __cplusplus > 201103L"
    local clang31_cxx11 = clang_minver .. " && __cplusplus >= 201103L"
    local clang29_cxx11 = clang_minver .. " && __cplusplus >= 201103L"
    local clang_cxx98   = clang_minver .. " && __cplusplus >= 199711L"

    -- set features for __has_feature()
    local features_of_has_feature =
    {
         "cxx_alias_templates"
    ,    "cxx_alignas"
    ,    "cxx_attributes"
    ,    "cxx_auto_type"
    ,    "cxx_binary_literals"
    ,    "cxx_constexpr"
    ,    "cxx_contextual_conversions"
    ,    "cxx_decltype"
    ,    "cxx_default_function_template_args"
    ,    "cxx_defaulted_functions"
    ,    "cxx_delegating_constructors"
    ,    "cxx_deleted_functions"
    ,    "cxx_explicit_conversions"
    ,    "cxx_generalized_initializers"
    ,    "cxx_inheriting_constructors"
    ,    "cxx_lambdas"
    ,    "cxx_local_type_template_args"
    ,    "cxx_noexcept"
    ,    "cxx_nonstatic_member_init"
    ,    "cxx_nullptr"
    ,    "cxx_range_for"
    ,    "cxx_raw_string_literals"
    ,    "cxx_reference_qualified_functions"
    ,    "cxx_relaxed_constexpr"
    ,    "cxx_return_type_deduction"
    ,    "cxx_rvalue_references"
    ,    "cxx_static_assert"
    ,    "cxx_strong_enums"
    ,    "cxx_thread_local"
    ,    "cxx_unicode_literals"
    ,    "cxx_unrestricted_unions"
    ,    "cxx_user_literals"
    ,    "cxx_variable_templates"
    ,    "cxx_variadic_templates"
    ,   {"cxx_aggregate_default_initializers", "cxx_aggregate_nsdmi"          }
    ,   {"cxx_trailing_return_types",          "cxx_trailing_return"          }
    ,   {"cxx_alignof",                        "cxx_alignas"                  }
    ,   {"cxx_final",                          "cxx_override_control"         }
    ,   {"cxx_override",                       "cxx_override_control"         }
    ,   {"cxx_uniform_initialization",         "cxx_generalized_initializers" }
    ,   {"cxx_defaulted_move_initializers",    "cxx_defaulted_functions"      }
    ,   {"cxx_lambda_init_captures",           "cxx_init_captures"            }
    }
    for _, feature in ipairs(features_of_has_feature) do
        local name = feature
        local test = feature
        if type(feature) == "table" then
            name = feature[1]
            test = feature[2]
        end
        _set(name, clang_minver .. " && __has_feature(" .. test .. ")")
    end

    -- set features
    _set("cxx_attribute_deprecated",         clang34_cxx14) -- http://llvm.org/bugs/show_bug.cgi?id=19242
    _set("cxx_decltype_auto",                clang34_cxx14) -- http://llvm.org/bugs/show_bug.cgi?id=19698
    _set("cxx_digit_separators",             clang34_cxx14)
    _set("cxx_generic_lambdas",              clang34_cxx14) -- http://llvm.org/bugs/show_bug.cgi?id=19674
    _set("cxx_enum_forward_declarations",    clang31_cxx11)
    _set("cxx_sizeof_member",                clang31_cxx11)
    _set("cxx_extended_friend_declarations", clang29_cxx11)
    _set("cxx_extern_templates",             clang29_cxx11)
    _set("cxx_func_identifier",              clang29_cxx11)
    _set("cxx_inline_namespaces",            clang29_cxx11)
    _set("cxx_long_long_type",               clang29_cxx11)
    _set("cxx_right_angle_brackets",         clang29_cxx11)
    _set("cxx_variadic_macros",              clang29_cxx11)
    _set("cxx_template_template_parameters", clang_cxx98)

    -- get features
    return _g.features
end

