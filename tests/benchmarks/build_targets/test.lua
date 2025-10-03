import("lib.detect.find_tool")
import("core.tool.toolchain")

function run_test(func)
    local dt = os.mclock()
    local n = 2
    local delta = 0
    for i = 1, n do
        local e = func()
        delta = delta + e
    end
    dt = os.mclock() - dt - delta
    return math.floor(dt / n)
end

function test_build(t)

    if xmake.is_embed() then
        return
    end

    local jobs = tostring(os.default_njob())

    -- xmake
    local xmake_dt = run_test(function()
        local dt = os.mclock()
        os.tryrm("build")
        os.tryrm(".xmake")
        dt = os.mclock() - dt
        os.runv("xmake", {"-j" .. jobs})
        return dt
    end)
    print("build targets/30: xmake: %d ms", xmake_dt)

    -- cmake
    local cmake = find_tool("cmake")
    if cmake then
        local cmake_default_dt = run_test(function()
            local dt = os.mclock()
            os.tryrm("build")
            os.mkdir("build")
            dt = os.mclock() - dt
            os.runv(cmake.program, {".."}, {curdir = "build"})
            os.runv(cmake.program, {"--build", ".", "-j" .. jobs}, {curdir = "build"})
            return dt
        end)
        print("build targets/30: cmake/default: %d ms", cmake_default_dt)
        t:require((cmake_default_dt > xmake_dt) or (cmake_default_dt + 3000 > xmake_dt))

        local ninja = find_tool("ninja")
        if ninja then
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
            local cmake_ninja_dt = run_test(function ()
                local dt = os.mclock()
                os.tryrm("build")
                os.mkdir("build")
                dt = os.mclock() - dt
                os.runv(cmake.program, table.join("..", "-G", "Ninja", configs), {curdir = "build", envs = envs})
                os.runv(cmake.program, {"--build", ".", "-j" .. jobs}, {curdir = "build", envs = envs})
                return dt
            end)
            print("build targets/30: cmake/ninja: %d ms", cmake_ninja_dt)
            t:require((cmake_ninja_dt > xmake_dt) or (cmake_ninja_dt + 3000 > xmake_dt))
        end

        local make = find_tool("make")
        if make and not is_subhost("windows") then
            local cmake_makefile_dt = run_test(function()
                local dt = os.mclock()
                os.tryrm("build")
                os.mkdir("build")
                dt = os.mclock() - dt
                os.runv(cmake.program, {"..", "-G", "Unix Makefiles"}, {curdir = "build"})
                os.runv(cmake.program, {"--build", ".", "-j" .. jobs}, {curdir = "build"})
                return dt
            end)
            print("build targets/30: cmake/makefile: %d ms", cmake_makefile_dt)
            t:require((cmake_makefile_dt > xmake_dt) or (cmake_makefile_dt + 3000 > xmake_dt))
        end
    end

    -- meson
    local meson = find_tool("meson")
    if meson then
        local meson_dt = run_test(function()
            local dt1 = os.mclock()
            os.tryrm("build")
            dt1 = os.mclock() - dt1
            os.runv(meson.program, {"setup", "build"})
            -- ccache will cache object files globally, which may affect the results of the second run.
            local dt2 = os.mclock()
            io.replace("build/build.ninja", "ccache", "")
            dt2 = os.mclock() - dt2
            os.runv(meson.program, {"compile", "-j", jobs, "-C", "build"})
            return dt1 + dt2
        end)
        print("build targets/30: meson: %d ms", meson_dt)
        t:require((meson_dt > xmake_dt) or (meson_dt + 3000 > xmake_dt))
    end
end


