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
-- See the License for the specific package governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        package.lua
--

-- define module
local package   = package or {}
local _instance = _instance or {}

-- load modules
local os             = require("base/os")
local io             = require("base/io")
local path           = require("base/path")
local utils          = require("base/utils")
local table          = require("base/table")
local global         = require("base/global")
local interpreter    = require("base/interpreter")
local sandbox        = require("sandbox/sandbox")
local config         = require("project/config")
local platform       = require("platform/platform")
local sandbox        = require("sandbox/sandbox")
local sandbox_os     = require("sandbox/modules/os")
local sandbox_module = require("sandbox/modules/import/core/sandbox/module")

-- new an instance
function _instance.new(name, info, rootdir)

    -- new an instance
    local instance = table.inherit(_instance)

    -- init instance
    instance._name  = name
    instance._NAME      = name
    instance._INFO      = info
    instance._ROOTDIR   = rootdir

    -- ok
    return instance
end

-- get the package configure
function _instance:get(name)

    -- the info
    local info = self._INFO

    -- get if from info first
    local value = info[name]
    if value ~= nil then
        return value 
    end
end

-- get the package name 
function _instance:name()
    return self._NAME
end

-- get the repository of this package
function _instance:repo()
    return self._REPO
end

-- get the package alias  
function _instance:alias()
    local requireinfo = self:requireinfo()
    if requireinfo then
        return requireinfo.alias 
    end
end

-- get urls
function _instance:urls()
    return self._URLS or table.wrap(self:get("urls"))
end

-- get urls
function _instance:urls_set(urls)
    self._URLS = urls
end

-- get the alias of url, @note need raw url
function _instance:url_alias(url)
    local urls_extra = self:get("__extra_urls")
    if urls_extra then
        local urlextra = urls_extra[url]
        if urlextra then
            return urlextra.alias
        end
    end
end

-- get deps
function _instance:deps()
    return self._DEPS
end

-- get order deps
function _instance:orderdeps()
    return self._ORDERDEPS
end

-- get sha256 of the url_alias@version_str
function _instance:sha256(url_alias)

    -- get sha256
    local versions    = self:get("versions")
    local version_str = self:version_str()
    if versions and version_str then

        local sha256 = nil
        if url_alias then
            sha256 = versions[url_alias .. ":" ..version_str]
        end
        if not sha256 then
            sha256 = versions[version_str]
        end

        -- ok?
        return sha256
    end
end

-- this package is from system/local/global?
--
-- @param kind  the from kind
--
-- system: from the system directories (.e.g /usr/local)
-- local:  from the local project package directories (.e.g projectdir/.xmake/packages)
-- global: from the global package directories (.e.g ~/.xmake/packages)
--
function _instance:from(kind)
    return self._FROMKIND == kind
end

-- get the package kind, binary or nil(static, shared)
function _instance:kind()
    return self:get("kind")
end

-- get the build directory of this package
function _instance:buildir()
    return path.join(self:cachedir(), "build")
end

-- get the cached directory of this package
function _instance:cachedir()
    return path.join(package.cachedir(), self:name():sub(1, 1):lower(), self:name(), self:version_str())
end

-- get the installed directory of this package
function _instance:installdir()

    -- only be a system package without urls, no installdir
    if self:from("system") then
        return 
    end

    -- make install directory
    return path.join(package.installdir(self:from("global")), self:name():sub(1, 1):lower(), self:name(), self:version_str())
end

-- get versions
function _instance:versions()

    -- make versions 
    if self._VERSIONS == nil then

        -- get versions
        local versions = {}
        for version, _ in pairs(table.wrap(self:get("versions"))) do

            -- remove the url alias prefix if exists
            local pos = version:find(':', 1, true)
            if pos then
                version = version:sub(pos + 1, -1)
            end
            table.insert(versions, version)
        end

        -- remove repeat
        self._VERSIONS = table.unique(versions)
    end
    return self._VERSIONS
end

-- get the version  
function _instance:version()
    return self._VERSION or {}
end

