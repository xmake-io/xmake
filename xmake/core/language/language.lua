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
-- @file        language.lua
--

-- define module
local language      = language or {}
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

-- the directories of platform
function language._directories()

    -- the directories
    return  {   path.join(config.directory(), "languages")
            ,   path.join(global.directory(), "languages")
            ,   path.join(xmake._PROGRAM_DIR, "languages")
            }
end

-- the interpreter
function language._interpreter()

    -- the interpreter has been initialized? return it directly
    if language._INTERPRETER then
        return language._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)
 
    -- register api: language()
    interp:api_register_scope("language")

    -- register api: on_load()
    interp:api_register_on_script("language", "load")

    -- save interpreter
    language._INTERPRETER = interp

    -- ok?
    return interp
end

-- load the given platform 
function language.load(plat)

    -- get platform name
    plat = plat or config.get("plat") or xmake._HOST
    if not plat then
        return nil, string.format("unknown platform!")
    end

    -- get it directly from cache dirst
    language._PLATFORMS = language._PLATFORMS or {}
    if language._PLATFORMS[plat] then
        return language._PLATFORMS[plat]
    end

    -- find the platform script path
    local scriptpath = nil
    for _, dir in ipairs(language._directories()) do

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
    local results, errors = language._interpreter():load(scriptpath, "platform", true, false)
    if not results and os.isfile(scriptpath) then
        return nil, errors
    end

    -- check the platform name
    if not results[plat] then
        return nil, string.format("the platform %s not found!", plat)
    end

    -- new an instance
    local instance, errors = _instance.new(plat, results[plat], language._interpreter():rootdir())
    if not instance then
        return nil, errors
    end

    -- save instance to the cache
    language._PLATFORMS[plat] = instance

    -- ok
    return instance

end

-- get the given platform configure
function language.get(name)

    -- get the current platform configure
    local instance = language.load()
    if instance then
        return instance:get(name)
    end
end

-- return module
return language
