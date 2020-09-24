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
local rule                      = require("project/rule")
local config                    = require("project/config")
local platform                  = require("platform/platform")
local deprecated                = require("base/deprecated")
local deprecated_interpreter    = require("base/deprecated/interpreter")

-- load all packages from the given directories
function deprecated_project._api_add_pkgdirs(interp, ...)

    -- get all directories
    local pkgdirs = {}
    local dirs = table.join(...)
    for _, dir in ipairs(dirs) do
        table.insert(pkgdirs, dir .. "/*.pkg")
    end

    -- add all packages
    interp:api_builtin_includes(pkgdirs)
end

-- load the given packages
function deprecated_project._api_add_pkgs(interp, ...)

    -- add all packages
    interp:api_builtin_includes(...)
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

-- set modes
function deprecated_project._api_set_modes(interp, ...)

    -- get api function
    local apifunc = interp:api_func("set_modes")
    assert(apifunc)

    -- register api
    interp:api_register_builtin("set_modes", function (...)

                                            -- deprecated
                                            deprecated.add("add_rules(\"mode.debug\", \"mode.release\")", "set_modes(\"debug\", \"release\")")

                                            -- dispatch it
                                            apifunc(...)
                                        end)
end

-- add_csnippet/add_cxxsnippet for option
function deprecated_project._api_option_add_cxsnippet(interp, apiname)

    -- get api function
    local apifunc = interp:_api_within_scope("option", apiname)
    assert(apifunc)

    -- register api
    interp:_api_within_scope_set("option", apiname, function (...)

                                            -- deprecated
                                            deprecated.add(apiname .. "s(...)", apiname .. "(...)")

                                            -- dispatch it
                                            apifunc(...)
                                        end)
end

-- add_headers for target
function deprecated_project._api_target_add_headers(interp)

    -- get api function
    local apifunc = interp:_api_within_scope("target", "add_headers")
    assert(apifunc)

    -- register api
    interp:_api_within_scope_set("target", "add_headers", function (value, ...)

                                            -- deprecated
                                            deprecated.add("add_headerfiles(%s)", "add_headers(%s)", tostring(value))

                                            -- dispatch it
                                            apifunc(value, ...)
                                        end)
end

-- add_headerdirs for target
function deprecated_project._api_target_add_headerdirs(interp)

    -- get api function
    local apifunc = interp:_api_within_scope("target", "add_headerdirs")
    assert(apifunc)

    -- register api
    interp:_api_within_scope_set("target", "add_headerdirs", function (value, ...)

                                            -- deprecated
                                            deprecated.add("add_includedirs(%s, {public|interface = true})", "add_headerdirs(%s)", tostring(value))

                                            -- dispatch it
                                            apifunc(value, ...)
                                        end)
end

-- add_defines_h for target
function deprecated_project._api_target_add_defines_h(interp)

    -- get api function
    local apifunc = interp:_api_within_scope("target", "add_defines_h")
    assert(apifunc)

    -- register api
    interp:_api_within_scope_set("target", "add_defines_h", function (value, ...)

                                            -- deprecated
                                            deprecated.add("add_configfiles() and set_configvar(%s)", "add_defines_h(%s)", tostring(value))

                                            -- dispatch it
                                            apifunc(value, ...)
                                        end)
end

-- add_defines_h for option
function deprecated_project._api_option_add_defines_h(interp)

    -- get api function
    local apifunc = interp:_api_within_scope("option", "add_defines_h")
    assert(apifunc)

    -- register api
    interp:_api_within_scope_set("option", "add_defines_h", function (value, ...)

                                            -- deprecated
                                            deprecated.add("add_configfiles() and set_configvar(%s)", "add_defines_h(%s)", tostring(value))

                                            -- dispatch it
                                            apifunc(value, ...)
                                        end)
end

-- set_config_header for target
function deprecated_project._api_target_set_config_header(interp)

    -- get api function
    local apifunc = interp:_api_within_scope("target", "set_config_header")
    assert(apifunc)

    -- register api
    interp:_api_within_scope_set("target", "set_config_header", function (value, ...)

                                            -- deprecated
                                            deprecated.add("add_configfiles(%s.in)", "set_config_header(%s)", tostring(value))

                                            -- dispatch it
                                            apifunc(value, ...)
                                        end)
