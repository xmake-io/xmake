import("lib.detect.find_tool")
import("core.tool.toolchain")

function test_build(t)

    if xmake.is_embed() then
        return
    end

    local jobs = tostring(os.default_njob())

    -- xmake
    os.tryrm("build")
    os.tryrm(".xmake")
    local xmake_dt = os.mclock()
    os.runv("xmake", {"-j" .. jobs})
    xmake_dt = os.mclock() - xmake_dt
    print("build targets/30: xmake: %d ms", xmake_dt)

    -- cmake
    local cmake = find_tool("cmake")
    if cmake then
        os.tryrm("build")
        os.mkdir("build")
        local cmake_default_dt = os.mclock()
        os.runv(cmake.program, {".."}, {curdir = "build"})
        os.runv(cmake.program, {"--build", ".", "-j" .. jobs}, {curdir = "build"})
        cmake_default_dt = os.mclock() - cmake_default_dt
        print("build targets/30: cmake/default: %d ms", cmake_default_dt)
        t:require((cmake_default_dt > xmake_dt) or (cmake_default_dt + 3000 > xmake_dt))

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
            os.runv(cmake.program, {"--build", ".", "-j" .. jobs}, {curdir = "build", envs = envs})
            cmake_ninja_dt = os.mclock() - cmake_ninja_dt
            print("build targets/30: cmake/ninja: %d ms", cmake_ninja_dt)
            t:require((cmake_ninja_dt > xmake_dt) or (cmake_ninja_dt + 3000 > xmake_dt))
        end

        local make = find_tool("make")
        if make and not is_subhost("windows") then
            os.tryrm("build")
            os.mkdir("build")
            local cmake_makefile_dt = os.mclock()
            os.runv(cmake.program, {"..", "-G", "Unix Makefiles"}, {curdir = "build"})
            os.runv(cmake.program, {"--build", ".", "-j" .. jobs}, {curdir = "build"})
            cmake_makefile_dt = os.mclock() - cmake_makefile_dt
            print("build targets/30: cmake/makefile: %d ms", cmake_makefile_dt)
            t:require((cmake_makefile_dt > xmake_dt) or (cmake_makefile_dt + 3000 > xmake_dt))
        end
    end

    -- meson
    local meson = find_tool("meson")
    if meson then
        os.tryrm("build")
        local meson_setup_dt = os.mclock()
        os.runv(meson.program, {"setup", "build"})
        meson_setup_dt = os.mclock() - meson_setup_dt

        -- ccache will cache object files globally, which may affect the results of the second run.
        io.replace("build/build.ninja", "ccache", "")

        local meson_build_dt = os.mclock()
        os.runv(meson.program, {"compile", "-j", jobs, "-C", "build"})
        meson_build_dt = os.mclock() - meson_build_dt
        local meson_dt = meson_setup_dt + meson_build_dt
        print("build targets/30: meson: %d ms", meson_dt)
        t:require((meson_dt > xmake_dt) or (meson_dt + 3000 > xmake_dt))
    end
end


