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
    configs.set("arch", "i386")

    -- trace
    utils.printf("checking for the architecture ... %s", configs.get("arch"))

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

    -- init the default cross from the current host and architecture
    local cross = ""
    local arch = configs.get("arch")
    if arch then
        if xmake._HOST == "macosx" and arch == "i386" then
            cross = "i386-mingw32-"
        elseif arch == "i386" then
            cross = "i686-w64-mingw32-"
        elseif arch == "x86_64" then
            cross = "x86_64-w64-mingw32-"
        end
    end

    -- done
    if not prober._probe_toolpath(configs, "cc", cross, "gcc", "the c compiler") then return false end
    if not prober._probe_toolpath(configs, "cxx", cross, {"g++", "gcc"}, "the c++ compiler") then return false end
    if not prober._probe_toolpath(configs, "as", cross, "gcc", "the assember") then return false end
    if not prober._probe_toolpath(configs, "ld", cross, {"g++", "gcc"}, "the linker") then return false end
    if not prober._probe_toolpath(configs, "ar", cross, "ar", "the static library linker") then return false end
    if not prober._probe_toolpath(configs, "sh", cross, {"g++", "gcc"}, "the shared library linker") then return false end
    if not prober._probe_toolpath(configs, "sc", cross, "swiftc", "the swift compiler") then return false end
    return true
end

-- probe the project configure 
function prober.config()

    -- call all probe functions
    return utils.call(  {   prober._probe_arch
                        ,   prober._probe_make
                        ,   prober._probe_ccache
                        ,   prober._probe_toolchains}
                    ,   nil
                    ,   config)
end

-- probe the global configure 
function prober.global()

    -- call all probe functions
    return utils.call(     {   prober._probe_make
                    ,       prober._probe_ccache}
                    ,   nil
                    ,   global)
end

-- return module: prober
return prober
