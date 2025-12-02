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

function test_config(t)

    -- 20% random trigger
    if math.random() > 0.2 then
        return
    end

    if xmake.is_embed() then
        return
    end

    -- xmake
    local xmake_dt = run_test(function ()
        local dt = os.mclock()
        os.tryrm("build")
        os.tryrm(".xmake")
        dt = os.mclock() - dt
        os.runv("xmake", {"config", "-c"})
        return dt
    end)
    print("config targets/1k: xmake: %d ms", xmake_dt)

    -- cmake
    local cmake = find_tool("cmake")
    if cmake then
        local cmake_default_dt = run_test(function()
            local dt = os.mclock()
            os.tryrm("build")
            os.mkdir("build")
            dt = os.mclock() - dt
            os.runv(cmake.program, {".."}, {curdir = "build"})
            return dt
        end)
        print("config targets/1k: cmake/default: %d ms", cmake_default_dt)
        t:require((cmake_default_dt > xmake_dt) or (cmake_default_dt + 2000 > xmake_dt))

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
            local cmake_ninja_dt = run_test(function()
                local dt = os.mclock()
                os.tryrm("build")
                os.mkdir("build")
                dt = os.mclock() - dt
                os.runv(cmake.program, table.join("..", "-G", "Ninja", configs), {curdir = "build", envs = envs})
                return dt
            end)
            print("config targets/1k: cmake/ninja: %d ms", cmake_ninja_dt)
            t:require((cmake_ninja_dt > xmake_dt) or (cmake_ninja_dt + 2000 > xmake_dt))
        end

        if find_tool("make") and not is_subhost("windows") then
            local cmake_makefile_dt = run_test(function ()
                local dt = os.mclock()
                os.tryrm("build")
                os.mkdir("build")
                dt = os.mclock() - dt
                os.runv(cmake.program, {"..", "-G", "Unix Makefiles"}, {curdir = "build"})
                return dt
            end)
            print("config targets/1k: cmake/makefile: %d ms", cmake_makefile_dt)
            t:require((cmake_makefile_dt > xmake_dt) or (cmake_makefile_dt + 2000 > xmake_dt))
        end
    end

    -- meson
    local meson = find_tool("meson")
    if meson then
        local meson_dt = run_test(function()
            local dt = os.mclock()
            os.tryrm("build")
            dt = os.mclock() - dt
            os.runv(meson.program, {"setup", "build"})
            return dt
        end)
        print("config targets/1k: meson: %d ms", meson_dt)
        t:require((meson_dt > xmake_dt) or (meson_dt + 2000 > xmake_dt))
    end
end


