--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        checker.lua
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
            print("checking for the SDK version of NDK ... android-%d", ndk_sdkver)
        else

            -- trace
            print("checking for the SDK version of NDK ... no")
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

    -- get cross
    local cross = "arm-linux-androideabi-"
    if arch and arch:startswith("arm64") then
        cross = "aarch64-linux-android-"
    end

    -- done
    checker.check_toolchain(config, "cc",   cross, "gcc",  "the c compiler") 
    checker.check_toolchain(config, "cxx",  cross, "g++",  "the c++ compiler") 
    checker.check_toolchain(config, "as",   cross, "gcc",  "the assember")
    checker.check_toolchain(config, "ld",   cross, "g++",  "the linker") 
    checker.check_toolchain(config, "ar",   cross, "ar",   "the static library archiver") 
    checker.check_toolchain(config, "ex",   cross, "ar",   "the static library extractor") 
    checker.check_toolchain(config, "sh",   cross, "g++",  "the shared library linker") 
end

-- init it
function init()

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

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

