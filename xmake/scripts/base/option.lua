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
-- @file        option.lua
--

-- define module: option
local option = {}

-- init _OPTIONS.metatable to always use lowercase keys
local _OPTIONS_metatable = 
{
    __index = function(table, key)
        -- make lowercase key
        if type(key) == "string" then
            key = key:lower()
        end
        return rawget(table, key)
    end
,   __newindex = function(table, key, value)
        -- make lowercase key
        if type(key) == "string" then
            key = key:lower()
        end
        rawset(table, key, value)
    end
}
xmake._OPTIONS = xmake._OPTIONS or {}
setmetatable(xmake._OPTIONS, _OPTIONS_metatable)

-- done the option
function option.done(argv)

    -- check
    assert(option._MENU)

    -- parse _ARGV to _OPTIONS
    for i, arg in ipairs(argv) do

        -- parse key and value
        local key, value
        local i = arg:find("=", 1, true)

        -- key=value?
        if i then
            key = arg:sub(1, i - 1)
            value = arg:sub(i + 1)
        -- only key?
        else
            key = arg
            value = ""
        end

        -- -k?
        if key:startswith("-") then
            xmake._OPTIONS[key:sub(2)] = value
        -- --key=value?
        elseif key:startswith("--") then
           xmake. _OPTIONS[key:sub(3)] = value
        end
    end

    -- ok
    return true
end

-- print the help option
function option.help()

    -- check
    assert(option._MENU)

end  

-- return module: option
return option
