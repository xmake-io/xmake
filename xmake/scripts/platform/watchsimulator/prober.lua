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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        prober.lua
--

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")
local tools     = require("tools/tools")
local config    = require("base/config")
local global    = require("base/global")

-- define module: prober
local prober = prober or {}

-- probe the architecture
function prober._probe_arch(configs)

    -- get the architecture
    local arch = configs.get("arch")

    -- ok? 
    if arch then return true end

    -- init the default architecture
    configs.set("arch", "x86_64")

    -- trace
    utils.printf("checking for the architecture ... %s", configs.get("arch"))

    -- ok
    return true
end

-- probe the xcode application directory
function prober._probe_xcode(configs)

    -- get the xcode directory
    local xcode_dir = configs.get("xcode_dir")

    -- ok? 
    if xcode_dir then return true end

    -- clear it first
    xcode_dir = nil

    -- attempt to get the default directory 
    if not xcode_dir then
        if os.isdir("/Applications/Xcode.app") then
            xcode_dir = "/Applications/Xcode.app"
        end
    end

    -- attempt to match the other directories
    if not xcode_dir then
        local dirs = os.match("/Applications/Xcode*.app", true)
        if dirs and table.getn(dirs) ~= 0 then
            xcode_dir = dirs[1]
        end
    end

    -- probe ok? update it
    if xcode_dir then
        -- save it
        configs.set("xcode_dir", xcode_dir)

        -- trace
        utils.printf("checking for the Xcode application directory ... %s", xcode_dir)
    else
        -- failed
        utils.error("checking for the Xcode application directory ... no")
        utils.error("    - xmake config --xcode_dir=xxx")
        utils.error("or  - xmake global --xcode_dir=xxx")
        return false
    end

    -- ok
    return true
end

-- probe the xcode sdk version
function prober._probe_xcode_sdkver(configs)

    -- get the xcode sdk version
    local xcode_sdkver = configs.get("xcode_sdkver")

    -- ok? 
    if xcode_sdkver then return true end

    -- clear it first
    xcode_sdkver = nil

    -- attempt to match the directory
    if not xcode_sdkver then
        local dirs = os.match(configs.get("xcode_dir") .. "/Contents/Developer/Platforms/WatchSimulator.platform/Developer/SDKs/WatchSimulator*.sdk", true)
        if dirs then
            for _, dir in ipairs(dirs) do
                xcode_sdkver = string.match(dir, "%d+%.%d+")
                if xcode_sdkver then break end
            end
        end
    end

    -- probe ok? update it
    if xcode_sdkver then
        
        -- save it
        configs.set("xcode_sdkver", xcode_sdkver)

        -- trace
        utils.printf("checking for the Xcode SDK version for %s ... %s", configs.get("plat"), xcode_sdkver)
    else
        -- failed
        utils.error("checking for the Xcode SDK version for %s ... no", configs.get("plat"))
        utils.error("    - xmake config --xcode_sdkver=xxx")
        utils.error("or  - xmake global --xcode_sdkver=xxx")
        return false
    end

    -- ok
    return true
end

-- probe the target minimal version
function prober._probe_target_minver(configs)

    -- get the target minimal version
    local target_minver = configs.get("target_minver")

    -- ok? 
    if target_minver then return true end

    -- init the default target minimal version
    configs.set("target_minver", "7.0")

    -- trace
    utils.printf("checking for the target minimal version ... %s", configs.get("target_minver"))

    -- ok
    return true
end

-- probe the make
function prober._probe_make(configs)

    -- ok? 
    local make = configs.get("make")
    if make then return true end

    -- probe the make path
    make = tools.probe("make", {"/usr/bin", "/usr/local/bin", "/opt/bin", "/opt/local/bin"})

    -- probe ok? update it
    if make then configs.set("make", make) end

    -- trace
    utils.printf("checking for the make ... %s", utils.ifelse(make, make, "no"))

    -- ok
    return true
end

