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
-- @file        find_qt.lua
--

-- imports
import("lib.detect.cache")
import("lib.detect.find_file")
import("core.base.option")
import("core.base.global")
import("core.project.config")

-- find qt sdk directory
function _find_sdkdir(sdkdir)

    -- init the search directories
    local pathes = {}
    if sdkdir then
        table.insert(pathes, path.join(sdkdir, "**", "bin"))
    end
    if os.host() == "macosx" then
        table.insert(pathes, "~/Qt/**/bin")
    elseif os.host() == "windows" then
    else
        table.insert(pathes, "~/Qt/**/bin")
    end

    -- attempt to find qmake
    local qmake = find_file(os.host() == "windows" and "qmake.exe" or "qmake", pathes)
    if qmake then
        return path.directory(path.directory(qmake))
    end
end

-- find qt sdk toolchains
function _find_qt(sdkdir)

    -- find qt directory
    sdkdir = _find_sdkdir(sdkdir)
    if not sdkdir or not os.isdir(sdkdir) then
        return nil
    end

    -- get the bin directory 
    local bindir = path.join(sdkdir, "bin")
    if not os.isexec(path.join(bindir, "qmake")) then
        return nil
    end

    -- get linkdirs
    local linkdirs = {path.join(sdkdir, "lib")}

    -- get includedirs
    local includedirs = {path.join(sdkdir, "include")}

    -- get toolchains
    return {sdkdir = sdkdir, bindir = bindir, linkdirs = linkdirs, includedirs = includedirs}
end

-- find qt sdk toolchains
--
-- @param sdkdir    the qt sdk directory
-- @param opt       the argument options, .e.g {verbose = true, force = false} 
--
-- @return          the qt sdk toolchains. .e.g {sdkdir = ..., bindir = .., linkdirs = ..., includedirs = ..., .. }
--
-- @code 
--
-- local toolchains = find_qt("~/Qt/5.10.1/clang_64")
-- 
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_qt." .. (sdkdir or "")
    local cacheinfo = cache.load(key)
    if not opt.force and cacheinfo.qt then
        return cacheinfo.qt
    end
       
    -- find qt
    local qt = _find_qt(sdkdir or config.get("qt_dir") or global.get("qt_dir"))
    if qt then

        -- save sdk directory to config
        config.set("qt_dir", qt.sdkdir, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for the Qt SDK directory ... ${green}%s", qt.sdkdir)
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for the Qt SDK directory ... ${red}no")
        end
    end

    -- save to cache
    cacheinfo.qt = qt or false
    cache.save(key, cacheinfo)

    -- ok?
    return qt
end
