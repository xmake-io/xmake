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
-- @file        tool.lua
--

-- define module
local sandbox_core_tool = sandbox_core_tool or {}

-- load modules
local tool      = require("tool/tool")
local config    = require("project/config")
local platform  = require("platform/platform")
local raise     = require("sandbox/modules/raise")

-- get the tool shell name
function sandbox_core_tool.shellname(name)

    -- get it
    return platform.tool(name)
end

-- check the tool and return the absolute path if exists
function sandbox_core_tool.check(shellname, dirs, check)

    -- check it
    return tool.check(shellname, dirs or platform.tooldirs(), check)
end

-- return module
return sandbox_core_tool
