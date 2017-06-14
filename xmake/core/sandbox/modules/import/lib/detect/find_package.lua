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
-- @file        find_package.lua
--

-- define module
local sandbox_lib_detect_find_package = sandbox_lib_detect_find_package or {}

-- load modules
local os                = require("base/os")
local path              = require("base/path")
local utils             = require("base/utils")
local table             = require("base/table")
local option            = require("base/option")
local cache             = require("project/cache")
local config            = require("project/config")
local project           = require("project/project")
local raise             = require("sandbox/modules/raise")
local import            = require("sandbox/modules/import")
local find_file         = import("lib.detect.find_file")
local find_library      = import("lib.detect.find_library")
local pkg_config        = import("lib.detect.pkg_config")

-- find package from project package directories
function sandbox_lib_detect_find_package._find_from_project_packagedirs(name, opt)

    -- TODO
end

-- find package from repositories
function sandbox_lib_detect_find_package._find_from_repositories(name, opt)

    -- TODO in repo branch
end

-- find package from modules (detect.package.find_xxx)
function sandbox_lib_detect_find_package._find_from_modules(name, opt)

    -- "detect.package.find_xxx" exists?
    if os.isfile(path.join(os.programdir(), "modules", "detect", "package", "find_" .. name .. ".lua")) then
        local find_package = import("detect.package.find_" .. name, {anonymous = true})
        if find_package then
            return find_package(opt)
        end
    end
end

-- find package from pkg-config
function sandbox_lib_detect_find_package._find_from_pkg_config(name, opt)
    return pkg_config.find(name, opt)
end

-- find package from system directories
function sandbox_lib_detect_find_package._find_from_systemdirs(name, opt)

    -- cannot get the version of package
    if opt.version then
        return 
    end

    -- add default search pathes on pc host
    local pathes = {}
    if opt.plat == "linux" or opt.plat == "macosx" then
        table.insert(pathes, "/usr/local/lib")
        table.insert(pathes, "/usr/lib")
        table.insert(pathes, "/opt/local/lib")
        table.insert(pathes, "/opt/lib")
        if opt.plat == "linux" and opt.arch == "x86_64" then
            table.insert(pathes, "/usr/local/lib/x86_64-linux-gnu")
            table.insert(pathes, "/usr/lib/x86_64-linux-gnu")
        end
    end

    -- attempt to get links from pkg-config
    local pkginfo = nil
    local links = opt.links
    if not links then
        pkginfo = pkg_config.info(name)
        if pkginfo then
            links = pkginfo.links
        end
    end

    -- find library 
    local result = nil
    for _, link in ipairs(table.wrap(links)) do
        local libinfo = find_library(link, pathes)
        if libinfo then
            result          = result or {}
            result.links    = table.join(result.links or {}, libinfo.link)
            result.linkdirs = table.join(result.linkdirs or {}, libinfo.linkdir)
        end
    end

    -- not found? only add links
    if not result and pkginfo and pkginfo.links then
        result = {links = pkginfo.links}
    end

    -- ok
    return result
end

-- find package
function sandbox_lib_detect_find_package._find(name, opt)

    -- init find scripts
    local findscripts = 
    {
        sandbox_lib_detect_find_package._find_from_project_packagedirs
    ,   sandbox_lib_detect_find_package._find_from_repositories
    ,   sandbox_lib_detect_find_package._find_from_modules
    }

    -- find package from the current host platform
    if opt.plat == os.host() and opt.arch == os.arch() then
        table.insert(findscripts, sandbox_lib_detect_find_package._find_from_pkg_config)
        table.insert(findscripts, sandbox_lib_detect_find_package._find_from_systemdirs)
    end

    -- find it
    local result = nil
    for _, find in ipairs(findscripts) do
        result = find(name, opt)
        if result then
            break
        end
    end

    -- remove repeat
    if result then
        result.linkdirs    = table.unique(result.linkdirs)
        result.includedirs = table.unique(result.includedirs)
    end

    -- ok?
    return result
end

-- find package 
--
-- @param name      the package name
-- @param opt       the package options. e.g. {plat = "iphoneos", arch = "arm64", version = "1.0.1", pathes = {"/usr/lib"}, links = {"ssl"}, includes = {"ssl.h"}}
--
-- @return          {links = {"ssl", "crypto", "z"}, linkdirs = {"/usr/local/lib"}, includedirs = {"/usr/local/include"}}
--
-- @code 
--
-- local package = find_package("openssl")
-- local package = find_package("openssl", {version = "1.0.1"})
-- local package = find_package("openssl", {plat = "iphoneos"})
-- local package = find_package("openssl", {pathes = {"/usr/lib", "/usr/local/lib", "/usr/local/include"}, version = "1.0.1"})
-- local package = find_package("openssl", {pathes = {"/usr/lib", "/usr/local/lib", "/usr/local/include"}, links = {"ssl", "crypto"}, includes = {"ssl.h"}})
-- 
-- @endcode
--
function sandbox_lib_detect_find_package.main(name, opt)

    -- get detect cache 
    local detectcache = cache(utils.ifelse(os.isfile(project.file()), "local.detect", "memory.detect"))
 
    -- init options
    opt = opt or {}
    opt.plat = opt.plat or config.get("plat") or os.host()
    opt.arch = opt.arch or config.get("arch") or os.arch()

    -- init cache key
    local key = "find_package_" .. opt.plat .. "_" .. opt.arch

    -- attempt to get result from cache first
    local cacheinfo = detectcache:get(key) or {}
    local result = cacheinfo[name]
    if result ~= nil then
        return utils.ifelse(result, result, nil)
    end

    -- find package
    result = sandbox_lib_detect_find_package._find(name, opt) 

    -- cache result
    cacheinfo[name] = utils.ifelse(result, result, false)

    -- save cache info
    detectcache:set(key, cacheinfo)
    detectcache:flush()

    -- trace
    if option.get("verbose") then
        if result then
            utils.cprint("checking for the %s ... ${green}ok", name)
        else
            utils.cprint("checking for the %s ... ${red}no", name)
        end
    end

    -- ok?
    return result
end

-- return module
return sandbox_lib_detect_find_package
