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

-- get the configure of the given platform
function platform._config(plat)

    -- the configure
    platform._CONFIGS = platform._CONFIGS or {}
    local config = platform._CONFIGS[plat]

    -- return it directly if exists
    if config then
        return config
    end

    -- load platform
    local p = require("platform/" .. plat .. "/_" .. plat)
    if p then
          
        -- make configure
        platform._CONFIGS[plat]= {}
        config = platform._CONFIGS[plat]

        -- init configure
        p.init(config)
    end

    -- ok?
    return config
end

-- init platform
function platform.init()

    -- init the current platform
    return platform._config(config.get("plat"))
end

-- get the given configure
function platform.get(name)

    -- check
    assert(platform._CONFIGS)

    -- get the current platform configure
    local config = platform._config(config.get("plat"))
    if config then
        -- get it
        return config[name]
    end
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
        utils.dump(platform._config(config.get("plat")))
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
    local config = platform._config(plat)
    if config and config.archs then
       for arch, _ in pairs(config.archs) do
        archs[table.getn(archs) + 1] = arch
       end
    end

    -- ok
    return archs
end
    
-- return module: platform
return platform