-- get the version string 
function _instance:version_str()
    return self:version().raw or self:version().version
end

-- the verson from tags, branches or versions?
function _instance:version_from(...)

    -- from source?
    for _, source in ipairs({...}) do
        if self:version().source == source then
            return true
        end
    end
end

-- set the version
function _instance:version_set(version, source)

    -- init package version
    if type(version) == "string" then
        version = {version = version, source = source}
    else
        version.source = source
    end

    -- save version
    self._VERSION = version
end

-- get the require info 
function _instance:requireinfo()
    return self._REQUIREINFO 
end

-- set the require info 
function _instance:requireinfo_set(requireinfo)
    self._REQUIREINFO = requireinfo
end

-- get xxx_script
function _instance:script(name, generic)

    -- get script
    local script = self:get(name)
    local result = nil
    if type(script) == "function" then
        result = script
    elseif type(script) == "table" then

        -- match script for special plat and arch
        local plat = (config.get("plat") or "")
        local pattern = plat .. '|' .. (config.get("arch") or "")
        for _pattern, _script in pairs(script) do
            if not _pattern:startswith("__") and pattern:find('^' .. _pattern .. '$') then
                result = _script
                break
            end
        end

        -- match script for special plat
        if result == nil then
            for _pattern, _script in pairs(script) do
                if not _pattern:startswith("__") and plat:find('^' .. _pattern .. '$') then
                    result = _script
                    break
                end
            end
        end

        -- get generic script
        result = result or script["__generic__"] or generic
    end

    -- only generic script
    result = result or generic

    -- imports some modules first
    if result and result ~= generic then
        local scope = getfenv(result)
        if scope then
            for _, modulename in ipairs(table.wrap(self:get("imports"))) do
                scope[sandbox_module.name(modulename)] = sandbox_module.import(modulename, {anonymous = true})
            end
        end
    end

    -- ok
    return result
end

-- fetch package info from the local packages
--
-- @return {packageinfo}, fetchfrom (.e.g local/global/system)
--
function _instance:fetch(force)

    -- attempt to get it from cache
    local fetchfrom = self._FETCHFROM
    local fetchinfo = self._FETCHINFO
    if not force and fetchinfo then
        return fetchinfo, fetchfrom
    end

    -- fetch binary tool?
    fetchinfo = nil
    fetchfrom = nil
    if self:kind() == "binary" then
    
        -- import find_tool
        self._find_tool = self._find_tool or sandbox_module.import("lib.detect.find_tool", {anonymous = true})

        -- fetch it from the system directories
        fetchinfo = self._find_tool(self:name(), {force = force})
        if fetchinfo then
            fetchfrom = "system" -- ignore self:requireinfo().system
        end
    else

        -- import find_package
        self._find_package = self._find_package or sandbox_module.import("lib.detect.find_package", {anonymous = true})

        -- fetch it from the package directories first
        local installdir = self:installdir()
        if not fetchinfo and installdir then
            fetchinfo = self._find_package(self:name(), {packagedirs = installdir, system = false, cachekey = "package:fetch", force = force}) 
            if fetchinfo then fetchfrom = self._FROMKIND end
        end

        -- fetch it from the system directories
        if not fetchinfo then
            local system = self:requireinfo().system
            if system == nil then -- find system package by default
                system = true
            end
            if system then
                fetchinfo = self._find_package(self:name(), {force = force})
                if fetchinfo then fetchfrom = "system" end
            end
        end
    end

    -- save to cache
    self._FETCHINFO = fetchinfo
    self._FETCHFROM = fetchfrom

    -- ok
    return fetchinfo, fetchfrom
end

-- exists this package in local
function _instance:exists()
    return self._FETCHINFO
end

-- the interpreter
function package._interpreter()

    -- the interpreter has been initialized? return it directly
    if package._INTERPRETER then
        return package._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)
 
    -- define apis
    interp:api_define(package.apis())
    
    -- save interpreter
    package._INTERPRETER = interp

    -- ok?
    return interp
end

