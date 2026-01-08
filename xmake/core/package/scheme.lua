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

-- is default scheme?
function _instance:is_default()
    return self:name() == "__default__"
end

-- get the it's package
function _instance:package()
    return self._PACKAGE
end

-- get the scheme configuration
function _instance:get(name)
    local value = self._INFO:get(name)
    if value == nil and self:is_default() and self:package() then
        value = self:package():get(name)
    end
    return value
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
    local value = self._INFO:extraconf(name, item, key)
    if value == nil and self:is_default() and self:package() then
        value = self:package():extraconf(name, item, key)
    end
    return value
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

-- set urls
function _instance:urls_set(urls)
    self._URLS = urls
end

-- get the alias of url, @note need raw url
function _instance:url_alias(url)
    return self:extraconf("urls", url, "alias")
end

-- get the version filter of url, @note need raw url
function _instance:url_version(url)
    return self:extraconf("urls", url, "version")
end

-- get the excludes paths of url
-- @note it supports the path pattern, but it only supports for archiver.
function _instance:url_excludes(url)
    return self:extraconf("urls", url, "excludes")
end

-- get the includes paths of url
-- @note it does not support the path pattern, and it only supports for git url now.
-- @see https://github.com/xmake-io/xmake/issues/6071
function _instance:url_includes(url)
    return self:extraconf("urls", url, "includes")
end

-- get the http headers of url, @note need raw url
function _instance:url_http_headers(url)
    return self:extraconf("urls", url, "http_headers")
end

-- get the script directory
function _instance:scriptdir()
    local scriptdir = self._SCRIPTDIR
    if not scriptdir then
        if self:package() then
            scriptdir = self:package():scriptdir()
        end
        self._SCRIPTDIR = scriptdir
    end
    return scriptdir
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
                    if not os.isfile(versionfile) and self:package() and self:package():base() then
                        versionfile = path.join(self:package():base():scriptdir(), subpath)
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

-- get version
function _instance:version()
    return self._VERSION
end

-- get version string
function _instance:version_str()
    local package = self:package()
    if package and package:is_thirdparty() then
        local requireinfo = package:requireinfo()
        if requireinfo then
            return requireinfo.version
        end
    end
    return self._VERSION_STR
end

-- set version
function _instance:version_set(version, source)

    -- save the semver version
    local sv = semver.new(version)
    if sv then
        self._VERSION = sv
    end

    -- save branch and tag
    if source == "branch" then
        self._BRANCH = version
    elseif source == "tag" then
        self._TAG = version
    elseif source == "commit" then
        self._COMMIT = version
    end

    -- save version string
    if source == "commit" then
        -- we strip it to avoid long paths
        self._VERSION_STR = version:sub(1, 8)
    else
        self._VERSION_STR = version
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

-- get hash of the source package for the url_alias@version_str
function _instance:sourcehash(url_alias)
    local versions    = self:_versions_list()
    local version_str = self:version_str()
    if versions and version_str then
        local sourcehash = nil
        if url_alias then
            sourcehash = versions[url_alias .. ":" ..version_str]
        end
        if not sourcehash then
            sourcehash = versions[version_str]
        end
        if sourcehash and #sourcehash == 40 then
            sourcehash = sourcehash:lower()
        end
        return sourcehash
    end
end

-- get revision(commit, tag, branch) of the url_alias@version_str, only for git url
function _instance:revision(url_alias)
    local revision = self:sourcehash(url_alias)
    if revision and #revision <= 40 then
        -- it will be sha256 of tar/gz file, not commit number if longer than 40 characters
        return revision
    end
end

-- get the patches of the current version
--
-- @code
-- add_patches("6.7.6", "https://cdn.kernel.org/pub/linux/kernel/v6.x/patch-6.7.6.xz",
--    "a394326aa325f8a930a4ce33c69ba7b8b454aef1107a4d3c2a8ae12908615fc4", {reverse = true})
-- @endcode
--
function _instance:patches()
    local patches = self._PATCHES
    if patches == nil then
        local patchinfos = self:get("patches")
        if patchinfos then
            local version_str = self:version_str()
            local patchinfo = patchinfos[version_str]
            if patchinfo then
                patches = {}
                patchinfo = table.wrap(patchinfo)
                for idx = 1, #patchinfo, 2 do
                    local extra = self:extraconf("patches." .. version_str, patchinfo[idx])
                    table.insert(patches , {url = patchinfo[idx], sha256 = patchinfo[idx + 1], extra = extra})
                end
            else
                -- match semver, e.g add_patches(">=1.0.0", url, sha256)
                for range, patchinfo in pairs(patchinfos) do
                    if semver.satisfies(version_str, range) then
                        patches = patches or {}
                        patchinfo = table.wrap(patchinfo)
                        for idx = 1, #patchinfo, 2 do
                            local extra = self:extraconf("patches." .. range, patchinfo[idx])
                            table.insert(patches , {url = patchinfo[idx], sha256 = patchinfo[idx + 1], extra = extra})
                        end
                    end
                end
            end
        end
        self._PATCHES = patches or false
    end
    return patches and patches or nil
end

-- get the resources of the current version
function _instance:resources()
    local resources = self._RESOURCES
    if resources == nil then
        local resourceinfos = self:get("resources")
        if resourceinfos then
            local version_str = self:version_str()
            local resourceinfo = resourceinfos[version_str]
            if resourceinfo then
                resources = {}
                resourceinfo = table.wrap(resourceinfo)
                for idx = 1, #resourceinfo, 3 do
                    local name = resourceinfo[idx]
                    resources[name] = {url = resourceinfo[idx + 1], sha256 = resourceinfo[idx + 2]}
                end
            else
                -- match semver, e.g add_resources(">=1.0.0", name, url, sha256)
                for range, resourceinfo in pairs(resourceinfos) do
                    if semver.satisfies(version_str, range) then
                        resources = resources or {}
                        resourceinfo = table.wrap(resourceinfo)
                        for idx = 1, #resourceinfo, 3 do
                            local name = resourceinfo[idx]
                            resources[name] = {url = resourceinfo[idx + 1], sha256 = resourceinfo[idx + 2]}
                        end
                    end
                end
            end
        end
        self._RESOURCES = resources or false
    end
    return resources and resources or nil
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
