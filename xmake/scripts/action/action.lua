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
local os    = require("base/os")
local path  = require("base/path")

-- load the given action
function action._load(name)
    
    -- load the given action
    return require("action/_" .. name)
end

-- done the given action
function action.done(name)
    
    -- load the given action
    local a = action._load(name)
    if not a then return false end

    -- done the given action
    return a.done()
end

-- list the all actions
function action.list()
    
    -- find all action scripts
    local list = {}
    local files = os.match(xmake._SCRIPTS_DIR .. "/action/_*.lua")
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
