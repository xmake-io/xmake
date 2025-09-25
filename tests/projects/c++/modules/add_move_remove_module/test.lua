inherit(".test_base")
import("utils.ci.is_running", {alias = "ci_is_running"})

CLANG_MIN_VER = is_subhost("windows") and "19" or "17"
GCC_MIN_VER = "11"
MSVC_MIN_VER = "14.29"

function _build(_)
    local flags = ""
    if ci_is_running() then
        flags = "-vD"
    end
    os.run("xmake -r " .. flags)
    io.writefile("src/bar.mpp", "export module bar;\n export {\n inline int bar() { return 0; }\n}")
    os.run("xmake " .. flags)
    os.rm("src/bar.mpp")
    os.run("xmake " .. flags)
    os.mv("src/foo.mpp", "src/bar.mpp")
    os.run("xmake " .. flags)
    os.mv("src/bar.mpp", "src/foo.mpp")
end

function main(_)
    local clang_options = {compiler = "clang", version = CLANG_MIN_VER, build = _build}
    local gcc_options = {compiler = "gcc", version = GCC_MIN_VER, build = _build}
    local msvc_options = {version = MSVC_MIN_VER, build = _build}
    run_tests(clang_options, gcc_options, msvc_options)
end
