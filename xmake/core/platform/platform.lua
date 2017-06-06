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

    -- get if from info first
    local value = info[name]
    if value ~= nil then
        return value 
    end

    -- load _g 
    if self._g == nil and info.load ~= nil then

        -- load it
        local ok, results = sandbox.load(info.load)
        if not ok then
            os.raise(results)
        end

        -- save _g
        self._g = results
    end

    -- get it from _g 
    return self._g[name]
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
 
    -- define apis
    interp:api_define
    {
        values =
        {
            -- platform.set_xxx
            "platform.set_os"
        ,   "platform.set_hosts"
        ,   "platform.set_archs"
        ,   "platform.set_menu"
        ,   "platform.set_installdir"
        }
    ,   script =
        {
            -- platform.on_xxx
            "platform.on_load"
        ,   "platform.on_check"
        ,   "platform.on_install"
        ,   "platform.on_uninstall"
        }
    ,   module =
        {
            -- platform.set_xxx
            "platform.set_environment"
        }
    ,   dictionary =
        {
            -- platform.set_xxx
            "platform.set_formats"
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

-- get the given platform configure
function platform.get(name, plat)

    -- get the current platform configure
    local instance = platform.load(plat)
    if instance then
        return instance:get(name)
    end
end

-- get the platform tool from the kind
--
-- .e.g cc, cxx, mm, mxx, as, ar, ld, sh, ..
--
function platform.tool(toolkind)

    -- attempt to get it from config first
    local toolpath = config.get(toolkind)
    if toolpath ~= nil then
        return toolpath
    else
        
        -- check the tool path
        local check = platform.get("check")
        if check then
            check("config", toolkind)
        end

        -- get it again
        return config.get(toolkind)
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
