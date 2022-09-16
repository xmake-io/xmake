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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        meson.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.platform.platform")
import("lib.detect.find_file")
import("lib.detect.find_tool")

-- get build directory
function _get_buildir()
    return config.buildir() or "build"
end

-- get artifacts directory
function _get_artifacts_dir()
    return path.absolute(path.join(_get_buildir(), "artifacts"))
end

-- is cross compilation?
function _is_cross_compilation()
    if not is_plat(os.subhost()) then
        return true
    end
    if is_plat("macosx") and not is_arch(os.subarch()) then
        return true
    end
    return false
end

-- get pkg-config
function _get_pkgconfig()
    if is_plat("windows") then
        local pkgconf = find_tool("pkgconf")
        if pkgconf then
            return pkgconf.program
        end
    end
    local pkgconfig = find_tool("pkg-config")
    if pkgconfig then
        return pkgconfig.program
    end
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

-- get cross file
function _get_cross_file(buildir)
    local crossfile = path.join(buildir, "cross_file.txt")
    if not os.isfile(crossfile) then
        local file = io.open(crossfile, "w")
        -- binaries
        file:print("[binaries]")
        local cc = _get_buildenv("cc")
        if cc then
            -- we need split it, maybe is `xcrun -sdk iphoneos clang`
            file:print("c=['%s']", table.concat(os.argv(cc), "', '"))
        end
        local cxx = _get_buildenv("cxx")
        if cxx then
            file:print("cpp=['%s']", table.concat(os.argv(cxx), "', '"))
        end
        local ld = _get_buildenv("ld")
        if ld then
            file:print("ld=['%s']", table.concat(os.argv(ld), "', '"))
        end
        local ar = _get_buildenv("ar")
        if ar then
            file:print("ar=['%s']", table.concat(os.argv(ar), "', '"))
        end
        local strip = _get_buildenv("strip")
        if strip then
            file:print("strip='%s'", strip)
        end
        local ranlib = _get_buildenv("ranlib")
        if ranlib then
            file:print("ranlib='%s'", ranlib)
        end
        if is_plat("mingw") then
            local mrc = _get_buildenv("mrc")
            if mrc then
                file:print("windres='%s'", mrc)
            end
        end
        local cmake = find_tool("cmake")
        if cmake then
            file:print("cmake='%s'", cmake.program)
        end
        local pkgconfig = _get_pkgconfig()
        if pkgconfig then
            file:print("pkgconfig='%s'", pkgconfig)
        end
        file:print("")

        -- built-in options
        file:print("[built-in options]")
        local cflags   = table.join(table.wrap(_get_buildenv("cxflags")), _get_buildenv("cflags"))
        local cxxflags = table.join(table.wrap(_get_buildenv("cxflags")), _get_buildenv("cxxflags"))
        local asflags  = table.wrap(_get_buildenv("asflags"))
        local arflags  = table.wrap(_get_buildenv("arflags"))
        local ldflags  = table.wrap(_get_buildenv("ldflags"))
        local shflags  = table.wrap(_get_buildenv("shflags"))
        if #cflags > 0 then
            file:print("c_args=['%s']", table.concat(cflags, "', '"))
        end
        if #cxxflags > 0 then
            file:print("cpp_args=['%s']", table.concat(cxxflags, "', '"))
        end
        local linkflags = table.join(ldflags or {}, shflags)
        if #linkflags > 0 then
            file:print("c_link_args=['%s']", table.concat(linkflags, "', '"))
            file:print("cpp_link_args=['%s']", table.concat(linkflags, "', '"))
        end
        file:print("")

        -- host machine
        file:print("[host_machine]")
        if is_plat("iphoneos", "macosx") then
            local cpu
            local cpu_family
            if is_arch("arm64") then
                cpu = "aarch64"
                cpu_family = "aarch64"
            elseif is_arch("armv7") then
                cpu = "arm"
                cpu_family = "arm"
            elseif is_arch("x64", "x86_64") then
                cpu = "x86_64"
                cpu_family = "x86_64"
            elseif is_arch("x86", "i386") then
                cpu = "i686"
                cpu_family = "x86"
            else
                raise("unsupported arch(%s)", config.arch())
            end
            file:print("system = 'darwin'")
            file:print("cpu_family = '%s'", cpu_family)
            file:print("cpu = '%s'", cpu)
            file:print("endian = 'little'")
        elseif is_plat("android") then
            -- TODO
            raise("android has been not supported now!")
        elseif is_plat("mingw") then
            local cpu
            local cpu_family
            if is_arch("x64", "x86_64") then
                cpu = "x86_64"
                cpu_family = "x86_64"
            elseif is_arch("x86", "i386") then
                cpu = "i686"
                cpu_family = "x86"
            else
                raise("unsupported arch(%s)", config.arch())
            end
            file:print("system = 'windows'")
            file:print("cpu_family = '%s'", cpu_family)
            file:print("cpu = '%s'", cpu)
            file:print("endian = 'little'")
        elseif is_plat("wasm") then
            file:print("system = 'emscripten'")
            file:print("cpu_family = 'wasm32'")
            file:print("cpu = 'wasm32'")
            file:print("endian = 'little'")
        elseif is_plat("cross") then
            local cpu = config.arch()
            if is_arch("arm64") then
                cpu = "aarch64"
            elseif is_arch("arm.*") then
                cpu = "arm"
            end
            local cpu_family = cpu
            file:print("system = '%s'", get_config("target_os") or "linux")
            file:print("cpu_family = '%s'", cpu_family)
            file:print("cpu = '%s'", cpu)
            file:print("endian = 'little'")
        end
        file:print("")
        file:close()
    end
    return crossfile
