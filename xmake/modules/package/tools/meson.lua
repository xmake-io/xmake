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
import("core.tool.toolchain")
import("core.tool.linker")
import("core.tool.compiler")
import("package.tools.ninja")
import("lib.detect.find_tool")

-- get build directory
function _get_buildir(package, opt)
    if opt and opt.buildir then
        return opt.buildir
    else
        _g.buildir = _g.buildir or package:buildir()
        return _g.buildir
    end
end

-- map compiler flags
function _map_compflags(package, langkind, name, values)
    return compiler.map_flags(langkind, name, values, {target = package})
end

-- map linker flags
function _map_linkflags(package, targetkind, sourcekinds, name, values)
    return linker.map_flags(targetkind, sourcekinds, name, values, {target = package})
end

-- is cross compilation?
function _is_cross_compilation(package)
    if not package:is_plat(os.subhost()) then
        return true
    end
    if package:is_plat("macosx") and not package:is_arch(os.subarch()) then
        return true
    end
    return false
end

-- get pkg-config
function _get_pkgconfig(package)
    if package:is_plat("windows") then
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

-- get cross file
function _get_cross_file(package, opt)
    opt = opt or {}
    local crossfile = path.join(_get_buildir(package, opt), "cross_file.txt")
    if not os.isfile(crossfile) then
        local file = io.open(crossfile, "w")
        -- binaries
        file:print("[binaries]")
        local cc = package:build_getenv("cc")
        if cc then
            -- we need split it, maybe is `xcrun -sdk iphoneos clang`
            file:print("c=['%s']", table.concat(os.argv(cc), "', '"))
        end
        local cxx = package:build_getenv("cxx")
        if cxx then
            file:print("cpp=['%s']", table.concat(os.argv(cxx), "', '"))
        end
        local ld = package:build_getenv("ld")
        if ld then
            file:print("ld=['%s']", table.concat(os.argv(ld), "', '"))
        end
        local ar = package:build_getenv("ar")
        if ar then
            file:print("ar=['%s']", table.concat(os.argv(ar), "', '"))
        end
        local strip = package:build_getenv("strip")
        if strip then
            file:print("strip='%s'", strip)
        end
        local ranlib = package:build_getenv("ranlib")
        if ranlib then
            file:print("ranlib='%s'", ranlib)
        end
        if package:is_plat("mingw") then
            local mrc = package:build_getenv("mrc")
            if mrc then
                file:print("windres='%s'", mrc)
            end
        end
        local cmake = find_tool("cmake")
        if cmake then
            file:print("cmake='%s'", cmake.program)
        end
        local pkgconfig = _get_pkgconfig(package)
        if pkgconfig then
            file:print("pkgconfig='%s'", pkgconfig)
        end
        file:print("")

        -- built-in options
        file:print("[built-in options]")
        local cflags   = table.join(table.wrap(package:build_getenv("cxflags")), package:build_getenv("cflags"))
        local cxxflags = table.join(table.wrap(package:build_getenv("cxflags")), package:build_getenv("cxxflags"))
        local asflags  = table.wrap(package:build_getenv("asflags"))
        local arflags  = table.wrap(package:build_getenv("arflags"))
        local ldflags  = table.wrap(package:build_getenv("ldflags"))
        local shflags  = table.wrap(package:build_getenv("shflags"))
        table.join2(cflags,   opt.cflags)
        table.join2(cflags,   opt.cxflags)
        table.join2(cxxflags, opt.cxxflags)
        table.join2(cxxflags, opt.cxflags)
        table.join2(asflags,  opt.asflags)
        table.join2(ldflags,  opt.ldflags)
        table.join2(shflags,  opt.shflags)
        table.join2(cflags,   _get_cflags_from_packagedeps(package, opt))
        table.join2(cxxflags, _get_cflags_from_packagedeps(package, opt))
        table.join2(ldflags,  _get_ldflags_from_packagedeps(package, opt))
        table.join2(shflags,  _get_ldflags_from_packagedeps(package, opt))
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
        if opt.host_machine then
            file:print("%s", opt.host_machine)
        elseif package:is_plat("iphoneos", "macosx") then
            local cpu
            local cpu_family
            if package:is_arch("arm64") then
                cpu = "aarch64"
                cpu_family = "aarch64"
            elseif package:is_arch("armv7") then
                cpu = "arm"
                cpu_family = "arm"
            elseif package:is_arch("x64", "x86_64") then
                cpu = "x86_64"
                cpu_family = "x86_64"
            elseif package:is_arch("x86", "i386") then
                cpu = "i686"
                cpu_family = "x86"
            else
                raise("unsupported arch(%s)", package:arch())
            end
            file:print("system = 'darwin'")
            file:print("cpu_family = '%s'", cpu_family)
            file:print("cpu = '%s'", cpu)
            file:print("endian = 'little'")
        elseif package:is_plat("android") then
            -- TODO
            raise("android has been not supported now!")
        elseif package:is_plat("mingw") then
            local cpu
            local cpu_family
            if package:is_arch("x64", "x86_64") then
                cpu = "x86_64"
                cpu_family = "x86_64"
            elseif package:is_arch("x86", "i386") then
                cpu = "i686"
                cpu_family = "x86"
            else
                raise("unsupported arch(%s)", package:arch())
            end
            file:print("system = 'windows'")
            file:print("cpu_family = '%s'", cpu_family)
            file:print("cpu = '%s'", cpu)
            file:print("endian = 'little'")
        elseif package:is_plat("wasm") then
            file:print("system = 'emscripten'")
            file:print("cpu_family = 'wasm32'")
            file:print("cpu = 'wasm32'")
            file:print("endian = 'little'")
        elseif package:is_plat("cross") and package:targetos() then
            local cpu = package:arch()
            if package:is_arch("arm64") then
                cpu = "aarch64"
            elseif package:is_arch("arm.*") then
                cpu = "arm"
            end
            local cpu_family = cpu
            file:print("system = '%s'", package:targetos() or "linux")
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
function _get_configs(package, configs, opt)

    -- add prefix
    configs = configs or {}
    table.insert(configs, "--prefix=" .. package:installdir())
    table.insert(configs, "--libdir=lib")

    -- set build type
    table.insert(configs, "-Dbuildtype=" .. (package:debug() and "debug" or "release"))

    -- add -fpic
    if package:is_plat("linux") and package:config("pic") ~= false then
        table.insert(configs, "-Db_staticpic=true")
    end

    -- add lto
    if package:config("lto") then
        table.insert(configs, "-Db_lto=true")
    end

    -- add vs_runtime flags
    local vs_runtime = package:config("vs_runtime")
    if package:is_plat("windows") and vs_runtime then
        table.insert(configs, "-Db_vscrt=" .. vs_runtime:lower())
    end

    -- add cross file
    if _is_cross_compilation(package) then
        table.insert(configs, "--cross-file=" .. _get_cross_file(package, opt))
    end

    -- add build directory
    table.insert(configs, _get_buildir(package, opt))
    return configs
