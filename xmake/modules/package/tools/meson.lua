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

-- get configs
function _get_configs(package, configs, opt)

    -- add prefix
    configs = configs or {}
    table.insert(configs, "--prefix=" .. package:installdir())
    table.insert(configs, "--libdir=lib")

    -- set build type
    table.insert(configs, "-Dbuildtype=" .. (package:debug() and "debug" or "release"))

    -- add -fpic
    if package:is_plat("linux") and package:config("pic") then
        table.insert(configs, "-Db_staticpic=true")
    end

    -- add vs_runtime flags
    if package:is_plat("windows") then
        table.insert(configs, "-Db_vscrt=" .. package:config("vs_runtime"):lower())
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
    else
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
        envs.CC        = package:build_getenv("cc")
        envs.AS        = package:build_getenv("as")
        envs.AR        = package:build_getenv("ar")
        envs.LD        = package:build_getenv("ld")
        envs.LDSHARED  = package:build_getenv("sh")
        envs.CPP       = package:build_getenv("cpp")
        envs.RANLIB    = package:build_getenv("ranlib")
        envs.CFLAGS    = table.concat(cflags, ' ')
        envs.CXXFLAGS  = table.concat(cxxflags, ' ')
        envs.ASFLAGS   = table.concat(asflags, ' ')
        envs.ARFLAGS   = table.concat(arflags, ' ')
        envs.LDFLAGS   = table.concat(ldflags, ' ')
        envs.SHFLAGS   = table.concat(shflags, ' ')
    end
    local ACLOCAL_PATH = {}
    local PKG_CONFIG_PATH = {}
    for _, dep in ipairs(package:orderdeps()) do
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
