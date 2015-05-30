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
local compiler  = require("compiler/compiler")

-- load the given platform 
function platform._load(plat)
 
    -- load it
    return require("platform/" .. plat .. "/_" .. plat)
end

-- get the configure of the given platform
function platform._configs(plat)

    -- the configure
    platform._CONFIGS = platform._CONFIGS or {}
    local configs = platform._CONFIGS[plat]

    -- return it directly if exists
    if configs then
        return configs
    end

    -- load platform
    local p = platform._load(plat)
    if p then
          
        -- init configure
        platform._CONFIGS[plat]= {}
        configs = platform._CONFIGS[plat]

        -- make configure
        p.make(configs)
    end

    -- ok?
    return configs
end

-- make the current platform configure
function platform.make()

    -- make and get the current platform configure
    return platform._configs(config.get("plat"))
end

-- get the given configure
function platform.get(name)

    -- check
    assert(platform._CONFIGS)

    -- get the current platform configure
    local configs = platform._configs(config.get("plat"))
    if configs then
        -- get it
        return configs[name]
    end
end

-- get the format from the given kind
function platform.format(kind)

    -- check
    assert(kind)

    -- get format
    local format = platform.get("format")
    assert(format)

    -- get it
    return format[kind] or {"", ""}
end

-- get the compiler from the given name
function platform.compiler(name)

    -- check
    assert(name)

    -- get compiler
    local c = platform.get("compiler")
    assert(c)

    -- load compiler
    c = c[name]
    if c then 
        return compiler.load(c)
    end
end

-- dump the platform configure
function platform.dump()
    
    -- check
    assert(platform._CONFIGS)

    -- dump
    if xmake._OPTIONS.verbose then
        utils.dump(platform._configs(config.get("plat")))
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
    local p = platform._load(plat)
    if p and p._ARCHS then
       for _, arch in ipairs(p._ARCHS) do
            archs[table.getn(archs) + 1] = arch
       end
    end

    -- ok
    return archs
end

-- get the option menu for action: xmake config or global
function platform.menu(action)
    
    -- check
    assert(action)

    -- get all platforms
    local plats = platform.plats()
    assert(plats)

    -- load and merge all platform menus
    local menus = {}
    local exist = {}
    for _, plat in ipairs(plats) do

        -- load platform
        local p = platform._load(plat)
        if p and p.menu then

            -- get the platform menu
            local menu = p.menu(action)
            if menu then

                -- exists options?
                local exists = false
                for _, option in ipairs(menu) do
                    local name = option[2]
                    if name and not exist[name] then
                        exists = true
                        break
                    end
                end

                -- merge it and remove repeat if exists options
                if exists then
                    -- get the platform menu option
                    for _, option in ipairs(menu) do

                        -- merge it and remove repeat 
                        local name = option[2]
                        if name then
                            if not exist[name] then
                                menus[table.getn(menus) + 1] = option
                                exist[name] = true
                            end
                        else
                            menus[table.getn(menus) + 1] = option
                        end
                    end
                end
            end
        end
    end

    -- get all platform menus
    return menus
end

-- probe the platform configure 
function platform.probe(configs, is_global)

    -- probe global
    if is_global then

        -- get all platforms
        local plats = platform.plats()
        assert(plats)

        -- probe all platforms with the current host
        for _, plat in ipairs(plats) do
            local p = platform._load(plat)
            if p and p._PROBER and p._PROBER.done and p._HOST and p._HOST == xmake._HOST then
                p._PROBER.done(configs)
            end
        end

    -- probe config
    else
        -- probe it
        local p = platform._load(config.get("plat"))
        if p and p._PROBER and p._PROBER.done then
            p._PROBER.done(configs)
        end
    end
end
    
-- return module: platform
return platform