end

-- get msvc
function _get_msvc(package)
    local msvc = toolchain.load("msvc", {plat = package:plat(), arch = package:arch()})
    assert(msvc:check(), "vs not found!") -- we need check vs envs if it has been not checked yet
    return msvc
end

-- get msvc run environments
function _get_msvc_runenvs(package)
    return os.joinenvs(_get_msvc(package):runenvs())
end

-- fix libname on windows
function _fix_libname_on_windows(package)
    for _, lib in ipairs(os.files(path.join(package:installdir("lib"), "lib*.a"))) do
        os.mv(lib, lib:gsub("(.+)lib(.-)%.a", "%1%2.lib"))
    end
end

-- get cflags from package deps
function _get_cflags_from_packagedeps(package, opt)
    local result = {}
    for _, depname in ipairs(opt.packagedeps) do
        local dep = package:dep(depname)
        if dep then
            local fetchinfo = dep:fetch({external = false})
            if fetchinfo then
                table.join2(result, _map_compflags(package, "cxx", "define", fetchinfo.defines))
                table.join2(result, _map_compflags(package, "cxx", "includedir", fetchinfo.includedirs))
                table.join2(result, _map_compflags(package, "cxx", "sysincludedir", fetchinfo.sysincludedirs))
            end
        end
    end
    return result
end

-- get ldflags from package deps
function _get_ldflags_from_packagedeps(package, opt)
    local result = {}
    for _, depname in ipairs(opt.packagedeps) do
        local dep = package:dep(depname)
        if dep then
            local fetchinfo = dep:fetch({external = false})
            if fetchinfo then
                table.join2(result, _map_linkflags(package, "binary", {"cxx"}, "linkdir", fetchinfo.linkdirs))
                table.join2(result, _map_linkflags(package, "binary", {"cxx"}, "link", fetchinfo.links))
                table.join2(result, _map_linkflags(package, "binary", {"cxx"}, "syslink", fetchinfo.syslinks))
            end
        end
    end
    return result
