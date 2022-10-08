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
local _instance = _instance or {}

-- load modules
local io         = require("base/io")
local os         = require("base/os")
local path       = require("base/path")
local table      = require("base/table")
local utils      = require("base/utils")
local semver     = require("base/semver")
local rule       = require("project/rule")
local config     = require("project/config")
local sandbox    = require("sandbox/sandbox")
local localcache = require("cache/localcache")

-- save the requires info to the cache
function _instance:save()
    package._cache():set(self:name(), self._INFO)
    package._cache():save()
end

-- clear the package
function _instance:clear()
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
function _instance:dump()
    utils.dump(self._INFO)
end

-- get the require info
function _instance:get(infoname)
    return self._INFO[infoname]
end

-- get the package name (with alias name)
function _instance:name()
    return self._NAME
end

-- get the package version
function _instance:version()

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
function _instance:license()
    return self:get("license")
end

-- has static libraries?
function _instance:has_static()
    return self:get("static")
end

-- has shared libraries?
function _instance:has_shared()
    return self:get("shared")
end

-- get the require string
function _instance:requirestr()
    return self:get("__requirestr")
end

-- get the install directory
function _instance:installdir()
    return self:get("__installdir")
end

-- get library files
function _instance:libraryfiles()
    return self:get("libfiles")
end

-- get the extra info from the given name
function _instance:extra(name)
    local extrainfo = self:extrainfo()
    if extrainfo then
        return extrainfo[name]
    end
end

-- get the extra info
function _instance:extrainfo()
    return self:get("__extrainfo")
end

-- set the value to the requires info
function _instance:set(name_or_info, ...)
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
function _instance:add(name_or_info, ...)
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
function _instance:enabled()
    return self:get("__enabled")
end

-- enable or disable this require info
function _instance:enable(enabled)
    self:set("__enabled", enabled)
end

-- get the given rule
function _instance:rule(name)
    return self:rules()[name]
end

-- get package rules
function _instance:rules()
    local rules = self._RULES
    if rules == nil then
        local ruleinfos = {}
        local installdir = self:installdir()
        local rulesdir = path.join(installdir, "rules")
        if os.isdir(rulesdir) then
            local files = os.match(path.join(rulesdir, "**.lua"))
            if files then
                for _, filepath in ipairs(files) do
                    local results, errors = rule._load(filepath)
                    if results then
                        table.join2(ruleinfos, results)
                    else
                        os.raise(errors)
                    end
                end
            end
        end

        -- make rule instances
        rules = {}
        for rulename, ruleinfo in pairs(ruleinfos) do
            rulename = "@" .. self:name() .. "/" .. rulename
            local instance = rule.new(rulename, ruleinfo, {package = self})
            rules[rulename] = instance
        end
        self._RULES = rules
    end
    return rules
end

-- get cache
function package._cache()
    return localcache.cache("package")
end

-- load the package from the cache
function package.load(name)
    local info = package._cache():get(name)
    if info == nil then
        return
    end
    return package.load_withinfo(name, info)
end

-- load package from the give package info
function package.load_withinfo(name, info)
    local instance = table.inherit(_instance)
    instance._INFO = info
    instance._NAME = name
    return instance
end

-- return module
return package
