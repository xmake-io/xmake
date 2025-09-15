inherit("test_base")

CLANG_MIN_VER = is_subhost("windows") and "19" or "17"
GCC_MIN_VER = "11"
MSVC_MIN_VER = "14.29"

function main(_)
    local check_outdata = {str = "culled", format_string = "Modules culling does not work"}
    local clang_options = {compiler = "clang", version = CLANG_MIN_VER, check_outdata = check_outdata}
    local gcc_options = {compiler = "gcc", version = GCC_MIN_VER, check_outdata = check_outdata}
    local msvc_options = {version = MSVC_MIN_VER, check_outdata = check_outdata}
    run_tests(clang_options, gcc_options, msvc_options)
end
