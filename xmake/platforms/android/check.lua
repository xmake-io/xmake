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
-- @file        check.lua
--

-- imports
import(".checker")
import("detect.sdks.find_ndk_sdkvers")
import("detect.sdks.find_ndk_toolchains")

-- check the sdk version for ndk
function _check_ndk_sdkver(config)

    -- get ndk sdk version
    local ndk_sdkver = config.get("ndk_sdkver")
    if not ndk_sdkver then 

        -- find the max version
        local sdkver_max = 0
        for _, sdkver in ipairs(find_ndk_sdkvers(config.get("ndk"))) do

            -- get the max version
            sdkver = tonumber(sdkver)
            if sdkver > sdkver_max then
                sdkver_max = sdkver
            end
        end

        -- save the version
        if sdkver_max > 0 then ndk_sdkver = sdkver_max end

        -- probe ok? update it
        if ndk_sdkver ~= nil and ndk_sdkver > 0 then 

            -- save it
            config.set("ndk_sdkver", ndk_sdkver)

            -- trace
            cprint("checking for the SDK version of NDK ... ${green}android-%d", ndk_sdkver)
        else

            -- trace
            cprint("checking for the SDK version of NDK ... ${red}no")
        end
    end
end

-- check toolchains 
function _check_toolchains(config)

    -- get toolchains directory
    local toolchains = config.get("toolchains")
    if not toolchains then

        -- find first toolchains 
        for _, toolchains in ipairs(find_ndk_toolchains(config.get("ndk"), config.get("arch"))) do
            config.set("toolchains", toolchains.bin)
            config.set("cross", toolchains.cross)
            break
        end
    end
    toolchains = config.get("toolchains")

    -- get toolchains version
    local toolchains_ver = config.get("toolchains_ver")
    if not toolchains_ver and toolchains then
        local toolchains_ver = toolchains:match("%-(%d*%.%d*)[/\\]")
        if toolchains_ver then

            -- save the toolchains version
            config.set("toolchains_ver", toolchains_ver)
 
            -- trace
            cprint("checking for the version of toolchains ... ${green}%s", toolchains_ver)
        else
            -- trace
            cprint("checking for the version of toolchains ... ${red}no")
        end
    end
end

-- get toolchains
function _toolchains(config)

    -- attempt to get it from cache first
    if _g.TOOLCHAINS then
        return _g.TOOLCHAINS
    end

    -- get architecture
    local arch = config.get("arch")

    -- get cross
    local cross = config.get("cross") 

    -- init toolchains
    local toolchains = {}

    -- check c/c++ tools to toolchains
    checker.toolchain_insert(toolchains, "cc",       cross,  "gcc",          "the c compiler") 
    checker.toolchain_insert(toolchains, "cxx",      cross,  "g++",          "the c++ compiler") 
    checker.toolchain_insert(toolchains, "as",       cross,  "gcc",          "the assember")
    checker.toolchain_insert(toolchains, "ld",       cross,  "g++",          "the linker") 
    checker.toolchain_insert(toolchains, "ld",       cross,  "gcc",          "the linker") 
    checker.toolchain_insert(toolchains, "ar",       cross,  "ar",           "the static library archiver") 
    checker.toolchain_insert(toolchains, "ex",       cross,  "ar",           "the static library extractor") 
    checker.toolchain_insert(toolchains, "sh",       cross,  "g++",          "the shared library linker") 
    checker.toolchain_insert(toolchains, "sh",       cross,  "gcc",          "the shared library linker") 

    -- insert rust tools to toolchains
    checker.toolchain_insert(toolchains, "rc",       "",      "rustc",       "the rust compiler") 
    checker.toolchain_insert(toolchains, "rc-ar",    "",      "rustc",       "the rust static library archiver") 
    checker.toolchain_insert(toolchains, "rc-sh",    "",      "rustc",       "the rust shared library linker") 
    checker.toolchain_insert(toolchains, "rc-ld",    "",      "rustc",       "the rust linker") 

    -- save toolchains
    _g.TOOLCHAINS = toolchains

    -- ok
    return toolchains
end

-- check it
function main(kind, toolkind)

    -- only check the given tool?
    if toolkind then
        return checker.toolchain_check(kind, toolkind, _toolchains)
    end

    -- init the check list of config
    _g.config = 
    {
        { checker.check_arch, "armv7-a" }
    ,   _check_ndk_sdkver
    ,   _check_toolchains
    ,   { checker.toolchain_check, "sh", _toolchains }
    ,   { checker.toolchain_check, "ld", _toolchains }
    }

    -- init the check list of global
    _g.global = 
    {
        _check_ndk_sdkver
    }

    -- check it
    checker.check(kind, _g)
end


