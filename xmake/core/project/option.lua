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
-- @file        option.lua
--

-- define module
local option = option or {}

-- load modules
local io       = require("base/io")
local os       = require("base/os")
local path     = require("base/path")
local table    = require("base/table")
local utils    = require("base/utils")
local option_  = require("base/option")
local config   = require("project/config")
local cache    = require("project/cache")
local linker   = require("tool/linker")
local compiler = require("tool/compiler")
local sandbox  = require("sandbox/sandbox")
local language = require("language/language")
local import   = require("sandbox/modules/import")

-- get cache
function option._cache()

    -- get it from cache first if exists
    if option._CACHE then
        return option._CACHE
    end

    -- init cache
    option._CACHE = cache("local.option")

    -- ok
    return option._CACHE
end

-- check option for c/c++
function option:_check_cx(kind)

    -- get snippets
    local snippets = self:get(kind .. "snippet") 

    -- get types
    local types = self:get(kind .. "types")

    -- get funcs
    local funcs = self:get(kind .. "funcs")

    -- get links
    local links = self:get(kind .. "links")

    -- get includes
    local includes = self:get(kind .. "includes")

    -- need not check it
    if not snippets and not types and not funcs and not links and not includes then
        return true
    end

    -- init source kind
    local sourcekind = kind
    if kind == "c" then
        sourcekind = "cc"
    end

    -- import has_cxsnippets()
    self._has_cxsnippets = self._has_cxsnippets or import("lib.detect.has_cxsnippets")

    -- get the tool name from the program
    local ok, results_or_errors = sandbox.load(self._has_cxsnippets, snippets, {target = self, sourcekind = sourcekind, types = types, funcs = funcs, includes = includes})
    if not ok then
        return false, results_or_errors
    end

    -- ok?
    return results_or_errors
end

-- check option 
function option:_check()

    -- check it
    local ok = self:_check_cx("c") and self:_check_cx("cxx")

    -- get name
    local name = self:name()
    if name:startswith("__") then
        name = name:sub(3)
    end

    -- trace
    utils.cprint("checking for the %s ... %s", name, utils.ifelse(ok, "${green}ok", "${red}no"))

    -- ok?
    return ok
end

-- attempt to check option 
function option:check(force)

    -- have been checked?
    if self._CHECKED and not force then
        return 
    end

    -- the option name
    local name = self:name()

    -- get default value, TODO: enable will be deprecated
    local default = self:get("default")
    if default == nil then
        default = self:get("enable")
    end

    -- need check? (only force to check the automatical option without the default value)
    if config.get(name) == nil or (default == nil and force) then

        -- use it directly if the default value exists
        if default ~= nil then

            -- save the default value
            config.set(name, default)

            -- save this option to configure 
            self:save()

        -- check option as boolean switch automatically if the default value not exists
        elseif default == nil and self:_check() then

            -- enable this option
            config.set(name, true)

            -- save this option to configure 
            self:save()
        else

            -- disable this option
            config.set(name, false)

            -- clear this option to configure 
            self:clear()
        end

    -- no check
    elseif config.get(name) then

        -- save this option to configure directly
        self:save()
    end    

    -- checked
    self._CHECKED = true
end

-- get the option info
function option:get(infoname)
    return self._INFO[infoname]
end

-- add the value to the option info
function option:add(name_or_info, ...)
    if type(name_or_info) == "string" then
        self._INFO[name_or_info] = table.unique(table.join2(table.wrap(self._INFO[name_or_info]), ...))
    elseif type(name_or_info) == "table" and #name_or_info == 0 then
        for name, info in pairs(name_or_info) do
            self:add(name, info)
        end
    end
end

-- get option deps
function option:deps()
    -- TODO in the future
    return {}
end

-- save the option info to the cache
function option:save()
    option._cache():set(self:name(), self._INFO)
    option._cache():flush()
end

-- clear the option info for cache
function option:clear()
    option._cache():set(self:name(), nil)
end

-- get the option name
function option:name()
    return self._NAME
end

-- load the option info from the cache
function option.load(name)

    -- check
    assert(name)

    -- get info
    local info = option._cache():get(name)
    if info == nil then
        return 
    end

    -- init option instance
    local instance = table.inherit(option)
    instance._INFO = info
    instance._NAME = name

    -- ok
    return instance
end

-- return module
return option
