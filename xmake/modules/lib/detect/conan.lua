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
-- @file        conan.lua
--

-- imports
import("lib.detect.find_file")
import("lib.detect.find_library")
import("detect.sdks.find_conandir")
import("core.project.config")
import("core.project.target")

-- get package info
--
-- @param name  the package name
-- @param opt   the argument options, {version = true, arch = "", plat = "", mode = "", conandir = ""}
--
-- @return      {links = {"ssl", "crypto", "z"}, linkdirs = {""}, includedirs = {""}, version = ""}
--
-- @code 
--
-- local pkginfo = conan.info("openssl")
-- 
-- @endcode
--
function info(name, opt)

    -- init options
    opt = opt or {}
    
    -- attempt to find the conan root directory
    local conandir = find_conandir(opt.conandir)
    if not conandir then
        return 
    end

    -- init cache
    _g._INFO = _g._INFO or {}

    -- get it from cache first
    local key = name 
    local result = _g._INFO[key]
    if result ~= nil then
        return result and result or nil
    end

    -- find the package conanmanifest file, .e.g ~/.conan/data/pcre2/10.31/bincrafters/stable/package/519f362e9832d00859a5da6d5f76da34ecf8e237/conanmanifest.txt
    local manifestfile = find_file("conanmanifest.txt", path.join(conandir, "data", name, "*", "*", "*", "package", "*"))

    -- save includedirs, linkdirs and links
    local info = manifestfile and io.readfile(manifestfile) or nil
    if info then
        local installdir = path.directory(manifestfile)
        result = {includedirs = path.join(installdir, "include"), linkdirs = path.join(installdir, "lib")}
        for _, line in ipairs(info:split('\n')) do
            line = line:split(':')[1]:trim()
            if line:startswith("lib") and (line:endswith(".lib") or line:endswith(".a")) then
                result.links = result.links or {}
                table.insert(result.links, target.linkname(path.filename(line)))
            end
        end
    end

    -- save version
    if result and manifestfile then
        result.version = manifestfile:match(path.join(name, "(%d+%.?%d*%.?%d*.-)"))
        if not result.version then
            result.version = manifestfile:match(path.join(name, "(%d+%.?%d*%.-)"))
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
-- @param opt   the argument options, {version = "1.0.1", links = {...}, conandir = ""}
--
-- @return      {links = {"ssl", "crypto", "z"}, linkdirs = {""}, includedirs = {""}}
--
-- @code 
--
-- local pkginfo = conan.find("openssl")
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

