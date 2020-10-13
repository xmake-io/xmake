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
-- @file        meson.lua
--

-- imports
import("core.base.option")
import("core.project.config")

-- get build directory
function _get_buildir()
    _g.buildir = _g.buildir or ("build_" .. hash.uuid4():split('%-')[1])
    return _g.buildir
end

-- get configs
function _get_configs(package, configs)

    -- add prefix
    local configs = configs or {}
    table.insert(configs, "--prefix=" .. package:installdir())

    -- add build directory
    table.insert(configs, _get_buildir())
    return configs
end

-- get the build environments
function buildenvs(package)
    local envs = {}
    if package:is_plat(os.host()) then
        local cflags   = table.join(table.wrap(package:config("cxflags")), package:config("cflags"))
        local cxxflags = table.join(table.wrap(package:config("cxflags")), package:config("cxxflags"))
        envs.CFLAGS    = table.concat(cflags, ' ')
        envs.CXXFLAGS  = table.concat(cxxflags, ' ')
        envs.ASFLAGS   = table.concat(table.wrap(package:config("asflags")), ' ')
    else
        local cflags   = table.join(table.wrap(package:build_getenv("cxflags")), package:build_getenv("cflags"))
        local cxxflags = table.join(table.wrap(package:build_getenv("cxflags")), package:build_getenv("cxxflags"))
        envs.CC        = package:build_getenv("cc")
        envs.AS        = package:build_getenv("as")
        envs.AR        = package:build_getenv("ar")
        envs.LD        = package:build_getenv("ld")
        envs.LDSHARED  = package:build_getenv("sh")
        envs.CPP       = package:build_getenv("cpp")
        envs.RANLIB    = package:build_getenv("ranlib")
        envs.CFLAGS    = table.concat(cflags, ' ')
        envs.CXXFLAGS  = table.concat(cxxflags, ' ')
        envs.ASFLAGS   = table.concat(table.wrap(package:build_getenv("asflags")), ' ')
        envs.ARFLAGS   = table.concat(table.wrap(package:build_getenv("arflags")), ' ')
        envs.LDFLAGS   = table.concat(table.wrap(package:build_getenv("ldflags")), ' ')
        envs.SHFLAGS   = table.concat(table.wrap(package:build_getenv("shflags")), ' ')
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
    for name, value in pairs(_get_configs(package, configs)) do
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
    os.vrunv("meson", argv, {envs = opt.envs or buildenvs(package)})
end

-- install package
function install(package, configs, opt)

    -- generate build files
    generate(package, configs, opt)

    -- do build and install
    local buildir = _get_buildir()
    if option.get("verbose") or option.get("diagnosis") then
        os.vrunv("ninja", {"-v", "-C", buildir})
        os.vrunv("ninja", {"install", "-v", "-C", buildir})
    else
        os.vrunv("ninja", {"-C", buildir})
        os.vrunv("ninja", {"install", "-C", buildir})
    end
end
