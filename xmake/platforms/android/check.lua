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
import("core.tool.tool")
import("platforms.checker", {rootdir = os.programdir()})

-- check the sdk version for ndk
function _check_ndk_sdkver(config)

    -- get ndk sdk version
    local ndk_sdkver = config.get("ndk_sdkver")
    if not ndk_sdkver then 

        -- get the ndk
        local ndk = config.get("ndk")
        if ndk then

            -- match all sdk directories
            local version_maxn = 0
            for _, sdkdir in ipairs(os.match(ndk .. "/platforms/android-*", true)) do

                -- get version
                local filename = path.filename(sdkdir)
                local version, count = filename:gsub("android%-", "")
                if count > 0 then

                    -- get the max version
                    version = tonumber(version)
                    if version > version_maxn then
                        version_maxn = version 
                    end
                end
            end

            -- save the version
            if version_maxn > 0 then ndk_sdkver = version_maxn end
        end

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

-- check the toolchains
function _check_toolchains(config)

    -- get architecture
    local arch = config.get("arch")

    -- get toolchains
    local toolchains = config.get("toolchains")
    if not toolchains then

        -- get ndk
        local ndk = config.get("ndk")
        if ndk then

            -- match all toolchains
            if arch and arch:startswith("arm64") then
                toolchains = os.match("%s/toolchains/aarch64-linux-android-**/prebuilt/*/bin/aarch64-linux-android-*", false, ndk)
            else
                toolchains = os.match("%s/toolchains/arm-linux-androideabi-**/prebuilt/*/bin/arm-linux-androideabi-*", false, ndk)
            end

            -- save the toolchains directory
            for _, filepath in ipairs(toolchains) do
                config.set("toolchains", path.directory(filepath))
                break
            end
        end
    end

    -- get toolchains version
    local toolchains = config.get("toolchains")
    if toolchains then
        local pos, _, toolchains_ver = toolchains:find("%-(%d*%.%d*)[/\\]")
        if pos and toolchains_ver then

            -- save the toolchains version
            config.set("toolchains_ver", toolchains_ver)
 
            -- trace
            cprint("checking for the version of toolchains ... ${green}%s", toolchains_ver)
        else
            -- trace
            cprint("checking for the version of toolchains ... ${red}no")
        end
    end

    -- get cross
    local cross = "arm-linux-androideabi-"
    if arch and arch:startswith("arm64") then
        cross = "aarch64-linux-android-"
    end

    -- check it for c/c++
    checker.check_toolchain(config, "cc",   cross, "gcc",  "the c compiler") 
    checker.check_toolchain(config, "cxx",  cross, "g++",  "the c++ compiler") 
    checker.check_toolchain(config, "as",   cross, "gcc",  "the assember")
    checker.check_toolchain(config, "ld",   cross, "g++",  "the linker") 
    checker.check_toolchain(config, "ld",   cross, "gcc",  "the linker") 
    checker.check_toolchain(config, "ar",   cross, "ar",   "the static library archiver") 
    checker.check_toolchain(config, "ex",   cross, "ar",   "the static library extractor") 
    checker.check_toolchain(config, "sh",   cross, "g++",  "the shared library linker") 
    checker.check_toolchain(config, "sh",   cross, "gcc",  "the shared library linker") 
end

-- check it
function main(kind)

    -- init the check list of config
    _g.config = 
    {
        { checker.check_arch, "armv7-a" }
    ,   checker.check_ccache
    ,   _check_ndk_sdkver
    ,   _check_toolchains
    }

    -- init the check list of global
    _g.global = 
    {
        checker.check_ccache
    ,   _check_ndk_sdkver
    }

    -- check it
    checker.check(kind, _g)
end


