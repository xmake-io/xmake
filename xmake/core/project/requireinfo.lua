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
-- @file        requireinfo.lua
--

-- define module
local requireinfo = requireinfo or {}

-- load modules
local io      = require("base/io")
local os      = require("base/os")
local path    = require("base/path")
local table   = require("base/table")
local utils   = require("base/utils")
local cache   = require("project/cache")
local config  = require("project/config")
local semver  = require("base/semver")
local sandbox = require("sandbox/sandbox")

-- get cache
function requireinfo._cache()

    -- get it from cache first if exists
    if requireinfo._CACHE then
        return requireinfo._CACHE
    end

    -- init cache
    requireinfo._CACHE = cache("local.requires")

    -- ok
    return requireinfo._CACHE
end

-- save the requires info to the cache
function requireinfo:save()

    -- To ensure that the full information (version, ..) is obtained, delay loading it
    if not self._LOADED then
        local on_load = self:script("on_load")
        if on_load then
            local ok, errors = sandbox.load(on_load, self)
            if not ok then
                os.raise(errors)
            end
        end
        self._LOADED = true
    end

    -- save it
    requireinfo._cache():set(self:name(), self._INFO)
    requireinfo._cache():flush()
end

-- clear the requireinfo
function requireinfo:clear()
    local info = self._INFO
    if info then
        for k, v in pairs(info) do
            if not k:startswith("__") then
                info[k] = nil
            end
        end
    end
end

-- dump this requireinfo
function requireinfo:dump()
    utils.dump(self._INFO)
end

-- get the require info
function requireinfo:get(infoname)
    return self._INFO[infoname]
end

-- get the require name
function requireinfo:name()
    return self._NAME
end

-- get the given script
function requireinfo:script(name)
    return self._SCRIPTS and self._SCRIPTS[name] or nil
end

-- get the package version
function requireinfo:version()

    -- get it from cache first
    if self._VERSION ~= nil then
        return self._VERSION
    end

    -- get version
    local version = nil
    local verstr = self:get("__version")
    if verstr then
        version = semver.new(verstr)
    end

    -- save to cache
    self._VERSION = version or false

    -- done
    return version
end

-- set the package version
function requireinfo:version_set(version)
    self._VERSION = nil
    self:set("__version", version)
end

-- get the require string
function requireinfo:requirestr()
    return self:get("__requirestr")
end

-- get the extra info from the given name
function requireinfo:extra(name)
    local extrainfo = self:extrainfo()
    if extrainfo then
        return extrainfo[name]
    end
end

-- get the extra info
function requireinfo:extrainfo()
    return self:get("__extrainfo")
end

-- set the value to the requires info
function requireinfo:set(name_or_info, ...)
    if type(name_or_info) == "string" then
        local args = ...
        if args ~= nil then
            self._INFO[name_or_info] = table.unwrap(table.unique(table.join(...)))
        else
            self._INFO[name_or_info] = nil
        end
    elseif table.is_dictionary(name_or_info) then
        for name, info in pairs(table.join(name_or_info, ...)) do
            self:set(name, info)
        end
    end
end

-- add the value to the requires info
function requireinfo:add(name_or_info, ...)
    if type(name_or_info) == "string" then
        local info = table.wrap(self._INFO[name_or_info])
        self._INFO[name_or_info] = table.unwrap(table.unique(table.join(info, ...)))
    elseif table.is_dictionary(name_or_info) then
        for name, info in pairs(table.join(name_or_info, ...)) do
            self:add(name, info)
        end
    end
end

-- this require info is enabled?
function requireinfo:enabled()
    return self:get("__enabled")
end

-- enable or disable this require info
--
-- @param enabled   enable it?
--
function requireinfo:enable(enabled)
    self:set("__enabled", enabled)
end

-- load the requires info from the cache
function requireinfo.load(name)

    -- check
    assert(name)

    -- get info
    local info = requireinfo._cache():get(name)
    if info == nil then
        return
    end

    -- init requireinfo instance
    local instance = table.inherit(requireinfo)
    instance._INFO = info
    instance._NAME = name

    -- ok
    return instance
end

-- return module
return requireinfo
