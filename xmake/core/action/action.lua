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
-- @file        action.lua
--

-- define module: action
local action = action or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local global    = require("base/global")
local config    = require("base/config")
local project   = require("base/project")
local platform  = require("base/platform")

-- load the given action
function action._load(name)
    
    -- load the given action
    return require("action/_" .. name)
end

-- load the project file
function action._load_project()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- enter the project directory
    if not os.cd(xmake._PROJECT_DIR) then
        -- error
        return string.format("not found project: %s!", xmake._PROJECT_DIR)
    end

    -- check the project file
    if not os.isfile(xmake._PROJECT_FILE) then
        return string.format("not found the project file: %s", xmake._PROJECT_FILE)
    end

    -- init the build directory
    if options.buildir and path.is_absolute(options.buildir) then
        options.buildir = path.relative(options.buildir, xmake._PROJECT_DIR)
    end

    -- xmake config or marked as "reconfig"?
    if options._ACTION == "config" or config._RECONFIG then

        -- probe the current project 
        project.probe()

        -- clear up the configure
        config.clearup()

    end

    -- load the project 
    return project.load()
end

-- done the given action
function action.done(name)
    
    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- load the given action
    local _action = action._load(name)
    if not _action then return false end

    -- load the global configure first
    if _action.need("global") then global.load() end

    -- load the project configure
    if _action.need("config") then
        local errors = config.load()
        if errors then
            -- error
            utils.error(errors)
            return false
        end
    end

    -- probe the platform
    if _action.need("platform") and (options._ACTION == "config" or config._RECONFIG) then
        if not platform.probe(false) then
            return false
        end
    end

    -- merge the default options
    for k, v in pairs(options._DEFAULTS) do
        if nil == options[k] then options[k] = v end
    end

    -- make the platform configure
    if _action.need("platform") and not platform.make() then
        utils.error("make platform configure: %s failed!", config.get("plat"))
        return false
    end

    -- load the project file
    if _action.need("project") then
        local errors = action._load_project()
        if errors then
            -- error
            utils.error(errors)
            return false
        end
    end

    -- reconfig it first if marked as "reconfig"
    if _action.need("config") and config._RECONFIG then

        -- config it
        local _action_config = action._load("config")
        if not _action_config or not _action_config.done() then
            -- error
            utils.error("reconfig failed for the changed host!")
            return false
        end
    end

    -- done the given action
    return _action.done()
end

-- list the all actions
function action.list()
    
    -- find all action scripts
    local list = {}
    local files = os.match(xmake._CORE_DIR .. "/action/_*.lua")
    if files then
        for _, file in ipairs(files) do
            local name = path.basename(file)
            if name and name ~= "_build" then
                table.insert(list, name:sub(2))
            end
        end
    end

    -- ok?
    return list
end

-- get the all action menus
function action.menu()

    -- get all actions
    local menus = {}
    local actions = action.list()
    for _, name in ipairs(actions) do
        
        -- load action
        local a = action._load(name)
        if a and a.menu then
            local m = a.menu()
            if m then
                menus[name] = m
            end
        end
    end

    -- ok?
    return menus
end

-- return module: action
return action
