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
local global    = require("base/global")

-- load platform directories
function platform._load_directories()

    -- load platform directories
    return  {   path.join(config.directory(), "platforms")
            ,   path.join(global.directory(), "platforms")
            ,   path.join(xmake._PROGRAM_DIR, "platforms")
            }
end

-- load prober the given platform directory
function platform._load_prober(platdir)

    -- the platform file path
    local filepath = path.join(platdir, "prober.lua")
    if os.isfile(filepath) then

        -- load script
        local script = loadfile(filepath)
        if script then

            -- load prober
            local prober = script()
            if prober then

                -- ok
                return prober
            end
        end
    end
end

-- load the given platform from the given directory
function platform._load_from(dir, plat)

    -- the platform file path
    local filepath = path.join(dir, plat, plat .. ".lua")
    if os.isfile(filepath) then

        -- load script
        local script = loadfile(filepath)
        if script then

            -- load module
            local module = script()
            if module then

                -- save directory
                module._DIRECTORY = path.directory(filepath)
                assert(module._DIRECTORY)

                -- attempt to load prober
                module._PROBER = platform._load_prober(module._DIRECTORY)

                -- ok
                return module
            end
        end
    end
end

-- load the given platform 
function platform._load(plat)

    -- check
    assert(plat)

    -- the module
    platform._MODULES = platform._MODULES or {}
    local module = platform._MODULES[plat]

    -- return it directory if ok
    if module then return module end

    -- load module
    local dirs = platform._load_directories()
    for _, dir in ipairs(dirs) do

        module = platform._load_from(dir, plat) 
        if module then
            break
        end

    end

    -- cache it if ok
    if module then
        platform._MODULES[plat] = module
    end

    -- ok?
    return module
end

-- get the configure of the given platform
function platform._configs(plat)

    -- check
    assert(plat)

    -- the configure
    platform._CONFIGS = platform._CONFIGS or {}
    local configs = platform._CONFIGS[plat]

    -- return it directly if exists
    if configs then
        return configs
    end

    -- load platform
    local module = platform._load(plat)
    if module then
          
        -- init configure
        platform._CONFIGS[plat]= {}
        configs = platform._CONFIGS[plat]

        -- make configure
        module.make(configs)
    end

    -- ok?
    return configs
end

-- get the current platform module
function platform.module()

    -- get the platform
    local plat = config.get("plat")
    if plat then
        -- load it
        return platform._load(plat)
    end
end

-- get the current platform module directory
function platform.directory()

    -- load it
    local module = platform.module()
    if module then
        return module._DIRECTORY
    end
end

-- make the current platform configure
function platform.make()

    -- get the platform
    local plat = config.get("plat")
    assert(plat)

    -- make and get the current platform configure
    return platform._configs(plat)
end

-- get the platform os
function platform.os()

    -- get module
    local module = platform.module()
    if not module then return end

    -- ok?
    return module._OS
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

-- get the given tool
function platform.tool(name)

    -- check
    assert(name)

    -- get tools
    local tools = platform.get("tools")
    if tools then
        return tools[name]
    end

end

-- get the given format
function platform.format(kind)

    -- check
    assert(kind)

    -- get formats
    local formats = platform.get("formats")
    if formats then
        return formats[kind]
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

    -- make list
    local list = {}
    local dirs = platform._load_directories()
    for _, dir in ipairs(dirs) do

        -- get the platform list 
        local plats = os.match(path.join(dir, "*"), true)
        if plats then
            for _, v in ipairs(plats) do
                table.insert(list, path.basename(v))
            end
        end

    end

    -- save it
    platform._PLATS = list

    -- ok
    return list
end

-- list all architectures
function platform.archs(plat)

    -- check
    assert(plat)
 
    -- load all platform configs
    local archs = {}
    local module = platform._load(plat)
    if module and module._ARCHS then
       for _, arch in ipairs(module._ARCHS) do
            table.insert(archs, arch)
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
        local module = platform._load(plat)
        if module and module.menu then

            -- get the platform menu
            local menu = module.menu(action)
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
                                table.insert(menus, option)
                                exist[name] = true
                            end
                        else
                            table.insert(menus, option)
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
function platform.probe(is_global)

    -- probe global
    if is_global then

        -- get all platforms
        local plats = platform.plats()
        assert(plats)

        -- probe all platforms with the current host
        for _, plat in ipairs(plats) do
            local module = platform._load(plat)
            if module and module._PROBER and module._PROBER.global and module._HOST and module._HOST == xmake._HOST then
                if not module._PROBER.global() then return false end
            end
        end

    -- probe config
    else
        -- probe it
        local module = platform.module()
        if module and module._PROBER and module._PROBER.config then
            if not module._PROBER.config() then return false end
        end
    end

    -- ok
    return true
end

-- return module: platform
return platform
