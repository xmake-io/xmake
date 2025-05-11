import("lib.detect.find_tool")
import("core.base.semver")
import("core.tool.toolchain")
import("utils.ci.is_running", {alias = "ci_is_running"})

function _gen_cmakelist()
    if not os.isfile("CMakeLists.txt") then
        os.vrunv("xmake project -k cmake")
    end
end

function _build(name, opt)
    opt = opt or {}
    local build_args = {}
    if ci_is_running() then
        table.insert(build_args, "-vD")
    end
    os.rm(".xmake", "build")
    os.mv("xmake.lua", "xmake.lua_")
    os.vrunv("xmake", table.join({"f", "--trybuild=cmake", "--toolchain=" .. name}, build_args), {shell = true, envs = opt.envs})
    os.vrunv("xmake", table.join({"b"}, build_args), {shell = true, envs = opt.envs})
    os.mv("xmake.lua_", "xmake.lua")
end

function _build_with(name, minver)
    if name == "msvc" then
        local _toolchain = toolchain.load(name, {plat = os.host(), arch = os.arch()})
        if _toolchain and _toolchain:check() then
            local vcvars = _toolchain:config("vcvars")
            if vcvars and vcvars.VCToolsVersion and semver.compare(vcvars.VCToolsVersion, minver) >= 0 then
                _build(name, {envs = vcvars})
            end
        end
    else
        local tool = find_tool(name, {version = true})
        if tool and tool.version and semver.compare(tool.version, minver) >= 0 then
            local _toolchain = toolchain.load(name, {plat = os.host(), arch = os.arch()})
            if _toolchain and _toolchain:check() then
                _build(name)
            end
        end
    end
end

function main(t)
    os.setenv("CMAKE_GENERATOR", "Ninja")

    local cmake = find_tool("cmake", {version = true})
    local ninja = find_tool("ninja")
    if ninja and cmake and cmake.version and semver.compare(cmake.version, "3.28") >= 0 then
        _gen_cmakelist()
        if is_subhost("windows") then
            _build_with("clang", "19")
            _build_with("msvc", "14.35")
        elseif is_subhost("linux") then
            _build_with("gcc", "14")
            _build_with("clang", "19")
        end
    end
end
