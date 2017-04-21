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
-- See the License for the specific package governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        package.lua
--

-- define module
local package   = package or {}
local _instance = _instance or {}

-- load modules
local os          = require("base/os")
local io          = require("base/io")
local path        = require("base/path")
local utils       = require("base/utils")
local table       = require("base/table")
local filter      = require("base/filter")
local sandbox     = require("sandbox/sandbox")
local interpreter = require("base/interpreter")
local config      = require("project/config")
local global      = require("project/global")
local project     = require("project/project")
local platform    = require("platform/platform")

-- new an instance
function _instance.new(name, info, rootdir)

    -- new an instance
    local instance = table.inherit(_instance)

    -- init instance
    instance._NAME      = name
    instance._INFO      = info
    instance._ROOTDIR   = rootdir

    -- init filter
    instance._FILTER = filter.new(function (variable)

        -- check
        assert(variable)

        -- init maps
        local maps = 
        {
            os          = platform.os()
        ,   host        = xmake._HOST
        ,   tmpdir      = os.tmpdir()
        ,   curdir      = os.curdir()
        ,   xmake       = path.join(xmake._PROGRAM_DIR, "xmake")
        ,   version     = instance:version()
        }

        -- map it
        return maps[variable]
    end)

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

    -- get it
    return self._NAME
end

-- get the package filter 
function _instance:filter()

    -- get it
    return self._FILTER
end

-- get sha256
function _instance:sha256()

    -- get it from cache first
    if self._SHA256 then
        return self._SHA256
    end

    -- find sha256
    local version  = self:version()
    local sha256s  = table.wrap(self:get("sha256s"))
    local versions = table.wrap(self:get("versions"))
    if version then
        for idx, ver in ipairs(versions) do
            if ver == version then
                self._SHA256 = sha256s[idx]
                break
            end
        end
    end

    -- get it
    return self._SHA256
end

-- get the version  
function _instance:version()

    -- get it
    if self._VERSIONINFO then
        return self._VERSIONINFO.version
    end
end

-- is optional package?
function _instance:optional()

    -- optional?
    if self._VERSIONINFO then
        return self._VERSIONINFO.mode == "optional"
    end
end

-- the verson from tags, branches or versions?
function _instance:verfrom()

    -- optional?
    if self._VERSIONINFO then
        return self._VERSIONINFO.source
    end
end

-- set the version info 
function _instance:versioninfo_set(versioninfo)

    -- set it
    self._VERSIONINFO = versioninfo
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
        ,   "package.set_sha256s"
        ,   "package.set_versions"
        ,   "package.set_homepage"
        ,   "package.set_description"
            -- package.add_xxx
        ,   "package.add_requires"
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
    }
end

-- get the local or global package directory
function package.directory(is_global)

    -- get directory
    if is_global then
        return path.join(global.directory(), "packages")
    else
        return path.join(config.directory(), "packages")
    end
end
  
-- load the package from the package url
function package.load_from_url(packagename, packageurl)

    -- make a temporary package file
    local packagefile = os.tmpfile() .. ".lua"

    -- make package description
    local packagedata = string.format([[
    package("%s")
        set_url("%s")
    ]], packagename, packageurl)

    -- write a temporary package description to file
    local ok, errors = io.writefile(packagefile, packagedata)
    if not ok then
        return nil, errors
    end

    -- load package instance
    local instance, errors = package.load_from_repository(packagename, nil, packagefile)

    -- remove the package file
    os.rm(packagefile)

    -- ok?
    return instance, errors
end

-- load the package from the project file
function package.load_from_project(packagename)

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
    local interp = errors or package._interpreter()

    -- not found?
    if not packages[packagename] then
        return
    end

    -- new an instance
    local instance, errors = _instance.new(packagename, packages[packagename], interp:rootdir())
    if not instance then
        return nil, errors
    end

    -- save instance to the cache
    package._PACKAGES[packagename] = instance

    -- ok
    return instance
end

-- load the package from the package directory or package description file
function package.load_from_repository(packagename, packagedir, packagefile)

    -- get it directly from cache first
    package._PACKAGES = package._PACKAGES or {}
    if package._PACKAGES[packagename] then
        return package._PACKAGES[packagename]
    end

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

    -- check the package name
    if not results[packagename] then
        return nil, string.format("the package %s not found!", name)
    end

    -- new an instance
    local instance, errors = _instance.new(packagename, results[packagename], package._interpreter():rootdir())
    if not instance then
        return nil, errors
    end

    -- save instance to the cache
    package._PACKAGES[packagename] = instance

    -- ok
    return instance
end
     
-- return module
return package