-- probe the ccache
function prober._probe_ccache(configs)

    -- ok? 
    local ccache_enable = configs.get("ccache")
    if ccache_enable and configs.get("__ccache") then return true end

    -- disable?
    if type(ccache_enable) == "boolean" and not ccache_enable then
        configs.set("__ccache", nil)
        return true
    end

    -- probe the ccache path
    local ccache_path = tools.probe("ccache", {"/usr/bin", "/usr/local/bin", "/opt/bin", "/opt/local/bin"})

    -- probe ok? update it
    if ccache_path then
        configs.set("ccache", true)
        configs.set("__ccache", ccache_path)
    else
        configs.set("ccache", false)
    end

    -- trace
    utils.printf("checking for the ccache ... %s", utils.ifelse(ccache_path, ccache_path, "no"))

    -- ok
    return true
end

-- probe the tool path
function prober._probe_toolpath(configs, kind, cross, names, description)

    -- check
    assert(kind)

    -- get the cross
    cross = configs.get("cross") or cross

    -- done
    local toolpath = nil
    local toolchains = configs.get("toolchains") 
    for _, name in ipairs(utils.wrap(names)) do

        -- attempt to get it from the given cross toolchains
        if toolchains then
            toolpath = tools.probe(cross .. (configs.get(kind) or name), toolchains)
        end

        -- attempt to get it directly from the configure
        if not toolpath then
            toolpath = configs.get(kind)
        end

        -- attempt to run it directly
        if not toolpath then
            toolpath = tools.probe(cross .. name)
        end

        -- probe ok?
        if toolpath then 

            -- update config
            configs.set(kind, toolpath) 

            -- end
            break
        end

    end

    -- trace
    if toolpath then
        utils.printf("checking for %s (%s) ... %s", description, kind, path.filename(toolpath))
    else
        utils.printf("checking for %s (%s) ... no", description, kind)
    end

    -- ok
    return true
end

-- probe the toolchains
function prober._probe_toolchains(configs)

    -- done
    if not prober._probe_toolpath(configs, "cc", "xcrun -sdk watchsimulator ", "clang", "the c compiler") then return false end
    if not prober._probe_toolpath(configs, "cxx", "xcrun -sdk watchsimulator ", {"clang++", "clang"}, "the c++ compiler") then return false end
    if not prober._probe_toolpath(configs, "mm", "xcrun -sdk watchsimulator ", "clang", "the objc compiler") then return false end
    if not prober._probe_toolpath(configs, "mxx", "xcrun -sdk watchsimulator ", {"clang++", "clang"}, "the objc++ compiler") then return false end
    if not prober._probe_toolpath(configs, "as", "xcrun -sdk watchsimulator ", "clang", "the assember") then return false end
    if not prober._probe_toolpath(configs, "ld", "xcrun -sdk watchsimulator ", {"clang++", "clang"}, "the linker") then return false end
    if not prober._probe_toolpath(configs, "ar", "xcrun -sdk watchsimulator ", "ar", "the static library linker") then return false end
    if not prober._probe_toolpath(configs, "sh", "xcrun -sdk watchsimulator ", {"clang++", "clang"}, "the shared library linker") then return false end
    if not prober._probe_toolpath(configs, "sc", "xcrun -sdk watchsimulator ", "swiftc", "the swift compiler") then return false end
    return true
end

-- probe the project configure 
function prober.config()

    -- call all probe functions
    return utils.call(  {   prober._probe_arch
                        ,   prober._probe_xcode
                        ,   prober._probe_xcode_sdkver
                        ,   prober._probe_target_minver
                        ,   prober._probe_make
                        ,   prober._probe_ccache
                        ,   prober._probe_toolchains}
                    ,   nil
                    ,   config)
end

-- probe the global configure 
function prober.global()

    -- call all probe functions
    return utils.call(  {   prober._probe_xcode
                        ,   prober._probe_make
                        ,   prober._probe_ccache}
                    ,   nil
                    ,   global)
end

-- return module: prober
return prober
