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
-- @file        platform.lua
--

-- define module: platform
local platform = platform or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local config    = require("base/config")

-- init platform
function platform.init()

    -- init platform configs
    platform._CONFIGS = platform._CONFIGS or {}
    local configs = platform._CONFIGS

    -- load platform
    local p = require("platform/" .. config.get("plat") .. "/_" .. config.get("plat"))
    if not p then
        return false
    end

    -- init platform
    return p.init(configs)
end

-- get the given configure
function platform.get(name)

    -- check
    assert(platform._CONFIGS)

    -- get it
    return platform._CONFIGS[name]
end

-- get the format from the given kind
function platform.format(kind)

    -- get format
    local format = platform.get("formats")

    -- get it
    return format[kind] or {"", ""}
end

-- dump the platform configure
function platform.dump()
    
    -- check
    assert(platform._CONFIGS)

    -- dump
    if xmake._OPTIONS.verbose then
        utils.dump(platform._CONFIGS)
    end
   
end

-- list all platforms
function platform.plats()
    
    -- return it directly if exists
    if platform._PLATS then
        return platform._PLATS 
    end

    -- get the platform list
    local plats = os.match(xmake._SCRIPTS_DIR .. "/platform/*", true)
    if plats then
        for i, v in ipairs(plats) do
            plats[i] = path.basename(v)
        end
    end

    -- save it
    platform._PLATS = plats

    -- ok
    return plats
end

-- list all architectures
function platform.archs(plat)

    -- check
    assert(plat)
 
    -- load all platform configs
    local archs = {}
    local configs = {}
    local p = require("platform/" .. plat .. "/_" .. plat)
    if p and p.init(configs) and configs.archs then
       for arch, _ in pairs(configs.archs) do
        archs[table.getn(archs) + 1] = arch
       end
    end

    -- ok
    return archs
end
    
-- return module: platform
return platform
