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
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        checker.lua
--

-- define module
local checker = checker or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local config    = require("project/config")
local global    = require("project/global")
local sandbox   = require("sandbox/sandbox")
local platform  = require("platform/platform")

-- the directories of checker
function checker._directories(plat)

    -- the directories
    return  {   path.join(path.join(config.directory(), "platforms"), plat)
            ,   path.join(path.join(global.directory(), "platforms"), plat)
            ,   path.join(path.join(xmake._PROGRAM_DIR, "platforms"), plat)
            }
end

-- check the list
function checker._checklist(funclist, ...)

    -- check all
    for _, func in ipairs(table.wrap(funclist)) do
        
        -- call it
        local ok, errors = sandbox.load(func, ...)
        if not ok then
            return false, errors
        end
    end

    -- ok
    return true
end

-- load the given checker from the given platform
function checker.load(plat)

    -- check
    assert(plat)

    -- get it directly from cache dirst
    checker._CHECKERS = checker._CHECKERS or {}
    if checker._CHECKERS[plat] then
        return checker._CHECKERS[plat]
    end

    -- find the checker script path
    local scriptpath = nil
    for _, dir in ipairs(checker._directories(plat)) do

        -- find this directory
        scriptpath = path.join(dir, "checker.lua")
        if os.isfile(scriptpath) then
            break
        end

    end

    -- not exists?
    if not scriptpath or not os.isfile(scriptpath) then
        return nil, string.format("the checker of %s not found!", plat)
    end

    -- load script
    local script, errors = loadfile(scriptpath)
    if script then

        -- make sandbox instance with the given script
        local instance, errors = sandbox.new(script, nil, path.directory(scriptpath))
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
    
        -- save tool to the cache
        checker._CHECKERS[plat] = module

        -- ok?
        return module
    end

    -- failed
    return nil, errors
end

-- check the project or global configure
--
-- @param name      the configure name: global or config
--
function checker.check(name)

    -- check the project configure?
    if name == "config" then

        -- get the current platform
        local plat = config.get("plat")
        if not plat then
            return false, string.format("the current platform is unknown!")
        end

        -- load the checker module
        local module, errors = checker.load(plat)
        if not module then
            return false, errors
        end

        -- check it
        return checker._checklist(module.get("config"), config)

    -- check the global configure?
    elseif name == "global" then

        -- check all platforms with the current host
        for _, plat in ipairs(table.wrap(platform.plats())) do

            -- load the checker module
            local module, errors = checker.load(plat)
            if not module then
                return false, errors
            end

            -- belong to the current host?
            if module.get("host") == xmake._HOST then

                -- check it
                local ok, errors = checker._checklist(module.get("global"), global)
                if not ok then
                    return false, errors
                end
            end
        end

        -- ok
        return true
    end

    -- failed
    return false, string.format("unknown check name: %s", name)
end

-- return module
return checker
