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
-- @file        dispatcher.lua
--

-- define module: dispatcher
local dispatcher = dispatcher or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")

-- the main function
--
-- dispatcher toolname toolpath action arguments ... 
function dispatcher.main(self, ...)

    -- check
    local args = ...
    assert(#args >= 3)

    -- get toolpath
    local toolname      = args[1]
    local toolpath      = args[2]
    local action_name   = args[3]
    assert(toolname and toolpath and action_name)

    -- load script
    local script, errors = loadfile(toolpath)
    if script then
        
        -- load tool
        local tool = script()

        -- init tool 
        if tool and tool.init then
            tool:init(toolname)
        end

        -- load action
        local action = tool[action_name]
        if action then
            
            -- init arguments for action
            local action_args = {}
            for i = 4, #args do
                table.insert(action_args, args[i])
            end

            -- done action
            if not action(tool, action_args) then
                utils.error("run action %s for '%s' failed!", action_name, toolname)
                assert(false)
            end
        else
            utils.error("load action %s for '%s' failed!", action_name, toolname)
            assert(false)
        end

    else
        utils.error(errors)
        utils.error("load %s failed!", toolpath)
        assert(false)
    end

    -- ok
    return true
end

-- return module: dispatcher
return dispatcher
