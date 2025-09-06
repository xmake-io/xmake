import("lib.detect.find_tool")

function test_config(t)

    -- xmake
    os.tryrm("build")
    local xmake_dt = os.mclock()
    os.runv(os.programfile(), {"config", "-c"})
    xmake_dt = os.mclock() - xmake_dt
    print("config targets/1k: xmake: %d ms", xmake_dt)

    -- cmake
    local cmake = find_tool("cmake")
    if cmake then
        if find_tool("ninja") then
            os.tryrm("build")
            os.mkdir("build")
            local cmake_ninja_dt = os.mclock()
            os.runv(cmake.program, {"..", "-G", "Ninja"}, {curdir = "build"})
            cmake_ninja_dt = os.mclock() - cmake_ninja_dt
            print("config targets/1k: cmake/ninja: %d ms", cmake_ninja_dt)
            t:require((cmake_ninja_dt > xmake_dt) or (cmake_ninja_dt + 1000 > xmake_dt))
        end

        if find_tool("make") then
            os.tryrm("build")
            os.mkdir("build")
            local cmake_makefile_dt = os.mclock()
            os.runv(cmake.program, {"..", "-G", "Unix Makefiles"}, {curdir = "build"})
            cmake_makefile_dt = os.mclock() - cmake_makefile_dt
            print("config targets/1k: cmake/makefile: %d ms", cmake_makefile_dt)
            t:require((cmake_makefile_dt > xmake_dt) or (cmake_makefile_dt + 1000 > xmake_dt))
        end
    end

    -- meson
    local meson = find_tool("meson")
    if meson then
        os.tryrm("build")
        local meson_dt = os.mclock()
        os.runv(meson.program, {"setup", "build"})
        meson_dt = os.mclock() - meson_dt
        print("config targets/1k: meson: %d ms", meson_dt)
        t:require((meson_dt > xmake_dt) or (meson_dt + 1000 > xmake_dt))
    end
end

