includes("@builtin/check")

target("foo")
    set_kind("static")
    add_files("foo.c")
    add_includedirs("$(buildir)")
    add_configfiles("config.h.in")

    check_bigendian("IS_BIG_ENDIAN")
    check_ctypes("HAS_WCHAR", "wchar_t")
    check_cincludes("HAS_STRING_H", "string.h")
    check_csnippets("HAS_INT_4", "return (sizeof(int) == 4)? 0 : -1;", {tryrun = true})
    check_csnippets("HAS_INT_4_IN_MAIN", [[
    int test() {
        return (sizeof(int) == 4)? 0 : -1;
    }
    int main(int argc, char** argv)
    {
        return test();
    }]], {tryrun = true})
    check_csnippets("INT_SIZE", 'printf("%d", sizeof(int)); return 0;', {output = true, number = true})
    check_sizeof("LONG_SIZE", "long")
    check_sizeof("STRING_SIZE", "std::string", {includes = "string"})
    configvar_check_bigendian("IS_BIG_ENDIAN")
    configvar_check_cincludes("HAS_STRING_AND_STDIO_H", {"string.h", "stdio.h"})
    configvar_check_ctypes("HAS_WCHAR_AND_FLOAT", {"wchar_t", "float"})
    configvar_check_links("HAS_PTHREAD", {"pthread", "m", "dl"})
    configvar_check_csnippets("HAS_STATIC_ASSERT", "_Static_assert(1, \"\");")
    configvar_check_cfuncs("HAS_SETJMP", "setjmp", {includes = {"signal.h", "setjmp.h"}})
    configvar_check_features("HAS_CONSTEXPR", "cxx_constexpr", {languages = "c++11"})
    configvar_check_features("HAS_CONSEXPR_AND_STATIC_ASSERT", {"cxx_constexpr", "c_static_assert"}, {languages = "c++11"})
    configvar_check_features("HAS_CXX_STD_98", "cxx_std_98")
    configvar_check_features("HAS_CXX_STD_11", "cxx_std_11", {languages = "c++11"})
    configvar_check_features("HAS_CXX_STD_14", "cxx_std_14", {languages = "c++14"})
    configvar_check_features("HAS_CXX_STD_17", "cxx_std_17", {languages = "c++17"})
    configvar_check_features("HAS_CXX_STD_20", "cxx_std_20", {languages = "c++20"})
    configvar_check_features("HAS_C_STD_89", "c_std_89")
    configvar_check_features("HAS_C_STD_99", "c_std_99")
    configvar_check_features("HAS_C_STD_11", "c_std_11", {languages = "c11"})
    configvar_check_features("HAS_C_STD_17", "c_std_17", {languages = "c17"})
    configvar_check_cflags("HAS_SSE2", "-msse2")
    configvar_check_csnippets("HAS_LONG_8", "return (sizeof(long) == 8)? 0 : -1;", {tryrun = true})
    configvar_check_csnippets("PTR_SIZE", 'printf("%d", sizeof(void*)); return 0;', {output = true, number = true})
    configvar_check_csnippets("HAVE_VISIBILITY", 'extern __attribute__((__visibility__("hidden"))) int hiddenvar;', {default = 0})
    configvar_check_csnippets("CUSTOM_ASSERT=assert", 'assert(1);', {default = "", quote = false})
    configvar_check_macros("HAS_GCC", "__GNUC__")
    configvar_check_macros("NO_GCC", "__GNUC__", {defined = false})
    configvar_check_macros("HAS_CXX20", "__cplusplus >= 202002L", {languages = "c++20"})

    local features_cxx17 = {
        "cxx_aggregate_bases",
        "cxx_aligned_new",
        "cxx_capture_star_this",
        "cxx_constexpr",
        "cxx_deduction_guides",
        "cxx_enumerator_attributes",
        "cxx_fold_expressions",
        "cxx_guaranteed_copy_elision",
        "cxx_hex_float",
        "cxx_if_constexpr",
        "cxx_inheriting_constructors",
        "cxx_inline_variables",
        "cxx_namespace_attributes",
        "cxx_noexcept_function_type",
        "cxx_nontype_template_args",
        "cxx_nontype_template_parameter_auto",
        "cxx_range_based_for",
        "cxx_static_assert",
        "cxx_structured_bindings",
        "cxx_template_template_args",
        "cxx_variadic_using"}
    for _, feature in ipairs(features_cxx17) do
        check_features("HAS_17_" .. feature:upper(), feature, {languages = "c++17"})
    end

    local features_cxx20 = {
        "cxx_aggregate_paren_init",
        "cxx_char8_t",
        "cxx_concepts",
        "cxx_conditional_explicit",
        "cxx_consteval",
        "cxx_constexpr",
        "cxx_constexpr_dynamic_alloc",
        "cxx_constexpr_in_decltype",
        "cxx_constinit",
        "cxx_deduction_guides",
        "cxx_designated_initializers",
        "cxx_generic_lambdas",
        "cxx_impl_coroutine",
        "cxx_impl_destroying_delete",
        "cxx_impl_three_way_comparison",
        "cxx_init_captures",
        "cxx_modules",
        "cxx_nontype_template_args",
        "cxx_using_enum"}
    for _, feature in ipairs(features_cxx20) do
        check_features("HAS_20_" .. feature:upper(), feature, {languages = "c++20"})
    end

target("test")
    add_deps("foo")
    set_kind("binary")
    add_files("main.c")