end

-- set_headerdir for target
function deprecated_project._api_target_set_headerdir(interp)

    -- get api function
    local apifunc = interp:_api_within_scope("target", "set_headerdir")
    assert(apifunc)

    -- register api
    interp:_api_within_scope_set("target", "set_headerdir", function (value, ...)

                                            -- deprecated
                                            deprecated.add(false, "set_headerdir(%s)", tostring(value))

                                            -- dispatch it
                                            apifunc(value, ...)
                                        end)
end

-- set_tools for target
function deprecated_project._api_target_set_tools(interp)

    -- get api function
    local apifunc = interp:_api_within_scope("target", "set_tools")
    assert(apifunc)

    -- register api
    interp:_api_within_scope_set("target", "set_tools", function (key, value, ...)

                                            -- deprecated
                                            deprecated.add("set_toolset(%s, %s)", "set_tools(%s, %s)", tostring(key), tostring(value))

                                            -- dispatch it
                                            apifunc(key, value, ...)
                                        end)
end

-- set_toolchain for target
function deprecated_project._api_target_set_toolchain(interp)

    -- get api function
    local apifunc = interp:_api_within_scope("target", "set_toolchain")
    assert(apifunc)

    -- register api
    interp:_api_within_scope_set("target", "set_toolchain", function (key, value, ...)

                                            -- deprecated
                                            deprecated.add("set_toolset(%s, %s)", "set_toolchain(%s, %s)", tostring(key), tostring(value))

                                            -- dispatch it
                                            apifunc(key, value, ...)
                                        end)
end

-- add_tools for target
function deprecated_project._api_target_add_tools(interp)

    -- get api function
    local apifunc = interp:_api_within_scope("target", "add_tools")
    assert(apifunc)

    -- register api
    interp:_api_within_scope_set("target", "add_tools", function (key, value, ...)

                                            -- deprecated
                                            deprecated.add("add_tools(%s, %s)", "set_toolchain(%s, %s)", tostring(key), tostring(value))

                                            -- dispatch it
                                            apifunc(key, value, ...)
                                        end)
end

-- enable options?
function deprecated_project._api_is_option(interp, ...)

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
    deprecated.add("has_config(\"%s\")", "is_option(\"%s\")", values)

    -- done
    return config.has(...)
end

-- register api
function deprecated_project.api_register(interp)

    -- register api: add_pkgdirs() to root
    interp:api_register(nil, "add_pkgdirs", deprecated_project._api_add_packagedirs)

    -- register api: add_pkgs() to root
    interp:api_register(nil, "add_pkgs",    deprecated_project._api_add_packages)

    -- register api: is_option() to root
    interp:api_register(nil, "is_option",   deprecated_project._api_is_option)

    -- register api: set_modes() to root
    deprecated_project._api_set_modes(interp)

    -- register api: add_csnippet/add_cxxsnippet() to option
    deprecated_project._api_option_add_cxsnippet(interp, "add_csnippet")
    deprecated_project._api_option_add_cxsnippet(interp, "add_cxxsnippet")

    -- register api: add_headers() to target
    deprecated_project._api_target_add_headers(interp)
    deprecated_project._api_target_add_headerdirs(interp)

    -- register api: add_defines_h()/set_config_header() to option/target
    deprecated_project._api_option_add_defines_h(interp)
    deprecated_project._api_target_add_defines_h(interp)
    deprecated_project._api_target_set_config_header(interp)

    -- register api: set_headerdir() to target
    deprecated_project._api_target_set_headerdir(interp)

    -- register api: set_toolchain/set_tools/add_tools() to target
    deprecated_project._api_target_set_tools(interp)
    deprecated_project._api_target_add_tools(interp)
    deprecated_project._api_target_set_toolchain(interp)
end

-- return module: deprecated_project
return deprecated_project
