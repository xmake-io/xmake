--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        deprecated_project.lua
--

-- define module: deprecated_project
local deprecated_project = deprecated_project or {}

-- load modules
local os                        = require("base/os")
local path                      = require("base/path")
local utils                     = require("base/utils")
local table                     = require("base/table")
local string                    = require("base/string")
local config                    = require("project/config")
local platform                  = require("platform/platform")
local deprecated                = require("base/deprecated")
local deprecated_interpreter    = require("base/deprecated/interpreter")

-- the current mode is belong to the given modes?
function deprecated_project._api_is_mode(interp, ...)

    -- get the current mode
    local mode = config.get("mode")
    if not mode then return false end

    -- exists this mode?
    for _, m in ipairs(table.join(...)) do
        if m and type(m) == "string" and m == mode then
            return true
        end
    end
end

-- the current platform is belong to the given platforms?
function deprecated_project._api_is_plat(interp, ...)

    -- get the current platform
    local plat = config.get("plat")
    if not plat then return false end

    -- exists this platform? and escape '-'
    for _, p in ipairs(table.join(...)) do
        if p and type(p) == "string" and plat:find(p:gsub("%-", "%%-")) then
            return true
        end
    end
end

-- the current platform is belong to the given architectures?
function deprecated_project._api_is_arch(interp, ...)

    -- get the current architecture
    local arch = config.get("arch")
    if not arch then return false end

    -- exists this architecture? and escape '-'
    for _, a in ipairs(table.join(...)) do
        if a and type(a) == "string" and arch:find(a:gsub("%-", "%%-")) then
            return true
        end
    end
end

-- the current kind is belong to the given kinds?
function deprecated_project._api_is_kind(interp, ...)

    -- get the current kind
    local kind = config.get("kind")
    if not kind then return false end

    -- exists this kind?
    for _, k in ipairs(table.join(...)) do
        if k and type(k) == "string" and k == kind then
            return true
        end
    end
end

-- enable options?
function deprecated_project._api_is_option(interp, ...)

    -- some options are enabled?
    for _, o in ipairs(table.join(...)) do
        if o and type(o) == "string" and config.get(o) then
            return true
        end
    end
end

-- load all packages from the given directories
function deprecated_project._api_add_pkgdirs(interp, ...)

    -- get all directories
    local pkgdirs = {}
    local dirs = table.join(...)
    for _, dir in ipairs(dirs) do
        table.insert(pkgdirs, dir .. "/*.pkg")
    end

    -- add all packages
    interp:api_builtin_add_subdirs(pkgdirs)
end

-- load the given packages
function deprecated_project._api_add_pkgs(interp, ...)

    -- add all packages
    interp:api_builtin_add_subdirs(...)
end

