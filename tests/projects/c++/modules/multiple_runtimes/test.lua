import("lib.detect.find_tool")
import("core.base.semver")
import("core.tool.toolchain")
import("utils.ci.is_running", {alias = "ci_is_running"})

CLANG_MIN_VER = "19"
GCC_MIN_VER = "15"
MSVC_MIN_VER = "14.35"

function _check_tool_version(name, min_ver)
    local tool = find_tool(name, {version = true})
    if not (tool and tool.version and semver.compare(tool.version, min_ver) >= 0) then
        return false
    end
    return true
end

function _check_msvc_version(min_ver)
    local msvc = toolchain.load("msvc")
    if not msvc or not msvc:check() then
        return false
    end
    local vcvars = msvc:config("vcvars")
    if not vcvars or not vcvars.VCInstallDir or not vcvars.VCToolsVersion then
        return false
    end
    local version = vcvars.VCToolsVersion
    if not version or not (semver.compare(version, min_ver) >= 0) then
        return false
    end
    return true
end

function main(_)
    if is_subhost("windows") then
        if not _check_msvc_version(MSVC_MIN_VER) then
            return
        end
        -- on windows, llvm libc++ std module is currently not supported, uncommend when supported
        -- if not check_tool_version("clang", CLANG_MIN_VER) then
        --     return
        -- end
    elseif is_host("linux") then
        if not _check_tool_version("gcc", GCC_MIN_VER) or not _check_tool_version("clang", CLANG_MIN_VER) then
            return
        end
    else
        return
    end

    local cl_str = "modules\\std.ixx"
    local clang_str = is_host("windows") and "v1\\std.cppm" or "v1/std.cppm"
    local gcc_str = "v1/std.cppm"

    local flags = true and "-vD" or ""
    local outdata
    outdata = os.iorun("xmake -r " ..  flags)
    if outdata then
        local success = false
        -- on windows, llvm libc++ std module is currently not supported, uncommend when supported
        if is_subhost("windows") then
            success = outdata:find(cl_str, 1, true) -- and outdata:find(clang_str, 1, true)
        else
            success = outdata:find(gcc_str, 1, true) and outdata:find(clang_str, 1, true)
        end
        if not success then
            raise("Multiple runtimes doesn't work\n%s", outdata)
        end
    end
end
