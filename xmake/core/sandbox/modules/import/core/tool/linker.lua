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
-- @file        linker.lua
--

-- define module
local sandbox_core_tool_linker = sandbox_core_tool_linker or {}

-- load modules
local platform  = require("platform/platform")
local raise     = require("sandbox/modules/raise")

-- make command for linking target file
function sandbox_core_tool_linker.command(target)
 
    -- get the linker instance
    local instance, errors = target:linker()
    if not instance then
        raise(errors)
    end

    -- make command
    return instance:command(target, target:objectfiles(), target:targetfile())
end

-- return module
return sandbox_core_tool_linker
