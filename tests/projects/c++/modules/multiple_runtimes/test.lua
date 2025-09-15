import("lib.detect.find_tool")
import("core.base.semver")
import("core.tool.toolchain")
import("utils.ci.is_running", {alias = "ci_is_running"})

CLANG_MIN_VER = "19"
GCC_MIN_VER = "15"
MSVC_MIN_VER = "14.35"

function main(_)
    if not is_subhost("windows") and not is_host("linux") then
        return
    end

    if is_subhost("windows") then
        local msvc = toolchain.load("msvc")
        if not msvc or not msvc:check() then
            wprint("msvc not found, skipping tests")
            return
        end
        local vcvars = msvc:config("vcvars")
        if not vcvars or not vcvars.VCInstallDir or not vcvars.VCToolsVersion then
            wprint("msvc not found, skipping tests")
            return
        end
        local version = vcvars.VCToolsVersion
        if not version or not (semver.compare(version, MSVC_MIN_VER) >= 0) then
            return
        end
        -- on windows, llvm libc++ std module is currently not supported, uncommend when supported
        local clang = find_tool("clang", {version = true})
        if not (clang and clang.version and semver.compare(clang.version, CLANG_MIN_VER) >= 0) then
            return
        end
    else
        local gcc = find_tool("gcc", {version = true})
        if not (gcc and gcc.version and semver.compare(gcc.version, GCC_MIN_VER) >= 0) then
            return
        end
        local clang = find_tool("clang", {version = true})
        if not (clang and clang.version and semver.compare(clang.version, CLANG_MIN_VER) >= 0) then
            return
        end
    end

    local cl_str = "modules\\std.ixx"
    local clang_str = is_host("windows") and "v1\\std.cppm" or "v1/std.cppm"
    local gcc_str = "v1/std.cppm"

    local flags = ""
    if ci_is_running() then
     flags = "-vD"
    end
    local outdata
    outdata = os.iorun("xmake -r " ..  flags)
    if outdata then
        local error = true
        -- on windows, llvm libc++ std module is currently not supported, uncommend when supported
        if is_host("windows") and outdata:find(cl_str, 1, true) and outdata:find(clang_str, 1, true) then
            error = false
        elseif outdata:find(clang_str, 1, true) and outdata:find(gcc_str, 1, true) then
            error = false
        end
        if error then
            raise("Multiple runtimes doesn't work\n%s", outdata)
        end
    end
end
