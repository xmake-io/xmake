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

-- register api
function deprecated_project.api_register(interp)

    -- register api: add_headers() to target
    deprecated_project._api_target_add_headers(interp)

    -- register api: set_config_header() to option/target
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
