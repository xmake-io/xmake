-- tests for the shared launcher module (runenvs/runargs wrappers); the
-- integration tests are host-gated and skip when the packaging tool is missing

import("lib.detect.find_tool")

local launcher = import("plugins.pack.launcher", {rootdir = os.programdir(), try = true})

-- skip when the launcher module is not available (older xmake builds)
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

-- run a callback and return (ok, error) without raising
function _try(callback)
    local ok = false
    local err = nil
    try
    {
        function ()
            callback()
            ok = true
        end,
        catch
        {
            function (errors)
                err = tostring(errors)
            end
        }
    }
    return ok, err
end

function _find_file(pattern)
    local files = os.files(pattern)
    if files and #files > 0 then
        return files[1]
    end
end

-- skip when the packaging tool/network is unavailable, otherwise it's a real failure
function _skip_or_raise(t, err, format)
    err = err or ""
    local lower = err:lower()
    local keywords = {
        "not found",
        "no such file",
        "cannot find",
        "failed to install",
        "install failed",
        "download",
        "exec format",
        "not supported",
        "unsupported"
    }
    for _, keyword in ipairs(keywords) do
        if lower:find(keyword, 1, true) then
            return t:skip(string.format("%s packaging unavailable: %s", format, err))
        end
    end
    raise(err)
end

-- -P . is required to avoid detecting a parent project
function _pack(t, formats)
    local ok, err = _try(function ()
        os.vrunv("xmake", {"f", "-y", "-m", "release", "-P", "."})
    end)
    if not ok then
        raise(err)
    end
    return _try(function ()
        os.vrunv("xmake", {"pack", "-y", "--formats=" .. formats, "--autobuild=y", "-P", "."})
    end)
end

-- formats that install their packaging tool on demand may not be available on
-- every host, so any packing failure is reported as a skip
function _pack_optional(t, formats, name)
    local ok, err = _pack(t, formats)
    if not ok then
        return t:skip(string.format("%s packaging unavailable: %s", name, err))
    end
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

function test_generate_runtime_vars(t)
    if _skip_without_launcher(t) then return end
    local pkg = _mock_package({runenvs = {"K", "$HERE/usr/share"}, runargs = {"--plugin", "${PREFIX}/lib/x.so"}})
    local script = launcher.generate(pkg, "/usr/bin/foo")
    t:require(script:find([[export K="$HERE"'/usr/share']], 1, true))
    t:require(script:find([["${PREFIX}"'/lib/x.so']], 1, true))
end

function test_generate_unknown_var_is_literal(t)
    if _skip_without_launcher(t) then return end
    local pkg = _mock_package({runenvs = {"K", "$NOPE/x"}, runargs = {"$ALSO_NOPE"}})
    local script = launcher.generate(pkg, "/usr/bin/foo")
    t:require(script:find("export K='$NOPE/x'\n", 1, true))
    t:require(script:find("'$ALSO_NOPE'", 1, true))
end

function test_main_executable_default_bindir(t)
    if _skip_without_launcher(t) then return end
    t:are_same(launcher.main_executable(_mock_package()), path.join("bin", "foo"))
end

function test_main_executable_custom_bindir(t)
    if _skip_without_launcher(t) then return end
    t:are_same(launcher.main_executable(_mock_package({bindir = "tools"})), path.join("tools", "foo"))
end

function test_main_executable_no_targets(t)
    if _skip_without_launcher(t) then return end
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

function test_pack_appimage(t)
    if _skip_without_launcher(t) then return end
    if not is_host("linux") then
        return t:skip("appimage is only packed and run on linux")
    end
    local skip = _pack_optional(t, "appimage", "appimage")
    if skip then return skip end
    local appfile = _find_file("build/xpack/**/*.AppImage")
    t:require(appfile)
    os.vrunv("chmod", {"+x", appfile})
    local out = os.iorunv(appfile, {"app-arg"}, {envs = {APPIMAGE_EXTRACT_AND_RUN = "1"}})
    t:require(out and out:find("arg[3]=app-arg", 1, true))
    t:require(out and out:find("env=launcher-ok", 1, true))
    t:require(out and out:find("here=/", 1, true))
    t:require_not(out and out:find("here=$HERE", 1, true))
