--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
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
local global        = require("base/global")

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

-- get platform name
function _instance:name()
    return self._NAME
end

-- set the value to the platform info
function _instance:set(name, ...)
    self._INFO[name] = table.unwrap({...})
end

-- add the value to the platform info
function _instance:add(name, ...)
    local info = table.wrap(self._INFO[name])
    self._INFO[name] = table.unwrap(table.join(info, ...))
end

-- get the platform configure
function _instance:get(name)

    -- attempt to get the static configure value
    local value = self._INFO[name]
    if value ~= nil then
        return value
    end

    -- lazy loading platform
    if not self._LOADED then
        local on_load = self._INFO.load
        if on_load then
            local ok, errors = sandbox.load(on_load, self)
            if not ok then
                os.raise(errors)
            end
        end
        self._LOADED = true
    end

    -- get other platform info
    return self._INFO[name]
end

-- get the platform os
function _instance:os()
    return self:get("os")
end

-- get the platform menu
function _instance:menu()
    return self:get("menu")
end

-- get the platform hosts
function _instance:hosts()
    return self:get("hosts")
end

-- get the platform archs
function _instance:archs()
    return self:get("archs")
end

-- the directories of platform
function platform._directories()

    -- the directories
    return  {   path.join(config.directory(), "platforms")
            ,   path.join(global.directory(), "platforms")
            ,   path.join(os.programdir(), "platforms")
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
 
    -- define apis
    interp:api_define
    {
        values =
        {
            -- platform.set_xxx
            "platform.set_os"
        ,   "platform.set_hosts"
        ,   "platform.set_archs"
        ,   "platform.set_installdir"
        }
    ,   script =
        {
            -- platform.on_xxx
            "platform.on_load"
        ,   "platform.on_check"
        }
    ,   module =
        {
            -- platform.set_xxx
            "platform.set_environment"
        }
    ,   dictionary =
        {
            -- platform.set_xxx
            "platform.set_menu"
        ,   "platform.set_formats"
        }
    }

    -- save interpreter
    platform._INTERPRETER = interp

    -- ok?
    return interp
end

-- load the given platform 
function platform.load(plat)

    -- get platform name
    plat = plat or config.get("plat") or os.host()
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
        scriptpath = path.join(dir, plat, "xmake.lua")
        if os.isfile(scriptpath) then
            break
        end
    end

    -- unknown platform? switch to cross compilation platform
    local cross = false
    if not scriptpath or not os.isfile(scriptpath) then
        scriptpath = path.join(os.programdir(), "platforms", "cross", "xmake.lua")
        cross = true
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

    -- get result
    local result = utils.ifelse(cross, results["cross"], results[plat])

    -- check the platform name
    if not result then
        return nil, string.format("the platform %s not found!", plat)
    end

    -- new an instance
    local instance, errors = _instance.new(plat, result, platform._interpreter():rootdir())
    if not instance then
        return nil, errors
    end

    -- save instance to the cache
    platform._PLATFORMS[plat] = instance

    -- ok
    return instance

end

-- get the given platform configure
function platform.get(name, plat)

    -- get the current platform configure
    local instance, errors = platform.load(plat)
    if instance then
        return instance:get(name)
    else
        os.raise(errors)
    end
end

-- get the platform tool from the kind
--
-- .e.g cc, cxx, mm, mxx, as, ar, ld, sh, ..
--
function platform.tool(toolkind)

    -- attempt to get program from config first
    local program = config.get(toolkind)
    local toolname = config.get("__toolname_" .. toolkind)
    if program == nil then 
        
        -- check it first
        local check = platform.get("check")
        if check then
            check("config", toolkind)
        end

        -- get it again
        program = config.get(toolkind)
        toolname = config.get("__toolname_" .. toolkind)
    end

    -- contain toolname? parse it, .e.g 'gcc@xxxx.exe'
    if program then
        local pos = program:find('@', 1, true)
        if pos then
            toolname = program:sub(1, pos - 1)
            program = program:sub(pos + 1)
        end
    end

    -- ok
    return program, toolname
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

-- get the platform os
function platform.os(plat)
    return platform.get("os", plat)
end

-- get the platform archs
function platform.archs(plat)
    return platform.get("archs", plat)
end

-- get the format of the given target kind for platform
function platform.format(targetkind)

    -- get formats
    local formats = platform.get("formats")
    if formats then
        return formats[targetkind]
    end
end


-- return module
return platform
