import("lib.detect.find_tool")
import("core.tool.toolchain")

function test_build(t)

    -- xmake
    os.tryrm("build")
    local xmake_dt = os.mclock()
    os.run("xmake")
    xmake_dt = os.mclock() - xmake_dt
    print("build targets/30: xmake: %d ms", xmake_dt)

    -- cmake
    local cmake = find_tool("cmake")
    if cmake then
        os.tryrm("build")
        os.mkdir("build")
        local cmake_default_dt = os.mclock()
        os.runv(cmake.program, {".."}, {curdir = "build"})
        os.runv(cmake.program, {"--build", "."}, {curdir = "build"})
        cmake_default_dt = os.mclock() - cmake_default_dt
        print("build targets/30: cmake/default: %d ms", cmake_default_dt)
        t:require((cmake_default_dt > xmake_dt) or (cmake_default_dt + 2000 > xmake_dt))

        local ninja = find_tool("ninja")
        if ninja then
            os.tryrm("build")
            os.mkdir("build")
            local configs = {}
            local envs
            if is_host("windows") then
                table.insert(configs, "-DCMAKE_MAKE_PROGRAM=" .. ninja.program)
                local msvc = toolchain.load("msvc")
                if msvc:check() then
                    table.insert(configs, "-DCMAKE_CXX_COMPILER=" .. (msvc:tool("cxx")))
                    table.insert(configs, "-DCMAKE_C_COMPILER=" .. (msvc:tool("cc")))
                    envs = os.joinenvs(msvc:runenvs())
                end
            end
            local cmake_ninja_dt = os.mclock()
            os.runv(cmake.program, table.join("..", "-G", "Ninja", configs), {curdir = "build", envs = envs})
            os.runv(cmake.program, {"--build", "."}, {curdir = "build", envs = envs})
            cmake_ninja_dt = os.mclock() - cmake_ninja_dt
            print("build targets/30: cmake/ninja: %d ms", cmake_ninja_dt)
            -- TODO we need to improve it
            --t:require((cmake_ninja_dt > xmake_dt) or (cmake_ninja_dt + 2000 > xmake_dt))
        end

        local make = find_tool("make")
        if make and not is_subhost("windows") then
            os.tryrm("build")
            os.mkdir("build")
            local cmake_makefile_dt = os.mclock()
            os.runv(cmake.program, {"..", "-G", "Unix Makefiles"}, {curdir = "build"})
            os.runv(cmake.program, {"--build", "."}, {curdir = "build"})
            cmake_makefile_dt = os.mclock() - cmake_makefile_dt
            print("build targets/30: cmake/makefile: %d ms", cmake_makefile_dt)
            t:require((cmake_makefile_dt > xmake_dt) or (cmake_makefile_dt + 2000 > xmake_dt))
        end
    end

    -- meson
    local meson = find_tool("meson")
    if meson then
        os.tryrm("build")
        local meson_dt = os.mclock()
        os.runv(meson.program, {"setup", "build"})
        os.runv(meson.program, {"compile", "-C", "build"})
        meson_dt = os.mclock() - meson_dt
        print("build targets/30: meson: %d ms", meson_dt)
        --t:require((meson_dt > xmake_dt) or (meson_dt + 2000 > xmake_dt))
    end
end


