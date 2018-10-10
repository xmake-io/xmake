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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        pkg_config.lua
--

-- imports
import("core.base.global")
import("core.project.target")
import("core.project.config")
import("lib.detect.find_file")
import("lib.detect.find_library")
import("detect.tools.find_brew")
import("detect.tools.find_pkg_config")

-- get package info
--
-- @param name  the package name
-- @param opt   the argument options, {version = true, configdirs = {"/xxxx/pkgconfig/"}}
--
-- @return      {links = {"ssl", "crypto", "z"}, linkdirs = {""}, includedirs = {""}, version = ""}
--
-- @code 
--
-- local pkginfo = pkg_config.info("openssl")
-- 
-- @endcode
--
function info(name, opt)
    
    -- attempt to add search pathes from pkg-config
    local pkg_config = find_pkg_config()
    if not pkg_config then
        return 
    end

    -- init options and cache
    opt      = opt or {}
    _g._INFO = _g._INFO or {}

    -- get it from cache first
    local result = _g._INFO[name]
    if result ~= nil then
        return result and result or nil
    end

    -- add PKG_CONFIG_PATH
    local configdirs_old = os.getenv("PKG_CONFIG_PATH")
    local configdirs = opt.configdirs or {}
    if #configdirs > 0 then
        os.addenv("PKG_CONFIG_PATH", unpack(configdirs))
    end

    -- attempt to get pkg-config path from `brew --prefix` if no flags
    local brewprefix = nil
    if not flags then

        -- find the config directories from the prefix directories of xmake
        local platsubdirs = path.join(config.get("plat") or os.host(), config.get("arch") or os.arch())
        os.addenv("PKG_CONFIG_PATH", path.join(config.directory(), "prefix", platsubdirs, "release", "lib", "pkgconfig"))
        os.addenv("PKG_CONFIG_PATH", path.join(config.directory(), "prefix", platsubdirs, "debug", "lib", "pkgconfig"))
        os.addenv("PKG_CONFIG_PATH", path.join(global.directory(), "prefix", platsubdirs, "release", "lib", "pkgconfig"))
        os.addenv("PKG_CONFIG_PATH", path.join(global.directory(), "prefix", platsubdirs, "debug", "lib", "pkgconfig"))

        -- find the prefix directory of brew directly, because `brew --prefix name` is too slow!
        local pcfile = find_file(name .. ".pc", "/usr/local/Cellar/" .. (opt.brewhint or name) .. "/*/lib/pkgconfig")
        if pcfile then
            brewprefix = path.directory(path.directory(path.directory(pcfile)))
            os.addenv("PKG_CONFIG_PATH", path.directory(pcfile))
        end
    end

    -- get libs and cflags
    local flags = try { function () return os.iorunv(pkg_config, {"--libs", "--cflags", name}) end }
    if flags then

        -- init result
        result = {}
        for _, flag in ipairs(flags:split('%s*')) do

            -- get links
            local link = flag:match("%-l(.*)") 
            if link then
                result.links = result.links or {}
                table.insert(result.links, link)
            end
       
            -- get linkdirs
            local linkdirs = nil
            local linkdir = flag:match("%-L(.*)") 
            if linkdir and os.isdir(linkdir) then
                result.linkdirs = result.linkdirs or {}
                table.insert(result.linkdirs, linkdir)
            end
       
            -- get includedirs
            local includedirs = nil
            local includedir = flag:match("%-I(.*)") 
            if includedir and os.isdir(includedir) then
                result.includedirs = result.includedirs or {}
                table.insert(result.includedirs, includedir)
            end
        end
    elseif brewprefix then
        local links = {}
        for _, file in ipairs(os.files(path.join(brewprefix, "lib", "*.a"))) do
            table.insert(links, target.linkname(path.filename(file)))
        end
        if #links > 0 then
            result = {links = links, linkdirs = {path.join(brewprefix, "lib")}, includedirs = {path.join(brewprefix, "include")}}
        end
    end

    -- get version
    if opt.version then

        -- get version
        local version = try { function() return os.iorunv(pkg_config, {"--modversion", name}) end }
        if version then
            result = result or {}
            result.version = version:trim()
        end
    end

    -- restore PKG_CONFIG_PATH
    if configdirs_old then
        os.setenv("PKG_CONFIG_PATH", configdirs_old)
    end

    -- save result to cache
    _g._INFO[name] = result and result or false

    -- ok?
    return result
end

-- find package 
--
-- @param name  the package name
-- @param opt   the argument options, {plat = "", arch = "", version = "1.0.1", links = {...}}
--
-- @return      {links = {"ssl", "crypto", "z"}, linkdirs = {""}, includedirs = {""}}
--
-- @code 
--
-- local pkginfo = pkg_config.find("openssl")
-- 
-- @endcode
--
function find(name, opt)

    -- get package info
    local pkginfo = info(name, opt)
    if not pkginfo then
        return 
    end

    -- match version?
    opt = opt or {}
    if opt.version and pkginfo.version ~= opt.version then
        return 
    end

    -- get links
    local links = pkginfo.links
    if not links or #links == 0 then
        links = opt.links
    end

    -- add default search linkdirs on pc host
    local linkdirs = pkginfo.linkdirs
    if links and #links > 0 and (not linkdirs or #linkdirs == 0) then
        linkdirs = linkdirs or {}
        table.insert(linkdirs, "/usr/local/lib")
        table.insert(linkdirs, "/usr/lib")
        table.insert(linkdirs, "/opt/local/lib")
        table.insert(linkdirs, "/opt/lib")
        if opt.plat == "linux" and opt.arch == "x86_64" then
            table.insert(linkdirs, "/usr/local/lib/x86_64-linux-gnu")
            table.insert(linkdirs, "/usr/lib/x86_64-linux-gnu")
            table.insert(linkdirs, "/usr/lib64")
            table.insert(linkdirs, "/opt/lib64")
        end
    end

    -- find library 
    local result = nil
    for _, link in ipairs(table.wrap(links)) do
        local libinfo = find_library(link, linkdirs)
        if libinfo then
            result          = result or {}
            result.links    = table.join(result.links or {}, libinfo.link)
            result.linkdirs = table.join(result.linkdirs or {}, libinfo.linkdir)
        end
    end

    -- found?
    if result and result.links then
        result.linkdirs     = table.unique(result.linkdirs)
        result.includedirs  = table.join(result.includedirs or {}, pkginfo.includedirs)
    end

    -- ok?
    return result
end
