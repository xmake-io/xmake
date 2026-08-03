-- Unit tests for the shared launcher module (runenvs/runargs wrappers).
-- These run in CI on every platform via `tests/run.lua` and need no packaging
-- tools: they exercise the pure logic of plugins.pack.launcher with a mock
-- package object.

local launcher = import("plugins.pack.launcher", {rootdir = os.programdir(), try = true})

-- the launcher module may not exist in older xmake builds (e.g. CI on the dev
-- branch), in which case the tests are skipped rather than failed
function _skip_without_launcher(t)
    if not launcher then
        return t:skip("launcher module not available in this xmake build")
    end
end

function _mock_package(opt)
    opt = opt or {}
    local target = {
        is_binary = function () return true end,
        basename = function () return "foo" end
    }
    return {
        get = function (_, key)
            return opt[key]
        end,
        targets = function ()
            return opt.targets or {target}
        end,
        installdir = function ()
            return opt.installdir or "/nonexistent/installed"
        end,
        builddir = function ()
            return opt.builddir or path.join(os.tmpdir(), "launcher-test")
        end
    }
end

function test_generate_empty(t)
    if _skip_without_launcher(t) then return end
    t:require_not(launcher.generate(_mock_package(), "/usr/bin/foo"))
    t:require_not(launcher.generate(_mock_package({runenvs = {}}), "/usr/bin/foo"))
    t:require_not(launcher.generate(_mock_package({runargs = {}}), "/usr/bin/foo"))
end

function test_generate_envs_and_args(t)
    if _skip_without_launcher(t) then return end
    local pkg = _mock_package({runenvs = {"XMAKE_TEST_ENV", "launcher-ok"}, runargs = {"--mode", "test"}})
    t:are_same(launcher.generate(pkg, "/usr/bin/foo"),
        "#!/bin/sh\nexport XMAKE_TEST_ENV='launcher-ok'\nexec \"/usr/bin/foo\" '--mode' 'test' \"$@\"\n")
end

function test_generate_quoting(t)
    if _skip_without_launcher(t) then return end
    -- values/args with spaces and single quotes must be escaped
    local pkg = _mock_package({runenvs = {"K", "it's a value"}, runargs = {"--opt=a b"}})
    local script = launcher.generate(pkg, "/usr/bin/foo")
    t:require(script:find("export K='it'\\''s a value'\n", 1, true))
    t:require(script:find("'--opt=a b'", 1, true))
end

function test_generate_empty_env_value(t)
    if _skip_without_launcher(t) then return end
    local pkg = _mock_package({runenvs = {"K", ""}, runargs = {"--x"}})
    t:require(launcher.generate(pkg, "/usr/bin/foo"):find("export K=''\n", 1, true))
end

function test_main_executable_default_bindir(t)
    if _skip_without_launcher(t) then return end
    t:are_same(launcher.main_executable(_mock_package()), "bin/foo")
end

function test_main_executable_custom_bindir(t)
    if _skip_without_launcher(t) then return end
    t:are_same(launcher.main_executable(_mock_package({bindir = "tools"})), "tools/foo")
end

function test_main_executable_no_targets(t)
    if _skip_without_launcher(t) then return end
    -- no binary targets and no installed bindir -> nil
    t:require_not(launcher.main_executable(_mock_package({targets = {}})))
end

function test_launcher_info(t)
    if _skip_without_launcher(t) then return end
    if is_host("windows") then
        return t:skip("launcher_info writes + chmods a shell script, posix only")
    end
    local pkg = _mock_package({runenvs = {"K", "V"}, runargs = {"--x"}})
    local info = launcher.launcher_info(pkg)
    t:require(info)
    t:are_same(info.launcher_exe, "bin/foo")
    t:are_same(info.real_rel, "bin/foo-real")
    t:are_same(info.exec_path, "/usr/bin/foo-real")
    t:require(os.isfile(info.wrapperfile))
end

function test_launcher_info_empty(t)
    if _skip_without_launcher(t) then return end
    if is_host("windows") then
        return t:skip("launcher_info writes + chmods a shell script, posix only")
    end
    t:require_not(launcher.launcher_info(_mock_package()))
end
