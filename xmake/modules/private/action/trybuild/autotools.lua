--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        autotools.lua
--

-- imports
import("core.base.cli")
import("core.base.option")
import("core.project.config")
import("core.platform.platform")
import("lib.detect.find_file")

-- translate path
function _translate_path(p)
    if p and is_host("windows") and is_plat("mingw") then
        p = p:gsub("\\", "/")
    end
    return p
end

-- translate windows bin path
function _translate_windows_bin_path(bin_path)
    if bin_path then
        local argv = os.argv(bin_path)
        argv[1] = argv[1]:gsub("\\", "/") .. ".exe"
        return os.args(argv)
    end
end

-- get build directory
function _get_buildir()
    return config.buildir() or "build"
end

-- get artifacts directory
function _get_artifacts_dir()
    return path.absolute(path.join(_get_buildir(), "artifacts"))
end

-- get the build environment
function _get_buildenv(key)
    local value = config.get(key)
    if value == nil then
        value = platform.toolconfig(key, config.plat())
    end
    if value == nil then
        value = platform.tool(key, config.plat())
    end
    return value
end

-- get the build environments
function _get_buildenvs()
    local envs = {}
    if is_plat(os.subhost()) then
        local cflags   = table.join(table.wrap(_get_buildenv("cxflags")), _get_buildenv("cflags"))
        local cxxflags = table.join(table.wrap(_get_buildenv("cxflags")), _get_buildenv("cxxflags"))
        local asflags  = table.copy(table.wrap(_get_buildenv("asflags")))
        local ldflags  = table.copy(table.wrap(_get_buildenv("ldflags")))
        if is_plat("linux") and is_arch("i386") then
            table.insert(cflags,   "-m32")
            table.insert(cxxflags, "-m32")
            table.insert(asflags,  "-m32")
            table.insert(ldflags,  "-m32")
        end
        envs.CFLAGS    = table.concat(cflags, ' ')
        envs.CXXFLAGS  = table.concat(cxxflags, ' ')
        envs.ASFLAGS   = table.concat(asflags, ' ')
        envs.LDFLAGS   = table.concat(ldflags, ' ')
    else
        local cflags   = table.join(table.wrap(_get_buildenv("cxflags")), _get_buildenv("cflags"))
        local cxxflags = table.join(table.wrap(_get_buildenv("cxflags")), _get_buildenv("cxxflags"))
        envs.CC        = _get_buildenv("cc")
        envs.AS        = _get_buildenv("as")
        envs.AR        = _get_buildenv("ar")
        envs.LD        = _get_buildenv("ld")
        envs.LDSHARED  = _get_buildenv("sh")
        envs.CPP       = _get_buildenv("cpp")
        envs.RANLIB    = _get_buildenv("ranlib")
        envs.CFLAGS    = table.concat(cflags, ' ')
        envs.CXXFLAGS  = table.concat(cxxflags, ' ')
        envs.ASFLAGS   = table.concat(table.wrap(_get_buildenv("asflags")), ' ')
        envs.ARFLAGS   = table.concat(table.wrap(_get_buildenv("arflags")), ' ')
        envs.LDFLAGS   = table.concat(table.wrap(_get_buildenv("ldflags")), ' ')
        envs.SHFLAGS   = table.concat(table.wrap(_get_buildenv("shflags")), ' ')
        if #envs.ARFLAGS == 0 then
            if envs.AR and envs.AR:endswith("ar") then
                envs.ARFLAGS = "-cr"
            end
        end
        if is_plat("mingw") then
            -- fix linker error, @see https://github.com/xmake-io/xmake/issues/574
            -- libtool: line 1855: lib: command not found
            envs.ARFLAGS = nil
            local ld = envs.LD
            if ld then
                if ld:endswith("x86_64-w64-mingw32-g++") then
                    envs.LD = path.join(path.directory(ld), is_host("windows") and "ld" or "x86_64-w64-mingw32-ld")
                elseif ld:endswith("i686-w64-mingw32-g++") then
                    envs.LD = path.join(path.directory(ld), is_host("windows") and "ld" or "i686-w64-mingw32-ld")
                end
            end
            if is_host("windows") then
                envs.CC       = _translate_windows_bin_path(envs.CC)
                envs.AS       = _translate_windows_bin_path(envs.AS)
                envs.AR       = _translate_windows_bin_path(envs.AR)
                envs.LD       = _translate_windows_bin_path(envs.LD)
                envs.LDSHARED = _translate_windows_bin_path(envs.LDSHARED)
                envs.CPP      = _translate_windows_bin_path(envs.CPP)
                envs.RANLIB   = _translate_windows_bin_path(envs.RANLIB)
            end
        end
    end
    if option.get("verbose") then
        print(envs)
    end
    return envs
