inherit("test_base")
import("utils.ci.is_running", {alias = "ci_is_running"})

CLANG_MIN_VER = is_subhost("windows") and "19" or "17"
GCC_MIN_VER = "11"
MSVC_MIN_VER = "14.29"

function _build(platform, toolchain_name, runtimes, policies, flags)
    os.exec("xmake f" .. platform .. "--toolchain=" .. toolchain_name .. runtimes .. "-c --yes " .. policies .. " --foo=n")
    local outdata
    if ci_is_running() then
        outdata = os.iorun("xmake -rvD")
    else
        outdata = os.iorun("xmake -rv")
    end
    if outdata then
        if outdata:find("FOO") then
            raise("Modules dependency scanner update does not work\n%s", outdata)
        end
    end
end

function main(t)
    local clang_options = {compiler = "clang", version = CLANG_MIN_VER, flags = {"--foo=y"}, after_build = _build}
    local gcc_options = {compiler = "gcc", version = GCC_MIN_VER, flags = {"--foo=y"}, after_build = _build}
    local msvc_options = {version = MSVC_MIN_VER, flags = {"--foo=y"}, after_build = _build}
    run_tests(clang_options, gcc_options, msvc_options)
end
