inherit("test_base")

CLANG_MIN_VER = "18"
GCC_MIN_VER = "13"
MSVC_MIN_VER = "14.30"

function main(_)
    local clang_options = {compiler = "clang", version = CLANG_MIN_VER}
    local gcc_options = {compiler = "gcc", version = GCC_MIN_VER}
    local msvc_options = {version = MSVC_MIN_VER}
    run_tests(clang_options, gcc_options, msvc_options)
end