-- get package apis
function package.apis()

    return 
    {
        values =
        {
            -- package.set_xxx
            "package.set_urls"
        ,   "package.set_kind"
        ,   "package.set_homepage"
        ,   "package.set_description"
            -- package.add_xxx
        ,   "package.add_deps"
        ,   "package.add_urls"
        ,   "package.add_imports"
        }
    ,   script =
        {
            -- package.on_xxx
            "package.on_build"
        ,   "package.on_install"
        ,   "package.on_test"

            -- package.before_xxx
        ,   "package.before_build"
        ,   "package.before_install"
        ,   "package.before_test"

            -- package.before_xxx
        ,   "package.after_build"
        ,   "package.after_install"
        ,   "package.after_test"
        }
    ,   dictionary = 
        {
            -- package.add_xxx
            "package.add_versions"
        }
    }
end

-- get install directory
function package.installdir(is_global)

    -- get directory
    if is_global then
        return path.join(global.directory(), "packages")
    else
        return path.join(config.directory(), "packages")
    end
end

-- the cache directory
function package.cachedir()
    return path.join(global.directory(), "cache", "packages")
end

-- load the package from the system directories
function package.load_from_system(packagename)

    -- get it directly from cache first
    package._PACKAGES = package._PACKAGES or {}
    if package._PACKAGES[packagename] then
        return package._PACKAGES[packagename]
    end

    -- new an empty instance
    local instance, errors = _instance.new(packagename, {}, package._interpreter():rootdir())
    if not instance then
        return nil, errors
    end

    -- mark as system package
    instance._FROMKIND = "system"

    -- save instance to the cache
    package._PACKAGES[packagename] = instance

    -- ok
    return instance
end

-- load the package from the project file
function package.load_from_project(packagename, project)

    -- get it directly from cache first
    package._PACKAGES = package._PACKAGES or {}
    if package._PACKAGES[packagename] then
        return package._PACKAGES[packagename]
    end

    -- load packages (with cache)
    local packages, errors = project.packages()
    if not packages then
        return nil, errors
    end

    -- get interpreter
    local interp = project.interpreter() or package._interpreter()

    -- not found?
    if not packages[packagename] then
        return
    end

    -- new an instance
    local instance, errors = _instance.new(packagename, packages[packagename], interp:rootdir())
    if not instance then
        return nil, errors
    end

    -- mark as local package
    instance._FROMKIND = "local"

    -- save instance to the cache
    package._PACKAGES[packagename] = instance

    -- ok
    return instance
end

-- load the package from the package directory or package description file
function package.load_from_repository(packagename, repo, packagedir, packagefile)

    -- get it directly from cache first
    package._PACKAGES = package._PACKAGES or {}
    if package._PACKAGES[packagename] then
        return package._PACKAGES[packagename]
    end

    -- load repository first for checking the xmake minimal version
    repo:load()

    -- find the package script path
    local scriptpath = packagefile
    if not packagefile and packagedir then
        scriptpath = path.join(packagedir, "xmake.lua")
    end
    if not scriptpath or not os.isfile(scriptpath) then
        return nil, string.format("the package %s not found!", packagename)
    end

    -- load package and disable filter, we will process filter after a while
    local results, errors = package._interpreter():load(scriptpath, "package", true, false)
    if not results and os.isfile(scriptpath) then
        return nil, errors
    end

    -- get the package info
    local packageinfo = nil
    for name, info in pairs(results) do
        packagename = name -- use the real package name in package() definition
        packageinfo = info
        break
    end

    -- check this package 
    if not packageinfo then
        return nil, string.format("%s: the package %s not found!", scriptpath, packagename)
    end

    -- new an instance
    local instance, errors = _instance.new(packagename, packageinfo, package._interpreter():rootdir())
    if not instance then
        return nil, errors
    end

    -- save repository
    instance._REPO = repo

    -- mark as global/project package?
    instance._FROMKIND = repo:is_global() and "global" or "local"

    -- save instance to the cache
    package._PACKAGES[packagename] = instance

    -- ok
    return instance
end
     
-- return module
return package
