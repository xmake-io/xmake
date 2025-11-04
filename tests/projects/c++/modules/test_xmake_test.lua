inherit("test_base")
import("utils.ci.is_running", {alias = "ci_is_running"})

CLANG_MIN_VER = is_subhost("windows") and "19" or "17"
GCC_MIN_VER = "11"
MSVC_MIN_VER = "14.29"

function run_xmake_test(...)
    local flags = ""
    if ci_is_running() then
        flags = "-vD"
    end
    local outdata, errdata = os.iorun("xmake test " .. flags)
    print(outdata, errdata)
    -- assert(outdata, errdata)
end

function main(t)
    local clang_options = {compiler = "clang", version = CLANG_MIN_VER, after_build = run_xmake_test}
    local gcc_options = {compiler = "gcc", version = GCC_MIN_VER, after_build = run_xmake_test}
    local msvc_options = {version = MSVC_MIN_VER, after_build = run_xmake_test}
    run_tests(clang_options, gcc_options, msvc_options)
end
