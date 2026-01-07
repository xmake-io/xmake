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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        scheme.lua
--

-- @ref         https://github.com/xmake-io/xmake/issues/7184
-- @note        This module provides scheme management for packages,
--              allowing custom download schemes and configurations
--              to be defined and applied to package management.

-- define module
local scheme = scheme or {}
local _instance = _instance or {}

-- load modules
local os             = require("base/os")
local io             = require("base/io")
local path           = require("base/path")
local utils          = require("base/utils")
local table          = require("base/table")
local option         = require("base/option")
local hashset        = require("base/hashset")
local scopeinfo      = require("base/scopeinfo")
local interpreter    = require("base/interpreter")
local language       = require("language/language")
local sandbox        = require("sandbox/sandbox")

-- new an instance
function _instance.new(name, opt)
    opt = opt or {}
    local instance = table.inherit(_instance)
    instance._NAME    = name
    instance._INFO    = scopeinfo.new("scheme", {}, {interpreter = scheme._interpreter()})
    instance._PACKAGE = opt.package
    return instance
end

-- get the scheme name
function _instance:name()
    return self._NAME
end

-- get the type: scheme
function _instance:type()
    return "scheme"
end

-- get the it's package
function _instance:package()
    return self._PACKAGE
end

-- get the scheme configuration
function _instance:get(name)
    return self._INFO:get(name)
end

-- set the value to scheme info
function _instance:set(name, ...)
    self._INFO:apival_set(name, ...)
end

-- add the value to scheme info
function _instance:add(name, ...)
    self._INFO:apival_add(name, ...)
end

-- get the extra configuration
function _instance:extraconf(name, item, key)
    return self._INFO:extraconf(name, item, key)
end

-- set the extra configuration
function _instance:extraconf_set(name, item, key, value)
    return self._INFO:extraconf_set(name, item, key, value)
end

-- get urls
function _instance:urls()
    local urls = self._URLS
    if urls == nil then
        urls = table.wrap(self:get("urls"))
        if #urls == 1 and urls[1] == "" then
            urls = {}
        end
    end
    return urls
end

-- get versions
function _instance:versions()
    if self._VERSIONS == nil then
        -- we need to sort the build number in semver list
        -- https://github.com/xmake-io/xmake/issues/6953
        local versions = {}
        for version, _ in table.orderpairs(self:_versions_list()) do
            -- remove the url alias prefix if exists
            local pos = version:find(':', 1, true)
            if pos then
                version = version:sub(pos + 1, -1)
            end
            table.insert(versions, version)
        end
        self._VERSIONS = table.unique(versions)
    end
    return self._VERSIONS
end

-- get versions list
function _instance:_versions_list()
    if self._VERSIONS_LIST == nil then
        local versions = table.wrap(self:get("versions"))
        local versionfiles = self:get("versionfiles")
        if versionfiles then
            for _, versionfile in ipairs(table.wrap(versionfiles)) do
                if not path.is_absolute(versionfile) then
                    local subpath = versionfile
                    versionfile = path.join(self:scriptdir(), subpath)
                    if not os.isfile(versionfile) and self:package() then
                        versionfile = path.join(self:package():scriptdir(), subpath)
                    end
                end
                if os.isfile(versionfile) then
                    local list = io.readfile(versionfile)
                    for _, line in ipairs(list:split("\n")) do
                        local splitinfo = line:split("%s+")
                        if #splitinfo == 2 then
                            local version = splitinfo[1]
                            local shasum = splitinfo[2]
                            versions[version] = shasum
                        end
                    end
                end
            end
        end
        self._VERSIONS_LIST = versions
    end
    return self._VERSIONS_LIST
end

-- get version string
function _instance:version_str()
    return self._VERSION_STR
end

-- set version
function _instance:version_set(version, source)
    self._VERSION_STR = version
    self._VERSION_SOURCE = source
    if source == "branch" then
        self._BRANCH = version
    elseif source == "tag" then
        self._TAG = version
    elseif source == "commit" then
        self._COMMIT = version
    end
end

-- get branch version
function _instance:branch()
    return self._BRANCH
end

-- get tag version
function _instance:tag()
    return self._TAG
end

-- get commit version
function _instance:commit()
    return self._COMMIT
end

-- is git ref?
function _instance:gitref()
    return self:branch() or self:tag() or self:commit()
end

-- interpreter
function scheme._interpreter()
    local interp = scheme._INTERPRETER
    if not interp then
        interp = interpreter.new()
        interp:api_define(scheme.apis())
        scheme._INTERPRETER = interp
    end
    return interp
end

-- get scheme apis
function scheme.apis()
    return {
        values = {
            -- scheme.set_xxx
            "scheme.set_urls",
            -- scheme.add_xxx
            "scheme.add_urls"
        },
        keyvalues = {
            -- scheme.add_xxx
            "scheme.add_patches"
        ,   "scheme.add_resources"
        },
        paths = {
            -- scheme.add_xxx
            "scheme.add_versionfiles"
        },
        dictionary = {
            -- scheme.add_xxx
            "scheme.add_versions"
        }
    }
end

-- new scheme
function scheme.new(name, opt)
    return _instance.new(name, opt)
end

-- return module
return scheme
