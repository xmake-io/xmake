--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
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

-- add_csnippet for option
function deprecated_project._api_option_add_csnippet(interp, ...)

    -- get api name
    local apiname = "add_csnippet"

    -- get api function
    local apifunc = interp:_api_within_scope("option", apiname .. 's')
    assert(apifunc)

    -- register api
    interp:api_register_builtin(apiname, function (...) 

                                            -- deprecated
                                            deprecated.add(apiname .. "s(...)", apiname .. "(...)")
                                          
                                            -- dispatch it
                                            apifunc(...)
                                        end)
end

-- add_cxxsnippet for option
function deprecated_project._api_option_add_cxxsnippet(interp, ...)

    -- get api name
    local apiname = "add_cxxsnippet"

    -- get api function
    local apifunc = interp:_api_within_scope("option", apiname .. 's')
    assert(apifunc)

    -- register api
    interp:api_register_builtin(apiname, function (...) 

                                            -- deprecated
                                            deprecated.add(apiname .. "s(...)", apiname .. "(...)")
                                          
                                            -- dispatch it
                                            apifunc(...)
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

    -- register api: set_enable() to option
    interp:api_register("option", "set_enable", deprecated_project._api_option_set_enable)

    -- register api: add_csnippet() to option
    interp:api_register("option", "add_csnippet", deprecated_project._api_option_add_csnippet)

    -- register api: add_cxxsnippet() to option
    interp:api_register("option", "add_cxxsnippet", deprecated_project._api_option_add_cxxsnippet)
end

-- return module: deprecated_project
return deprecated_project
