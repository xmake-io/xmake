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

-- check the architecture
function check_arch(config)

    -- get the architecture
    local arch = config.get("arch")
    if not arch then

        -- the default architecture
        local archs =
        {
            macosx          = os.arch()
        ,   linux           = os.arch()
        ,   windows         = os.arch()
        ,   iphoneos        = "armv7"
        ,   iphonesimulator = os.arch()
        ,   watchos         = "armv7"
        ,   watchsimulator  = os.arch()
        ,   android         = "armv7-a"
        }

        -- init the default architecture
        config.set("arch", archs[config.get("plat")])

        -- trace
        print("checking for the architecture ... %s", config.get("arch"))
    end
end

-- check the xcode application directory
function check_xcode(config)

    -- get the xcode directory
    local xcode_dir = config.get("xcode_dir")
    if not xcode_dir then

        -- attempt to get the default directory 
        if not xcode_dir then
            if os.isdir("/Applications/Xcode.app") then
                xcode_dir = "/Applications/Xcode.app"
            end
        end

        -- attempt to match the other directories
        if not xcode_dir then
            local dirs = os.match("/Applications/Xcode*.app", true)
            if dirs and #dirs ~= 0 then
                xcode_dir = dirs[1]
            end
        end

        -- check ok? update it
        if xcode_dir then

            -- save it
            config.set("xcode_dir", xcode_dir)

            -- trace
            print("checking for the Xcode application directory ... %s", xcode_dir)
        else
            -- failed
            print("checking for the Xcode application directory ... no")
            print("please run:")
            print("    - xmake config --xcode_dir=xxx")
            print("or  - xmake global --xcode_dir=xxx")
            raise()
        end
    end
end

-- check the xcode sdk version
function check_xcode_sdkver(config)

    -- get plat
    local plat = config.get("plat")

    -- the xcode sdk directories
    local xcode_sdkdirs =
    {
        macosx          = "/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX*.sdk"
    ,   iphoneos        = "/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS*.sdk"
    ,   iphonesimulator = "/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator*.sdk"
    ,   watchos         = "/Contents/Developer/Platforms/WatchOS.platform/Developer/SDKs/WatchOS*.sdk"
    ,   watchsimulator  = "/Contents/Developer/Platforms/WatchSimulator.platform/Developer/SDKs/WatchSimulator*.sdk"
    }

    -- get the xcode sdk version
    local xcode_sdkver = config.get("xcode_sdkver")
    if not xcode_sdkver then

        -- attempt to match the directory
        if not xcode_sdkver then
            local dirs = os.match(config.get("xcode_dir") .. xcode_sdkdirs[plat], true)
            for _, dir in ipairs(dirs) do
                xcode_sdkver = string.match(dir, "%d+%.%d+")
                if xcode_sdkver then break end
            end
        end

        -- check ok? update it
        if xcode_sdkver then
            
            -- save it
            config.set("xcode_sdkver", xcode_sdkver)

            -- trace
            print("checking for the Xcode SDK version for %s ... %s", plat, xcode_sdkver)
        else
            -- failed
            print("checking for the Xcode SDK version for %s ... no", plat)
            print("please run:")
            print("    - xmake config --xcode_sdkver=xxx")
            print("or  - xmake global --xcode_sdkver=xxx")
            raise()
        end
    end
end

-- check the target minimal version
function check_target_minver(config)

    -- get the target minimal version
    local target_minver = config.get("target_minver")
    if not target_minver then

        -- TODO
        -- the default versions
        local versions =
        {
            macosx          = "10.9"
        ,   iphoneos        = "7.0"
        ,   iphonesimulator = "7.0"
        ,   watchos         = "7.0"
        ,   watchsimulator  = "7.0"
        }

        -- init the default target minimal version
        config.set("target_minver", versions[config.get("plat")])

        -- trace
        print("checking for the target minimal version ... %s", config.get("target_minver"))

    end
end

-- check the make
function check_make(config)

    -- get the make
    local make = config.get("make")
    if not make then 

        -- check the make path
        make = tool.check("make", {"/usr/bin", "/usr/local/bin", "/opt/bin", "/opt/local/bin"})

        -- check ok? update it
        if make then config.set("make", make) end

        -- trace
        print("checking for the make ... %s", ifelse(make, make, "no"))

    end
end

-- check the ccache
function check_ccache(config)

    -- ok? 
    local ccache = config.get("ccache")
    if ccache ~= nil then

        -- check the ccache path
        local ccache_path = tool.check("ccache", {"/usr/bin", "/usr/local/bin", "/opt/bin", "/opt/local/bin"})

        -- check ok? update it
        if ccache_path then
            config.set("ccache", true)
            config.set("__ccache", ccache_path)
        else
            config.set("ccache", false)
        end

        -- trace
        print("checking for the ccache ... %s", ifelse(ccache_path, ccache_path, "no"))

    end
end

-- check the toolchain
function check_toolchain(config, kind, cross, name, description, check)

    -- get the tool path
    local toolpath = config.get(kind)
    if not toolpath then

        -- get the cross
        cross = config.get("cross") or cross

        -- check it using the custom script
        if not toolpath and check then

            -- check it
            try
            {
                function ()

                    -- check it
                    check(cross .. name)

                    -- ok
                    toolpath = cross .. name
                end
            }
        end

        -- attempt to get it from the given cross toolchains
        local toolchains = config.get("toolchains") 
        if not toolpath and toolchains then
            toolpath = tool.check(cross .. name, toolchains)
        end

        -- attempt to run it directly
        if not toolpath then
            toolpath = tool.check(cross .. name)
        end

        -- check ok?
        if toolpath then 

            -- update config
            config.set(kind, toolpath) 

        end

        -- trace
        if toolpath then
            print("checking for %s (%s) ... %s", description, kind, path.filename(toolpath))
        else
            print("checking for %s (%s) ... no", description, kind)
        end
    end
end