end

-- get the build environments
function buildenvs(package, opt)
    local envs = {}
    opt = opt or {}
    if package:is_plat(os.host()) then
        local cflags   = table.join(table.wrap(package:config("cxflags")), package:config("cflags"))
        local cxxflags = table.join(table.wrap(package:config("cxflags")), package:config("cxxflags"))
        local asflags  = table.wrap(package:config("asflags"))
        local ldflags  = table.wrap(package:config("ldflags"))
        local shflags  = table.wrap(package:config("shflags"))
        table.join2(cflags,   opt.cflags)
        table.join2(cflags,   opt.cxflags)
        table.join2(cxxflags, opt.cxxflags)
        table.join2(cxxflags, opt.cxflags)
        table.join2(asflags,  opt.asflags)
        table.join2(ldflags,  opt.ldflags)
        table.join2(shflags,  opt.shflags)
        table.join2(cflags,   _get_cflags_from_packagedeps(package, opt))
        table.join2(cxxflags, _get_cflags_from_packagedeps(package, opt))
        table.join2(ldflags,  _get_ldflags_from_packagedeps(package, opt))
        table.join2(shflags,  _get_ldflags_from_packagedeps(package, opt))
        envs.CFLAGS    = table.concat(cflags, ' ')
        envs.CXXFLAGS  = table.concat(cxxflags, ' ')
        envs.ASFLAGS   = table.concat(asflags, ' ')
        envs.LDFLAGS   = table.concat(ldflags, ' ')
        envs.SHFLAGS   = table.concat(shflags, ' ')
        if package:is_plat("windows") then
            envs = os.joinenvs(envs, _get_msvc_runenvs(package))
            local pkgconf = find_tool("pkgconf")
            if pkgconf then
                envs.PKG_CONFIG = pkgconf.program
            end
        end
    end
    local ACLOCAL_PATH = {}
    local PKG_CONFIG_PATH = {}
    for _, dep in ipairs(package:librarydeps()) do
        local pkgconfig = path.join(dep:installdir(), "lib", "pkgconfig")
        if os.isdir(pkgconfig) then
            table.insert(PKG_CONFIG_PATH, pkgconfig)
        end
        pkgconfig = path.join(dep:installdir(), "share", "pkgconfig")
        if os.isdir(pkgconfig) then
            table.insert(PKG_CONFIG_PATH, pkgconfig)
        end
        local aclocal = path.join(dep:installdir(), "share", "aclocal")
        if os.isdir(aclocal) then
            table.insert(ACLOCAL_PATH, aclocal)
        end
    end
    envs.ACLOCAL_PATH    = path.joinenv(ACLOCAL_PATH)
    envs.PKG_CONFIG_PATH = path.joinenv(PKG_CONFIG_PATH)
    return envs
end

-- generate build files for ninja
function generate(package, configs, opt)

    -- init options
    opt = opt or {}

    -- pass configurations
    local argv = {}
    for name, value in pairs(_get_configs(package, configs, opt)) do
        value = tostring(value):trim()
        if value ~= "" then
            if type(name) == "number" then
                table.insert(argv, value)
            else
                table.insert(argv, "--" .. name .. "=" .. value)
            end
        end
    end

    -- do configure
    os.vrunv("meson", argv, {envs = opt.envs or buildenvs(package, opt)})
end

-- build package
function build(package, configs, opt)

    -- generate build files
    opt = opt or {}
    generate(package, configs, opt)

    -- do build
    local buildir = _get_buildir(package, opt)
    ninja.build(package, {}, {buildir = buildir, envs = opt.envs or buildenvs(package, opt)})
end

-- install package
function install(package, configs, opt)

    -- generate build files
    opt = opt or {}
    generate(package, configs, opt)

    -- do build and install
    local buildir = _get_buildir(package, opt)
    ninja.install(package, {}, {buildir = buildir, envs = opt.envs or buildenvs(package, opt)})

    -- fix static libname on windows
    if package:is_plat("windows") and not package:config("shared") then
        _fix_libname_on_windows(package)
    end
end