-- the current os is belong to the given os?
function deprecated_project._api_os(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- deprecated
    deprecated.add("is_os(\"%s\")", "os(\"%s\")", values)

    -- done
    return deprecated_project._api_is_os(interp, ...)
end

-- the current mode is belong to the given modes?
function deprecated_project._api_modes(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- deprecated
    deprecated.add("is_mode(\"%s\")", "modes(\"%s\")", values)

    -- done
    return deprecated_project._api_is_mode(interp, ...)
end

-- the current platform is belong to the given platforms?
function deprecated_project._api_plats(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- deprecated
    deprecated.add("is_plat(\"%s\")", "plats(\"%s\")", values)

    -- done
    return deprecated_project._api_is_plat(interp, ...)
end

-- the current platform is belong to the given architectures?
function deprecated_project._api_archs(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- deprecated
    deprecated.add("is_arch(\"%s\")", "archs(\"%s\")", values)

    -- done
    return deprecated_project._api_is_arch(interp, ...)
end

-- the current kind is belong to the given kinds?
function deprecated_project._api_kinds(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- deprecated
    deprecated.add("is_kind(\"%s\")", "kinds(\"%s\")", values)

    -- done
    return deprecated_project._api_is_kind(interp, ...)
end

-- enable options?
function deprecated_project._api_options(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- deprecated
    deprecated.add("is_option(\"%s\")", "options(\"%s\")", values)

    -- done
    return deprecated_project._api_is_option(interp, ...)
end

-- load all packages from the given directories
function deprecated_project._api_add_packagedirs(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- deprecated
    deprecated.add("add_packagedirs(\"%s\")", "add_pkgdirs(\"%s\")", values)

    -- done
    return deprecated_project._api_add_pkgdirs(interp, ...)
end

-- load the given packages
function deprecated_project._api_add_packages(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- deprecated
    deprecated.add("add_packages(\"%s\")", "add_pkgs(\"%s\")", values)

    -- done
    return deprecated_project._api_add_pkgs(interp, ...)
end

-- set_enable for option
function deprecated_project._api_option_set_enable(interp, ...)

    -- get api function
    local apifunc = interp:_api_within_scope("option", "set_default")
    assert(apifunc)

    -- register api
    interp:api_register_builtin("set_enable", function (value) 

                                            -- deprecated
                                            deprecated.add("set_default(%s)", "set_enable(%s)", tostring(value))
                                          
                                            -- dispatch it
                                            apifunc(value)
                                        end)
end

-- register api
function deprecated_project.api_register(interp)

    -- register api: set_target() and set_option()
    deprecated_interpreter.api_register_set_scope(interp, "target", "option")
    deprecated_interpreter.api_register_add_scope(interp, "target", "option")
   
    -- register api: set_runscript() and set_installscript() and set_packagescript()
    deprecated_interpreter.api_register_set_script(interp, "target", "runscript", "installscript", "packagescript")

    -- register api: kinds(), modes(), plats(), archs(), options()
    interp:api_register(nil, "kinds",   deprecated_project._api_kinds)
    interp:api_register(nil, "modes",   deprecated_project._api_modes)
    interp:api_register(nil, "plats",   deprecated_project._api_plats)
    interp:api_register(nil, "archs",   deprecated_project._api_archs)
    interp:api_register(nil, "options", deprecated_project._api_options)

    -- register api: add_pkgdirs() to root
    interp:api_register(nil, "add_pkgdirs", deprecated_project._api_add_packagedirs)

    -- register api: add_pkgs() to root
    interp:api_register(nil, "add_pkgs",    deprecated_project._api_add_packages)

    -- register api: set_enable() to option
    interp:api_register("option", "set_enable", deprecated_project._api_option_set_enable)

    -- register api: set_values() to option
    deprecated_interpreter._api_register_set_xxx_xxx(interp, "option", "enable")
    deprecated_interpreter._api_register_set_xxx_xxx(interp, "option", "showmenu")
    deprecated_interpreter._api_register_set_xxx_xxx(interp, "option", "category")
    deprecated_interpreter._api_register_set_xxx_xxx(interp, "option", "warnings")
    deprecated_interpreter._api_register_set_xxx_xxx(interp, "option", "optimize")
    deprecated_interpreter._api_register_set_xxx_xxx(interp, "option", "languages")
    deprecated_interpreter._api_register_set_xxx_xxx(interp, "option", "description")

    -- register api: add_values() to option
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "links")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "cincludes")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "cxxincludes")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "cfuncs")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "cxxfuncs")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "ctypes")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "cxxtypes")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "cflags")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "cxflags")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "cxxflags")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "mflags")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "mxflags")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "mxxflags")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "ldflags")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "vectorexts")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "defines")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "defines_if_ok")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "defines_h_if_ok")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "undefines")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "undefines_if_ok")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "undefines_h_if_ok")

    -- register api: add_pathes() to option
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "linkdirs")
    deprecated_interpreter._api_register_add_xxx_xxx(interp, "option", "includedirs")
end

-- return module: deprecated_project
return deprecated_project
