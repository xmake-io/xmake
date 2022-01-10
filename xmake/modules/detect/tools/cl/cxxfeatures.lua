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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
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
-- Reference: http://msdn.microsoft.com/en-us/library/vstudio/hh567368.aspx
-- http://blogs.msdn.com/b/vcblog/archive/2013/06/28/c-11-14-stl-features-fixes-and-breaking-changes-in-vs-2013.aspx
-- http://blogs.msdn.com/b/vcblog/archive/2014/11/17/c-11-14-17-features-in-vs-2015-preview.aspx
-- http://www.visualstudio.com/en-us/news/vs2015-preview-vs.aspx
-- http://blogs.msdn.com/b/vcblog/archive/2015/04/29/c-11-14-17-features-in-vs-2015-rc.aspx
-- http://blogs.msdn.com/b/vcblog/archive/2015/06/19/c-11-14-17-features-in-vs-2015-rtm.aspx
-- https://docs.microsoft.com/en-us/cpp/overview/visual-cpp-language-conformance?view=msvc-160
--
-- porting from Modules/Compiler/MSVC-CXX-FeatureTests.cmake
--
function main()

    -- init conditions
    local msvc_minver = "_MSC_VER >= 1200"
    local msvc_60     = "_MSC_VER >= 1200"
    local msvc_70     = "_MSC_VER >= 1300"
    local msvc_71     = "_MSC_VER >= 1310"
    local msvc_2005   = "_MSC_VER >= 1400"
    local msvc_2008   = "_MSC_VER >= 1500"
    local msvc_2010   = "_MSC_VER >= 1600"
    local msvc_2012   = "_MSC_VER >= 1700"
    local msvc_2013   = "_MSC_VER >= 1800"
    local msvc_2015   = "_MSC_VER >= 1900"
    local msvc_2017   = "_MSC_VER >= 1910"
    local msvc_2019   = "_MSC_VER >= 1920"
    local msvc_2022   = "_MSC_VER >= 1930"

    -- set language standard supports
    _set("cxx_std_98", msvc_2005)
    _set("cxx_std_11", msvc_2015)
    _set("cxx_std_14", msvc_2017)
    _set("cxx_std_17", msvc_2019)
    _set("cxx_std_20", msvc_2022)

    -- VS version 15 (not 2015) introduces support for aggregate initializers.
    _set("cxx_aggregate_default_initializers", "_MSC_FULL_VER >= 190024406")

    -- VS 2015 Update 2 introduces support for variable templates.
    -- https://www.visualstudio.com/en-us/news/vs2015-update2-vs.aspx
    _set("cxx_variable_templates", "_MSC_FULL_VER >= 190023918")

    _set("cxx_alignas",                       msvc_2015)
    _set("cxx_alignof",                       msvc_2015)
    _set("cxx_attributes",                    msvc_2015)
    _set("cxx_attribute_deprecated",          msvc_2015)
    _set("cxx_binary_literals",               msvc_2015)
    _set("cxx_constexpr",                     msvc_2015)
    _set("cxx_decltype_auto",                 msvc_2015)
    _set("cxx_digit_separators",              msvc_2015)
    _set("cxx_func_identifier",               msvc_2015)
    _set("cxx_nonstatic_member_init",         msvc_2015)
    _set("cxx_defaulted_move_initializers",   msvc_2015)
    _set("cxx_generic_lambdas",               msvc_2015)
    _set("cxx_inheriting_constructors",       msvc_2015)
    _set("cxx_inline_namespaces",             msvc_2015)
    _set("cxx_lambda_init_captures",          msvc_2015)
    _set("cxx_noexcept",                      msvc_2015)
    _set("cxx_return_type_deduction",         msvc_2015)
    _set("cxx_sizeof_member",                 msvc_2015)
    _set("cxx_thread_local",                  msvc_2015)
    _set("cxx_unicode_literals",              msvc_2015)
    _set("cxx_unrestricted_unions",           msvc_2015)
    _set("cxx_user_literals",                 msvc_2015)
    _set("cxx_reference_qualified_functions", msvc_2015)

    -- "The copies and moves don't interact precisely like the Standard says they
    -- should. For example, deletion of moves is specified to also suppress
    -- copies, but Visual C++ in Visual Studio 2013 does not."
    -- http://blogs.msdn.com/b/vcblog/archive/2014/11/17/c-11-14-17-features-in-vs-2015-preview.aspx
    -- lists this as 'partial' in 2013
    _set("cxx_deleted_functions", msvc_2015)

    -- http://blogs.msdn.com/b/vcblog/archive/2014/11/17/c-11-14-17-features-in-vs-2015-preview.aspx
    -- Note 1. While previous version of VisualStudio said they supported these
    -- they silently produced bad code, and are now marked as having partial
    -- support in previous versions. The footnote says the support will be complete
    -- in msvc 2015, so support the feature for that version, assuming that is true.
    -- The blog post also says that VS 2013 Update 3 generates an error in cases
    -- that previously produced bad code.
    _set("cxx_generalized_initializers", "_MSC_FULL_VER >= 180030723")

    -- Microsoft now states they support contextual conversions in 2013 and above.
    -- See footnote 6 at:
    -- http://blogs.msdn.com/b/vcblog/archive/2014/11/17/c-11-14-17-features-in-vs-2015-preview.aspx
    _set("cxx_contextual_conversions",         msvc_2013)
    _set("cxx_default_function_template_args", msvc_2013)
    _set("cxx_defaulted_functions",            msvc_2013)
    _set("cxx_delegating_constructors",        msvc_2013)
    _set("cxx_explicit_conversions",           msvc_2013)
    _set("cxx_raw_string_literals",            msvc_2013)
    _set("cxx_uniform_initialization",         msvc_2013)
    _set("cxx_alias_templates",                msvc_2013)

    -- Support is documented, but possibly partly broken:
    -- https://msdn.microsoft.com/en-us/library/hh567368.aspx
    -- http://thread.gmane.org/gmane.comp.lib.boost.devel/244986/focus=245333
    _set("cxx_variadic_templates",           msvc_2013)

    _set("cxx_enum_forward_declarations",    msvc_2012)
    _set("cxx_final",                        msvc_2012)
    _set("cxx_range_for",                    msvc_2012)
    _set("cxx_strong_enums",                 msvc_2012)

    _set("cxx_auto_type",                    msvc_2010)
    _set("cxx_decltype",                     msvc_2010)
    _set("cxx_extended_friend_declarations", msvc_2010)
    _set("cxx_extern_templates",             msvc_2010)
    _set("cxx_lambdas",                      msvc_2010)
    _set("cxx_local_type_template_args",     msvc_2010)
    _set("cxx_long_long_type",               msvc_2010)
    _set("cxx_nullptr",                      msvc_2010)
    _set("cxx_override",                     msvc_2010)
    _set("cxx_right_angle_brackets",         msvc_2010)
    _set("cxx_rvalue_references",            msvc_2010)
    _set("cxx_static_assert",                msvc_2010)
    _set("cxx_template_template_parameters", msvc_2010)
    _set("cxx_trailing_return_types",        msvc_2010)
    _set("cxx_variadic_macros",              msvc_2010)

    -- get features
    return _g.features
end

