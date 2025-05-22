inherit(".test_base")

CLANG_MIN_VER = "17"
GCC_MIN_VER = "11"
MSVC_MIN_VER = "14.29"

function main(_)
    -- clang-cl doesn't support mixing pch and C++ module atm
    local clang_options = {compiler = "clang", version = CLANG_MIN_VER, disable_clang_cl = true}
    local gcc_options = {compiler = "gcc", version = GCC_MIN_VER}
    local msvc_options = {version = MSVC_MIN_VER}
    run_tests(clang_options, gcc_options, msvc_options)
end
