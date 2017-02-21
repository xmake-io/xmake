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
-- @file        checker.lua
--

-- imports
import("core.tool.tool")

-- check all for the given config kind
function check(kind, checkers)

    -- import config module
    local config = import("core.project." .. kind)

    -- check all
    for _, checker in ipairs(checkers[kind]) do

        -- has arguments?
        local args = nil
        if type(checker) == "table" then
            if #checker > 1 then
                args = checker[2]
            end
            checker = checker[1]
        end

        -- check it
        checker(config, args)
    end
end

-- check the architecture
function check_arch(config, default)

    -- get the architecture
    local arch = config.get("arch")
    if not arch then

        -- init the default architecture
        config.set("arch", default or os.arch())

        -- trace
        cprint("checking for the architecture ... ${green}%s", config.get("arch"))
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
            cprint("checking for the Xcode application directory ... ${green}%s", xcode_dir)
        else
            -- failed
            cprint("checking for the Xcode application directory ... ${red}no")
            cprint("${bright red}please run:")
            cprint("${red}    - xmake config --xcode_dir=xxx")
            cprint("${red}or  - xmake global --xcode_dir=xxx")
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
            cprint("checking for the Xcode SDK version for %s ... ${green}%s", plat, xcode_sdkver)
        else
            -- failed
            cprint("checking for the Xcode SDK version for %s ... ${red}no", plat)
            cprint("${bright red}please run:")
            cprint("${red}    - xmake config --xcode_sdkver=xxx")
            cprint("${red}or  - xmake global --xcode_sdkver=xxx")
            raise()
        end
    end
end

-- check the target minimal version
function check_target_minver(config)

    -- get the target minimal version
    local target_minver = config.get("target_minver")
    if not target_minver then

        -- the default versions
        local versions =
        {
            macosx          = "10.9"
        ,   iphoneos        = "7.0"
        ,   iphonesimulator = "7.0"
        ,   watchos         = "2.1"
        ,   watchsimulator  = "2.1"
        }

        -- init the default target minimal version
        config.set("target_minver", config.get("xcode_sdkver") or versions[config.get("plat")])

        -- trace
        cprint("checking for the target minimal version ... ${green}%s", config.get("target_minver"))
    end
end

-- check the ccache
function check_ccache(config)

    -- get the ccache
    local ccache = config.get("ccache")
    if ccache == nil or (type(ccache) == "boolean" and ccache) then

        -- check the ccache path
        local ccache_path = tool.check("ccache")

        -- check ok? update it
        if ccache_path then
            config.set("ccache", ccache_path)
        else
            config.set("ccache", false)
        end

        -- trace
        if ccache_path then
            cprint("checking for the ccache ... ${green}%s", ccache_path)
        else
            cprint("checking for the ccache ... ${red}no")
        end
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

        -- get toolchains
        local toolchains = config.get("toolchains")
        if not toolchains then
            local sdkdir = config.get("sdk")
            if sdkdir then
                toolchains = path.join(sdkdir, "bin")
            end
        end

        -- attempt to get it from the given cross toolchains
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
            cprint("checking for %s (%s) ... ${green}%s", description, kind, path.filename(toolpath))
        else
            cprint("checking for %s (%s: ${red}%s${clear}) ... ${red}no", description, kind, name)
        end
    end
end

-- check the toolchain from env
function check_toolchain_from_env(config, kind, envname, description, check)

    -- get shell name from the env
    local shellname = os.getenv(envname)
    if shellname and shellname:trim() ~= "" then
        check_toolchain(config, kind, "", shellname, description, check) 
    end
end

