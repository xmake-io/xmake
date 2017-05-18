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

-- check toolchains directory
function _check_toolchains_dir(config)

    -- get toolchains directory
    local toolchains_dir = config.get("toolchains")
    if not toolchains_dir then

        -- get architecture
        local arch = config.get("arch")

        -- get ndk
        local ndk = config.get("ndk")
        if ndk then

            -- match all toolchains
            if arch and arch:startswith("arm64") then
                toolchains_dir = os.match("%s/toolchains/aarch64-linux-android-**/prebuilt/*/bin/aarch64-linux-android-*", false, ndk)
            else
                toolchains_dir = os.match("%s/toolchains/arm-linux-androideabi-**/prebuilt/*/bin/arm-linux-androideabi-*", false, ndk)
            end

            -- save the toolchains directory
            for _, filepath in ipairs(toolchains_dir) do
                config.set("toolchains", path.directory(filepath))
                break
            end
        end
    end
end

-- check toolchains version
function _check_toolchains_ver(config)

    -- get toolchains version
    local toolchains_ver = config.get("toolchains_ver")
    if not toolchains_ver then

        -- get toolchains directory
        local toolchains_dir = config.get("toolchains")
        if toolchains_dir then
            local pos, _, toolchains_ver = toolchains_dir:find("%-(%d*%.%d*)[/\\]")
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
    local cross = "arm-linux-androideabi-"
    if arch and arch:startswith("arm64") then
        cross = "aarch64-linux-android-"
    end

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

    -- insert archiver and unarchiver tools to toolchains
    checker.toolchain_insert(toolchains, "tar",         "",   "tar",         "the common file [un]archiverr") 
    checker.toolchain_insert(toolchains, "gzip",        "",   "gzip",        "the gzip file [un]archiver") 
    checker.toolchain_insert(toolchains, "7z",          "",   "7z",          "the 7z file [un]archiver") 
    checker.toolchain_insert(toolchains, "zip",         "",   "zip",         "the zip file archiver") 
    checker.toolchain_insert(toolchains, "unzip",       "",   "unzip",       "the zip file unarchiver") 

    -- insert other tools to toolchains
    checker.toolchain_insert(toolchains, "ccache",      "",   "ccache",      "the compiler cache") 
    checker.toolchain_insert(toolchains, "ping",        "",   "ping",        "the ping utility") 

    -- save toolchains
    _g.TOOLCHAINS = toolchains

    -- ok
    return toolchains
end

-- check it
function main(kind, toolkind)

    -- only check the given tool?
    if toolkind then
        return checker.toolchain_check(import("core.project." .. kind), toolkind, _toolchains)
    end

    -- init the check list of config
    _g.config = 
    {
        { checker.check_arch, "armv7-a" }
    ,   _check_ndk_sdkver
    ,   _check_toolchains_dir
    ,   _check_toolchains_ver
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


