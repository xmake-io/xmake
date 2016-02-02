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
-- @file        string.lua
--

-- load modules
local string = require("base/string")
local filter = require("base/filter")

-- define module
local sandbox_builtin_string = sandbox_builtin_string or {}

-- format string with the builtin variables
function sandbox_builtin_string.vformat(format, ...)

    -- TODO
    -- format and filter it
--    return filter.done(string.format(format, ...), filter.handler_for_project)
end

-- inherit the public interfaces of string
for k, v in pairs(string) do
    if not k:startswith("_") and type(v) == "function" then
        sandbox_builtin_string[k] = v
    end
end

-- return module
return sandbox_builtin_string

