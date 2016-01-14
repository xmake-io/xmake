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
local tools     = require("tools/tools")

-- the main function
--
-- dispatcher toolname toolpath action arguments ... 
function dispatcher.main(self, ...)

    -- check
    local args = ...
    assert(#args >= 2)

    -- get tool kind and action name
    local tool_kind     = args[1]
    local action_name   = args[2]
    assert(tool_kind and action_name)

    -- get the tool 
    local tool = tools.get(tool_kind)
    if tool then
        
        -- load action
        local action = tool[action_name]
        if action then
            
            -- init arguments for action
            local action_args = {}
            for i = 3, #args do
                table.insert(action_args, args[i]:decode())
            end

            -- done action
            if not action(tool, action_args) then
                utils.error("run action %s failed!", action_name)
                assert(false)
            end
        else
            utils.error("load action %s failed!", action_name)
            assert(false)
        end

    else
        assert(false)
    end

    -- ok
    return true
end

-- return module: dispatcher
return dispatcher
