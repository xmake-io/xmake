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
-- @file        package.lua
--

-- define module
local package = {}

-- load modules
local io         = require("base/io")
local os         = require("base/os")
local path       = require("base/path")
local table      = require("base/table")
local utils      = require("base/utils")
local config     = require("project/config")
local semver     = require("base/semver")
local sandbox    = require("sandbox/sandbox")
local localcache = require("cache/localcache")

-- get cache
function package._cache()
    return localcache.cache("package")
end

-- save the requires info to the cache
function package:save()
    package._cache():set(self:name(), self._INFO)
    package._cache():save()
end

-- clear the package
function package:clear()
    local info = self._INFO
    if info then
        for k, v in pairs(info) do
            if not k:startswith("__") then
                info[k] = nil
            end
        end
    end
end

-- dump this package
function package:dump()
    utils.dump(self._INFO)
end

-- get the require info
function package:get(infoname)
    return self._INFO[infoname]
end

-- get the require name
function package:name()
    return self._NAME
end

-- get the package version
function package:version()

    -- get it from cache first
    if self._VERSION ~= nil then
        return self._VERSION
    end

    -- get version
    local version = nil
    local verstr = self:get("version")
    if verstr then
        version = semver.new(verstr)
    end
    self._VERSION = version or false
    return version
end

-- get the package license
function package:license()
    return self:get("license")
end

-- has static libraries?
function package:has_static()
    return self:get("static")
end

-- has shared libraries?
function package:has_shared()
    return self:get("shared")
end

-- get the require string
function package:requirestr()
    return self:get("__requirestr")
end

-- get the install directory
function package:installdir()
    return self:get("__installdir")
end

-- get the extra info from the given name
function package:extra(name)
    local extrainfo = self:extrainfo()
    if extrainfo then
        return extrainfo[name]
    end
end

-- get the extra info
function package:extrainfo()
    return self:get("__extrainfo")
end

-- set the value to the requires info
function package:set(name_or_info, ...)
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
function package:add(name_or_info, ...)
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
function package:enabled()
    return self:get("__enabled")
end

-- enable or disable this require info
--
-- @param enabled   enable it?
--
function package:enable(enabled)
    self:set("__enabled", enabled)
end

-- load the requires info from the cache
function package.load(name)

    -- check
    assert(name)

    -- get info
    local info = package._cache():get(name)
    if info == nil then
        return
    end

    -- init package instance
    local instance = table.inherit(package)
    instance._INFO = info
    instance._NAME = name
    return instance
end

-- return module
return package
