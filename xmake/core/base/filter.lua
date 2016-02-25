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
-- @file        filter.lua
--

-- define module: filter
local filter = filter or {}

-- load modules
local table     = require("base/table")
local utils     = require("base/utils")
local string    = require("base/string")

-- init filter
function filter.init(handler)

    -- init an filter instance
    local self = {_HANDLER = handler}

    -- inherit the interfaces of filter
    for k, v in pairs(filter) do
        if type(v) == "function" then
            self[k] = v
        end
    end

    -- ok
    return self
end

-- filter the builtin variables: "hello $(variable)" for string
function filter.handle(self, value)

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
                                    
        -- is upper?
        local isupper = false
        local c = string.char(variable:byte())
        if c >= 'A' and c <= 'Z' then isupper = true end

        -- handler it
        local result = handler(variable:lower())

        -- convert to upper?
        if isupper and result and type(result) == "string" then
            result = result:upper() 
        end

        -- invalid builtin variable?
        if result == nil then
            utils.error("invalid variable: $(%s)", variable)
            utils.abort()
        end

        -- ok?
        return result
    end))
end

-- return module: filter
return filter