end

-- get configs
function _get_configs(artifacts_dir, buildir)

    -- add prefix
    local configs = {"--prefix=" .. artifacts_dir}
    if configfile then
        table.insert(configs, "--reconfigure")
    end

    -- add extra user configs
    local tryconfigs = config.get("tryconfigs")
    if tryconfigs then
        for _, opt in ipairs(os.argv(tryconfigs)) do
            table.insert(configs, tostring(opt))
        end
    end

    -- add cross file
    if _is_cross_compilation() then
        table.insert(configs, "--cross-file=" .. _get_cross_file(buildir))
    end

    -- add build directory
    table.insert(configs, buildir)
    return configs
end

-- detect build-system and configuration file
function detect()
    return find_file("meson.build", os.curdir())
end

-- do clean
function clean()
    local buildir = _get_buildir()
    if os.isdir(buildir) then
        local configfile = find_file("build.ninja", buildir)
        if configfile then
            local ninja = assert(find_tool("ninja"), "ninja not found!")
            local ninja_argv = {"-C", buildir}
            if option.get("verbose") or option.get("diagnosis") then
                table.insert(ninja_argv, "-v")
            end
            table.insert(ninja_argv, "-t")
            table.insert(ninja_argv, "clean")
            os.vexecv(ninja.program, ninja_argv)
            if option.get("all") then
                os.tryrm(buildir)
            end
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

    -- generate makefile
    local buildir = _get_buildir()
    local meson = assert(find_tool("meson"), "meson not found!")
    local configfile = find_file("build.ninja", buildir)
    if not configfile or os.mtime(config.filepath()) > os.mtime(configfile) then
        os.vexecv(meson.program, _get_configs(artifacts_dir, buildir))
    end

    -- do build
    local ninja = assert(find_tool("ninja"), "ninja not found!")
    local ninja_argv = {"-C", buildir}
    if option.get("verbose") then
        table.insert(ninja_argv, "-v")
    end
    table.insert(ninja_argv, "-j")
    table.insert(ninja_argv, option.get("jobs"))
    os.vexecv(ninja.program, ninja_argv)
    os.vexecv(ninja.program, table.join("install", ninja_argv))
    cprint("output to ${bright}%s", artifacts_dir)
    cprint("${color.success}build ok!")
end