end

-- get configs
function _get_configs(artifacts_dir)

    -- add prefix
    local configs = {}
    table.insert(configs, "--prefix=" .. _translate_path(artifacts_dir))

    -- add extra user configs
    local tryconfigs = config.get("tryconfigs")
    if tryconfigs then
        for _, opt in ipairs(cli.parse(tryconfigs)) do
            table.insert(configs, tostring(opt))
        end
    end

    -- add host for cross-complation
    if not is_plat(os.subhost()) then
        if is_plat("iphoneos") then
            local triples =
            {
                arm64  = "aarch64-apple-darwin",
                arm64e = "aarch64-apple-darwin",
                armv7  = "armv7-apple-darwin",
                armv7s = "armv7s-apple-darwin",
                i386   = "i386-apple-darwin",
                x86_64 = "x86_64-apple-darwin"
            }
            table.insert(configs, "--host=" .. (triples[config.arch()] or triples.arm64))
        elseif is_plat("android") then
            -- @see https://developer.android.com/ndk/guides/other_build_systems#autoconf
            local triples =
            {
                ["armv5te"]     = "arm-linux-androideabi",  -- deprecated
                ["armv7-a"]     = "arm-linux-androideabi",  -- deprecated
                ["armeabi"]     = "arm-linux-androideabi",  -- removed in ndk r17
                ["armeabi-v7a"] = "arm-linux-androideabi",
                ["arm64-v8a"]   = "aarch64-linux-android",
                i386            = "i686-linux-android",     -- deprecated
                x86             = "i686-linux-android",
                x86_64          = "x86_64-linux-android",
                mips            = "mips-linux-android",     -- removed in ndk r17
                mips64          = "mips64-linux-android"    -- removed in ndk r17
            }
            table.insert(configs, "--host=" .. (triples[config.arch()] or triples["armeabi-v7a"]))
        elseif is_plat("mingw") then
            local triples =
            {
                i386   = "i686-w64-mingw32",
                x86_64 = "x86_64-w64-mingw32"
            }
            table.insert(configs, "--host=" .. (triples[config.arch()] or triples.i386))
        else
            raise("autotools: unknown platform(%s)!", config.plat())
        end
    end
    return configs
end

-- detect build-system and configuration file
function detect()
    if not is_subhost("windows") then
        return find_file("configure", os.curdir()) or find_file("configure.ac", os.curdir())
    end
end

-- do clean
function clean()
    if find_file("[mM]akefile", os.curdir()) then
        if option.get("all") then
            os.vexec("make distclean")
            os.tryrm(_get_artifacts_dir())
        else
            os.vexec("make clean")
        end
    end
end

-- do build
function build()

    -- get artifacts directory
    local artifacts_dir = _get_artifacts_dir()
    if not os.isdir(artifacts_dir) then
        os.mkdir(artifacts_dir)
    end

    -- generate configure
    if not os.isfile("configure") then
        if os.isfile("autogen.sh") then
            os.vexecv("sh", {"./autogen.sh"})
        elseif os.isfile("configure.ac") then
            os.vexec("autoreconf --install --symlink")
        end
    end

    -- do configure
    local configfile = find_file("[mM]akefile", os.curdir())
    if not configfile or os.mtime(config.filepath()) > os.mtime(configfile) then
        os.vexecv("sh", table.join("./configure", _get_configs(artifacts_dir)), {envs = _get_buildenvs()})
    end

    -- do build
    local argv = {"-j" .. option.get("jobs")}
    if option.get("verbose") then
        table.insert(argv, "V=1")
    end
    if is_host("bsd") then
        os.vexecv("gmake", argv)
        os.vexec("gmake install")
    else
        os.vexecv("make", argv)
        os.vexec("make install")
    end
    cprint("output to ${bright}%s", artifacts_dir)
    cprint("${color.success}build ok!")
end
