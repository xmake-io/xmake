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
-- @file        string.lua
--

-- load modules
local string    = require("base/string")
local sandbox   = require("sandbox/sandbox")

-- define module
local sandbox_string = sandbox_string or {}

-- inherit the public interfaces of string
for k, v in pairs(string) do
    if not k:startswith("_") and type(v) == "function" then
        sandbox_string[k] = v
    end
end

-- format string with the builtin variables
function sandbox_string.vformat(format, ...)

    -- check
    assert(format)

    -- get the current sandbox instance
    local instance = sandbox.instance()
    assert(instance)

    -- ignore %$(...)
    format = format:gsub("%%%$", "__$__")

    -- format string
    local result = string.format(format, ...)
    assert(result)

    -- get filter from the current sandbox
    local filter = instance:filter()
    if filter then
        result = filter:handle(result)
    end

    -- escape to $(...)
    result = result:gsub("__%$__", "$")

    -- ok?
    return result
end

-- return module
return sandbox_string

