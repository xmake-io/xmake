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
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_package.lua
--

-- imports
import("core.base.global")
import("core.project.config")
import("core.project.option")
import("core.project.target")
import("core.language.language")
import("lib.detect.find_file")
import("lib.detect.find_library")

-- find package from the repository (maybe only include and no links)
function _find_package_from_repo(name, opt)

    -- get build mode, e.g. debug_f7821231
    local mode = table.concat({opt.mode or "release", opt.configs_hash}, '_')

    -- get the prefix directories
    local prefixdirs = table.wrap(opt.prefixdirs)
    local platsubdirs = path.join(config.get("plat") or os.host(), config.get("arch") or os.arch())
    if #prefixdirs == 0 then
        table.insert(prefixdirs, path.join(opt.islocal and config.directory() or global.directory(), "prefix", platsubdirs, mode))
    end

    -- find the prefix info file of package, .e.g prefix/info/z/zlib/1.2.11/info.txt
    local packagedirs = {}
    local packagepath = path.join(name:sub(1, 1), name, "*")
    table.insert(packagedirs, path.join(opt.islocal and config.directory() or global.directory(), "prefix", "info", platsubdirs, mode, packagepath))
    local prefixfile = find_file("info.txt", packagedirs)
    if not prefixfile then
        return 
    end

    -- load prefix info
    local prefixinfo = io.load(prefixfile)
    if not prefixinfo then
        return 
    end

    -- get prefix directory of this package
    local prefixdir = path.translate(path.directory(path.directory(path.directory(path.directory(prefixfile)))):gsub("[/\\]prefix[/\\]info[/\\]", "/prefix/"))

    -- save includedirs to result (maybe only include and no links)
    local result = {}
    local includedirs = {}
    for _, includedir in ipairs(prefixinfo.includedirs) do
        table.insert(includedirs, path.join(prefixdir, includedir))
    end
    if #includedirs == 0 then
        table.insert(includedirs, path.join(prefixdir, "include"))
    end
    result.includedirs = table.unique(includedirs)

    -- get links and link directories
    local links = {}
    local linkdirs = {}
    for _, linkdir in ipairs(prefixinfo.linkdirs) do
        table.insert(linkdirs, path.join(prefixdir, linkdir))
    end
    if prefixinfo.links then
        table.join2(links, prefixinfo.links)
    end
    if prefixinfo.installed and (not prefixinfo.linkdirs or not prefixinfo.links) then
        local found = false
        for _, line in ipairs(prefixinfo.installed) do
            line = line:trim()
            if line:endswith(".lib") or line:endswith(".a") then
                found = true
                if not prefixinfo.linkdirs then
                    table.insert(linkdirs, path.join(prefixdir, path.directory(line)))
                end
                if not prefixinfo.links then
                    table.insert(links, target.linkname(path.filename(line)))
                end
            end
        end
        if not found then
            for _, line in ipairs(prefixinfo.installed) do
                line = line:trim()
                if line:endswith(".so") or line:endswith(".dylib") then
                    if not prefixinfo.linkdirs then
                        table.insert(linkdirs, path.join(prefixdir, path.directory(line)))
                    end
                    if not prefixinfo.links then
                        table.insert(links, target.linkname(path.filename(line)))
                    end
                end
            end
        end
    end

    -- add root include and link directories
    if #linkdirs == 0 then
        table.insert(linkdirs, path.join(prefixdir, "lib"))
    end

    -- uses name as links directly .e.g libname.a
    if #links == 0 then
        links = table.wrap(name)
    end

    -- find library 
    for _, link in ipairs(links) do
        local libinfo = find_library(link, linkdirs)
        if libinfo then
            result.links    = table.join(result.links or {}, libinfo.link)
            result.linkdirs = table.join(result.linkdirs or {}, libinfo.linkdir)
        end
    end
    -- make unique links
    if result.links then
        result.links = table.unique(result.links)
    end

    -- inherit the other prefix variables
    for name, values in pairs(prefixinfo) do
        if name ~= "links" and name ~= "linkdirs" and name ~= "includedirs" and name ~= "installed" and name ~= "prefixdir" then
            result[name] = values
        end
    end

    -- get version
    result.version = path.filename(path.directory(prefixfile))

    -- ok
    return result
end

-- find package from the package directories
function _find_package_from_packagedirs(name, opt)

    -- get package path (.e.g name.pkg) in the package directories
    local packagepath = nil
    for _, dir in ipairs(table.wrap(opt.packagedirs)) do
        local p = path.join(dir, name .. ".pkg")
        if os.isdir(p) then
            packagepath = p
            break
        end
    end
    if not packagepath then
        return 
    end

    -- get package file (.e.g name.pkg/xmake.lua)
    local packagefile = path.join(packagepath, "xmake.lua")
    if not os.isfile(packagefile) then
        return 
    end

    -- init interpreter
    local interp = option.interpreter()

    -- register filter handler
    interp:filter():register("find_package", function (variable)
 
        -- init maps
        local maps = 
        {
            arch       = opt.arch
        ,   plat       = opt.plat
        ,   mode       = opt.mode 
        }

        -- get variable
        return maps[variable]
    end)

    -- load script
    local ok, errors = interp:load(packagefile)
    if not ok then
        raise(errors)
    end

    -- load the package from the the package file
    local packageinfos, errors = interp:make("option", true, true)
    if not packageinfos then
        raise(errors)
    end

    -- unregister filter handler
    interp:filter():register("find_package", nil)
 
    -- get package info
    local packageinfo = packageinfos[name]
    if not packageinfo then
        return 
    end

    -- get linkdirs
    local linkdirs = {}
    for _, linkdir in ipairs(packageinfo:get("linkdirs")) do
        table.insert(linkdirs, path.join(packagepath, linkdir))
    end
    if #linkdirs == 0 then
        return 
    end

    -- find library 
    local result = nil
    for _, link in ipairs(packageinfo:get("links")) do
        local libinfo = find_library(link, linkdirs)
        if libinfo then
            result          = result or {}
            result.links    = table.join(result.links or {}, libinfo.link)
            result.linkdirs = table.join(result.linkdirs or {}, libinfo.linkdir)
        end
    end

    -- inherit other package info
    if result then
        result.includedirs = {}
        for _, includedir in ipairs(packageinfo:get("includedirs")) do
            table.insert(result.includedirs, path.join(packagepath, includedir))
        end
        for _, infoname in ipairs({"defines", "languages", "warnings"}) do
            result[infoname] = packageinfo:get(infoname)
        end
    end

    -- ok?
    return result
end

-- find package using the xmake package manager
--
-- @param name  the package name
-- @param opt   the options, .e.g {verbose = true, version = "1.12.x", configs_hash = "xxxxxx")
--
function main(name, opt)

    -- find package from repository
    local result = _find_package_from_repo(name, opt)

    -- find package from the given package directories, e.g. packagedir/xxx.pkg
    if not result and opt.packagedirs then
        result = _find_package_from_packagedirs(name, opt)
    end
    return result
end
