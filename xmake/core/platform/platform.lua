--!The Make-like Build Utility based on Lua
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
-- @file        platform.lua
--

-- define module
local platform      = platform or {}
local _instance     = _instance or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local table         = require("base/table")
local interpreter   = require("base/interpreter")
local sandbox       = require("sandbox/sandbox")
local config        = require("project/config")
local global        = require("project/global")

-- load the platform module
function _instance:_load(modulename)

    -- return it directly if cached
    local cachename = "_" .. modulename:upper()
    if self[cachename] then
        return self[cachename]
    end

    -- no this module?
    if not self._INFO[modulename] then
        return nil
    end

    -- get the script path
    local scriptpath = path.join(self._ROOTDIR, self._INFO[modulename] .. ".lua")
    
    -- not exists?
    if not scriptpath or not os.isfile(scriptpath) then
        return nil, string.format("the %s of %s not found!", modulename, self._NAME)
    end

    -- load script
    local script, errors = loadfile(scriptpath)
    if script then

        -- make sandbox instance with the given script
        local instance, errors = sandbox.new(script, nil, self._ROOTDIR)
        if not instance then
            return nil, errors
        end

        -- import the module
        local module, errors = instance:import()
        if not module then
            return nil, errors
        end

        -- init the module
        if module.init then
            module.init()
        end
    
        -- save it to the cache
        self[cachename] = module

        -- ok?
        return module
    end

    -- failed
    return nil, errors
end

-- new an instance
function _instance.new(name, info, rootdir)

    -- new an instance
    local instance = table.inherit(_instance)

    -- init instance
    instance._NAME      = name
    instance._INFO      = info
    instance._ROOTDIR   = rootdir

    -- ok
    return instance
end

-- get the platform configure
function _instance:get(name)

    -- the info
    local info = self._INFO

    -- load it first
    if self._g == nil and info.load ~= nil then

        -- load it
        local ok, errors = sandbox.load(info.load)
        if not ok then
            os.raise(errors)
        end

        -- save _g
        self._g = getfenv(info.load)._g
    end

    -- get it
    if self._g ~= nil then
        return self._g[name]
    end
end

-- get the platform os
function _instance:os()

    -- get it
    return self._INFO.os
end

-- get the platform menu
function _instance:menu()

    -- get it
    return self._INFO.menu
end

-- get the platform hosts
function _instance:hosts()

    -- get it
    return self._INFO.hosts
end

-- get the platform archs
function _instance:archs()

    -- get it
    return self._INFO.archs
end

-- get the platform tooldirs
function _instance:tooldirs()

    -- get it
    return self._INFO.tooldirs
end

-- get the checker
function _instance:checker()

    -- load checker
    return self:_load("checker")
end

-- get the installer
function _instance:installer()

    -- load installer
    return self:_load("installer")
end

-- get the environment
function _instance:environment()

    -- load environment
    return self:_load("environment")
end

-- the directories of platform
function platform._directories()

    -- the directories
    return  {   path.join(config.directory(), "platforms")
            ,   path.join(global.directory(), "platforms")
            ,   path.join(xmake._PROGRAM_DIR, "platforms")
            }
end

-- the interpreter
function platform._interpreter()

    -- the interpreter has been initialized? return it directly
    if platform._INTERPRETER then
        return platform._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)
 
    -- register api: platform()
    interp:api_register_scope("platform")

    -- register api: set_os()
    interp:api_register_set_values("platform", "os")

    -- register api: set_hosts() 
    interp:api_register_set_values("platform", "hosts")

    -- register api: set_archs() 
    interp:api_register_set_values("platform", "archs")

    -- register api: set_menu() 
    interp:api_register_set_values("platform", "menu")

    -- register api: set_checker()
    interp:api_register_set_values("platform", "checker")

    -- register api: set_tooldirs()
    interp:api_register_set_values("platform", "tooldirs")

    -- register api: set_environment()
    interp:api_register_set_values("platform", "environment")

    -- register api: set_installer()
    interp:api_register_set_values("platform", "installer")

    -- register api: on_load()
    interp:api_register_on_script("platform", "load")

    -- save interpreter
    platform._INTERPRETER = interp

    -- ok?
    return interp
end

-- load the given platform 
function platform.load(plat)

    -- get platform name
    plat = plat or config.get("plat") or xmake._HOST
    if not plat then
        return nil, string.format("unknown platform!")
    end

    -- get it directly from cache dirst
    platform._PLATFORMS = platform._PLATFORMS or {}
    if platform._PLATFORMS[plat] then
        return platform._PLATFORMS[plat]
    end

    -- find the platform script path
    local scriptpath = nil
    for _, dir in ipairs(platform._directories()) do

        -- find this directory
        scriptpath = path.join(path.join(dir, plat), "xmake.lua")
        if os.isfile(scriptpath) then
            break
        end
    end

    -- not exists?
    if not scriptpath or not os.isfile(scriptpath) then
        return nil, string.format("the platform %s not found!", plat)
    end

    -- load platform
    local results, errors = platform._interpreter():load(scriptpath, "platform", true, false)
    if not results and os.isfile(scriptpath) then
        return nil, errors
    end

    -- check the platform name
    if not results[plat] then
        return nil, string.format("the platform %s not found!", plat)
    end

    -- new an instance
    local instance, errors = _instance.new(plat, results[plat], platform._interpreter():rootdir())
    if not instance then
        return nil, errors
    end

    -- save instance to the cache
    platform._PLATFORMS[plat] = instance

    -- ok
    return instance

end

-- get the platform os
function platform.os(plat)

    -- load the platform 
    local instance = platform.load(plat)
    if instance then
        return instance:os()
    end
end

-- get the given platform configure
function platform.get(name)

    -- get the current platform configure
    local instance = platform.load()
    if instance then
        return instance:get(name)
    end
end

-- get the platform tool from the kind
--
-- .e.g cc, cxx, mm, mxx, as, ar, ld, sh, ..
--
function platform.tool(kind)

    -- get it
    return config.get(kind)
end

-- get the platform archs
function platform.archs(plat)

    -- load the platform 
    local instance = platform.load(plat)
    if instance then
        return instance:archs()
    end
end

-- get the all platforms
function platform.plats()
    
    -- return it directly if exists
    if platform._PLATS then
        return platform._PLATS 
    end

    -- get all platforms
    local plats = {}
    local dirs  = platform._directories()
    for _, dir in ipairs(dirs) do

        -- get the platform list 
        local platpathes = os.match(path.join(dir, "*"), true)
        if platpathes then
            for _, platpath in ipairs(platpathes) do
                if os.isfile(path.join(platpath, "xmake.lua")) then
                    table.insert(plats, path.basename(platpath))
                end
            end
        end
    end

    -- save them
    platform._PLATS = plats

    -- ok
    return plats
end

-- get the tool directories
function platform.tooldirs(plat)

    -- get the tool directories for the current platform
    local instance = platform.load(plat)
    if instance then
        return instance:tooldirs()
    end
end

-- get the given format
function platform.format(kind)

    -- get formats
    local formats = platform.get("formats")
    if formats then
        return formats[kind]
    end
end


-- return module
return platform
