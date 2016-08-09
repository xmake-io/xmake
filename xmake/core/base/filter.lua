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
-- @file        filter.lua
--

-- define module: filter
local filter = filter or {}

-- load modules
local os        = require("base/os")
local table     = require("base/table")
local utils     = require("base/utils")
local string    = require("base/string")

-- new filter instance
function filter.new(handler)

    -- init an filter instance
    local self = table.inherit(filter)

    -- save handler
    self._HANDLER = handler

    -- ok
    return self
end

-- filter the shell command
-- 
-- .e.g
--
-- print("$(shell echo hello xmake)")
-- add_ldflags("$(shell pkg-config --libs sqlite3)")
--
function filter.shell(cmd)

    -- empty?
    if #cmd == 0 then
        os.raise("empty $(shell)!")
    end

    -- run shell
    local ok, outdata, errdata = os.iorun(cmd)
    if not ok then
        os.raise("run $(shell %s) failed, errors: %s", cmd, errdata or "")
    end

    -- trim it
    if outdata then
        outdata = outdata:trim()
    end

    -- return the shell result
    return outdata or ""
end

-- filter the builtin variables: "hello $(variable)" for string
--
-- .e.g  
--
-- print("$(host)")
--
function filter:handle(value)

    -- check
    assert(type(value) == "string")

    -- return it directly if no handler
    local handler = self._HANDLER
    if handler == nil then
        return value
    end

    -- filter the builtin variables
    return (value:gsub("%$%((.-)%)", function (variable) 

        -- check
        assert(variable)

        -- is shell?
        if variable:startswith("shell ") then
            return filter.shell(variable:sub(7, -1))
        end

        -- parse variable:mode
        local varmode   = variable:split(':')
        local mode      = varmode[2]
        variable        = varmode[1]
       
        -- handler it
        local result = handler(variable)

        -- invalid builtin variable?
        if result == nil then
            os.raise("invalid variable: $(%s)", variable)
        end
 
        -- handle mode
        if mode then
            if mode == "upper" then
                result = result:upper()
            elseif mode == "lower" then
                result = result:lower()
            end
        end

        -- ok?
        return result
    end))
end

-- return module: filter
return filter
