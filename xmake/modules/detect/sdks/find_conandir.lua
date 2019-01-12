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
-- @file        find_conandir.lua
--

-- imports
import("lib.detect.cache")
import("lib.detect.find_file")
import("core.base.option")
import("core.base.global")
import("core.project.config")

-- find conan directory
function _find_conandir(sdkdir)

    -- init the search directories
    local pathes = {}
    if sdkdir then
        table.insert(pathes, sdkdir)
    end
    table.insert(pathes, path.translate("~/.conan"))

    -- attempt to find conan.conf
    local conan = find_file("conan.conf", pathes)
    if conan then
        return path.directory(conan)
    end
end

-- find conan directory
--
-- @param sdkdir    the conan directory
-- @param opt       the argument options, .e.g {verbose = true, force = false} 
--
-- @return          the conan directory
--
-- @code 
--
-- local conandir = find_conandir()
-- 
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_conandir" .. (sdkdir or "")
    local cacheinfo = cache.load(key)
    if not opt.force and cacheinfo.conan ~= nil then
        return cacheinfo.conan
    end
       
    -- find conan
    local conan = _find_conandir(sdkdir or config.get("conan") or global.get("conan"))
    if conan then

        -- save to config
        config.set("conan", conan, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for the conan directory ... ${color.success}%s", conan)
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for the conan directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.conan = conan or false
    cache.save(key, cacheinfo)

    -- ok?
    return conan
end
