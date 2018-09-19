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
-- @file        vcpkg.lua
--

-- imports
import("lib.detect.find_file")
import("lib.detect.find_library")
import("detect.sdks.find_vcpkgdir")
import("core.project.config")

-- get package info
--
-- @param name  the package name
-- @param opt   the argument options, {version = true, arch = "", plat = "", mode = "", vcpkgdir = ""}
--
-- @return      {links = {"ssl", "crypto", "z"}, linkdirs = {""}, includedirs = {""}, version = ""}
--
-- @code 
--
-- local pkginfo = vcpkg.info("openssl")
-- 
-- @endcode
--
function info(name, opt)

    -- init options
    opt = opt or {}
    
    -- attempt to find the vcpkg root directory
    local vcpkgdir = find_vcpkgdir(opt.vcpkgdir)
    if not vcpkgdir then
        return 
    end

    -- get arch, plat and mode
    local arch = opt.arch or config.arch() or os.arch()
    local plat = opt.plat or config.plat() or os.host()
    local mode = opt.mode or config.mode() or "release"

    -- init cache
    _g._INFO = _g._INFO or {}

    -- get it from cache first
    local key = name .. "_" .. arch .. "_" .. plat .. "_" .. mode
    local result = _g._INFO[key]
    if result ~= nil then
        return result and result or nil
    end

    -- get the vcpkg installed directory
    local installdir = path.join(vcpkgdir, "installed")

    -- get the vcpkg info directory
    local infodir = path.join(installdir, "vcpkg", "info")

    -- find the package info file, .e.g zlib_1.2.11-3_x86-windows.list
    local infofile = find_file(format("%s_*_%s-%s.list", name, arch, plat), infodir)

    -- save includedirs, linkdirs and links
    local info = infofile and io.readfile(infofile) or nil
    if info then
        for _, line in ipairs(info:split('\n')) do
            line = line:trim()

            -- get includedirs
            if line:endswith("/include/") then
                result = result or {}
                result.includedirs = result.includedirs or {}
                table.insert(result.includedirs, path.join(installdir, line))
            end

            -- get linkdirs and links
            if (plat == "windows" and line:endswith(".lib")) or line:endswith(".a") then
                if line:find(plat .. (mode == "debug" and "/debug" or "") .. "/lib/", 1, true) then
                    result = result or {}
                    result.links = result.links or {}
                    result.linkdirs = result.linkdirs or {}
                    table.insert(result.linkdirs, path.join(installdir, path.directory(line)))
                    table.insert(result.links, path.basename(line))
                end
            end
        end
    end

    -- save version
    if opt.version then
        local infoname = path.basename(infofile)
        result.version = infoname:match(name .. "_(%d+%.?%d*%.?%d*.-)_" .. arch)
        if not result.version then
            result.version = infoname:match(name .. "_(%d+%.?%d*%.-)_" .. arch)
        end
    end

    -- save result to cache
    _g._INFO[key] = result and result or false

    -- ok?
    return result
end

-- find package 
--
-- @param name  the package name
-- @param opt   the argument options, {plat = "", arch = "", mode = "", version = "1.0.1", links = {...}, vcpkgdir = ""}
--
-- @return      {links = {"ssl", "crypto", "z"}, linkdirs = {""}, includedirs = {""}}
--
-- @code 
--
-- local pkginfo = vcpkg.find("openssl")
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

    -- find library 
    local result = nil
    for _, link in ipairs(table.wrap(links)) do
        local libinfo = find_library(link, pkginfo.linkdirs)
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

