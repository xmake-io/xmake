import("lib.detect.find_tool")
import("core.base.semver")
import("core.tool.toolchain")

function _cleanup()
    os.rm(".xmake", "build")
end

function _gen_cmakelist()
    if not os.isfile("CMakeLists.txt") then
        os.exec("xmake project -k cmake")
    end
end

function _build(t)
    os.mv("xmake.lua", "xmake.lua_")
    os.exec("xmake f --trybuild=cmake --toolchain=" .. t)
    os.exec("xmake b")
    os.mv("xmake.lua_", "xmake.lua")
end

function main(t)
    _cleanup()

    os.setenv("CMAKE_GENERATOR", "Ninja")

    local cmake = find_tool("cmake", {version = true})
    local ninja = find_tool("ninja")
    if ninja and cmake and cmake.version and semver.compare(cmake.version, "3.28") >= 0 then
        _gen_cmakelist()
        if is_subhost("windows") then
            local clang = find_tool("clang", {version = true})
            if clang and clang.version and semver.compare(clang.version, "18.0") >= 0 then
                _build("clang")
                _cleanup()
            end
            _build("msvc")
        elseif is_subhost("msys") or is_subhost("linux") then
            local gcc = find_tool("gcc", {version = true})
            if gcc and gcc.version and semver.compare(gcc.version, "14.0") >= 0 then
                _build("gcc")
                _cleanup()
            end
            local clang = find_tool("clang", {version = true})
            if clang and clang.version and semver.compare(clang.version, "18.0") >= 0 then
                _build("clang")
                _cleanup()
            end
        end
    end
end