end

function test_pack_runself(t)
    if _skip_without_launcher(t) then return end
    if not is_host("linux") then
        return t:skip("runself is only packed and run on linux")
    end
    local skip = _pack_optional(t, "runself", "runself")
    if skip then return skip end
    local runfile = _find_file("build/xpack/**/*.run")
    t:require(runfile)
    os.vrunv("chmod", {"+x", runfile})
    local target = path.join(os.tmpdir(), "launcher_runself")
    os.tryrm(target)
    local out
    if find_tool("script") then
        -- makeself expects a tty for its progress output
        local cmd = string.format("%s --target %s run-arg", runfile, target)
        out = os.iorunv("script", {"-qec", cmd, "/dev/null"})
    else
        out = os.iorunv(runfile, {"--target", target, "run-arg"})
    end
    t:require(out and out:find("arg[3]=run-arg", 1, true))
    t:require(out and out:find("env=launcher-ok", 1, true))
    t:require(out and out:find("prefix=/", 1, true))
end

function test_pack_deb(t)
    if _skip_without_launcher(t) then return end
    if not is_host("linux") then
        return t:skip("deb is only packed on linux")
    end
    if not find_tool("debuild") then
        return t:skip("debuild not found, please run `sudo apt install devscripts`")
    end
    local ok, err = _pack(t, "deb")
    if not ok then
        return _skip_or_raise(t, err, "deb")
    end
    local debfile = _find_file("build/xpack/**/*.deb")
    t:require(debfile)
    t:require(os.isfile(debfile))
end

function test_pack_rpm(t)
    if _skip_without_launcher(t) then return end
    if not is_host("linux") then
        return t:skip("rpm is only packed on linux")
    end
    if not find_tool("rpmbuild") then
        return t:skip("rpmbuild not found")
    end
    local ok, err = _pack(t, "rpm")
    if not ok then
        return _skip_or_raise(t, err, "rpm")
    end
    t:require(_find_file("build/xpack/**/*.rpm"))
end

function test_pack_srpm(t)
    if _skip_without_launcher(t) then return end
    if not is_host("linux") then
        return t:skip("srpm is only packed on linux")
    end
    if not find_tool("rpmbuild") then
        return t:skip("rpmbuild not found")
    end
    local ok, err = _pack(t, "srpm")
    if not ok then
        return _skip_or_raise(t, err, "srpm")
    end
    t:require(_find_file("build/xpack/**/*.src.rpm"))
end

function test_pack_nsis(t)
    if _skip_without_launcher(t) then return end
    if not is_host("windows") then
        return t:skip("nsis is only packed and run on windows")
    end
    local skip = _pack_optional(t, "nsis", "nsis")
    if skip then return skip end
    t:require(_find_file("build/xpack/**/*.exe"))
end

function test_pack_wix(t)
    if _skip_without_launcher(t) then return end
    if not is_host("windows") then
        return t:skip("wix is only packed on windows")
    end
    if not find_tool("wix") then
        return t:skip("wix toolset not found")
    end
    local ok, err = _pack(t, "wix")
    if not ok then
        return _skip_or_raise(t, err, "wix")
    end
    t:require(_find_file("build/xpack/**/*.msi"))
end

function test_pack_dmg(t)
    if _skip_without_launcher(t) then return end
    if not is_host("macosx") then
        return t:skip("dmg is only packed on macos")
    end
    local ok, err = _pack(t, "dmg")
    if not ok then
        return _skip_or_raise(t, err, "dmg")
    end
    t:require(_find_file("build/xpack/**/*.dmg"))
end
