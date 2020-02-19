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
        value = platform.get(key, config.plat())
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
        local cflags   = table.join(table.wrap(config.get("cxflags")), config.get("cflags"))
        local cxxflags = table.join(table.wrap(config.get("cxflags")), config.get("cxxflags"))
        envs.CFLAGS    = table.concat(cflags, ' ')
        envs.CXXFLAGS  = table.concat(cxxflags, ' ')
        envs.ASFLAGS   = table.concat(table.wrap(config.get("asflags")), ' ')
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
                    envs.LD = path.join(path.directory(ld), "x86_64-w64-mingw32-ld")
                elseif ld:endswith("i686-w64-mingw32-g++") then
                    envs.LD = path.join(path.directory(ld), "i686-w64-mingw32-ld")
                end
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
    table.insert(configs, "--prefix=" .. artifacts_dir)

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
                ["armv5te"]     = "arm-linux-androideabi",
                ["armv7-a"]     = "arm-linux-androideabi",
                ["arm64-v8a"]   = "aarch64-linux-android",
                i386            = "i686-linux-android",
                x86_64          = "x86_64-linux-android",
                mips            = "mips-linux-android",
                mips64          = "mips64-linux-android"
            }
            table.insert(configs, "--host=" .. (triples[config.arch()] or triples["armv7-a"]))
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
    return find_file("configure", os.curdir()) or find_file("configure.ac", os.curdir())
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
        os.vexecv("./configure", _get_configs(artifacts_dir), {envs = _get_buildenvs()})
    end

    -- do build
    os.vexec("make -j" .. option.get("jobs"))
    os.vexec("make install")
    cprint("output to ${bright}%s", artifacts_dir)
    cprint("${bright}build ok!")
end


