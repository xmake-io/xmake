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
-- @file        utils.lua
--

-- load modules
local io        = require("base/io")
local utils     = require("base/utils")
local colors    = require("base/colors")
local try       = require("sandbox/modules/try")
local catch     = require("sandbox/modules/catch")
local vformat   = require("sandbox/modules/vformat")
local raise     = require("sandbox/modules/raise")

-- define module
local sandbox_utils = sandbox_utils or {}

-- inherit the public interfaces of utils
for k, v in pairs(utils) do
    if not k:startswith("_") and type(v) == "function" then
        sandbox_utils[k] = v
    end
end

-- print format string with newline
-- print builtin-variables with $(var)
-- print multi-variables with raw lua action
--
function sandbox_utils.print(format, ...)

    -- print format string
    if type(format) == "string" and format:find("%", 1, true) then

        local args = {...}
        try
        {
            function ()
                -- attempt to print format string first
                io.write(vformat(format, unpack(args)) .. "\n")
            end,
            catch 
            {
                function ()
                    -- print multi-variables with raw lua action
                    print(format, unpack(args))
                end
            }
        }

    else
        -- print multi-variables with raw lua action
        print(format, ...)
    end
end

-- print format string and the builtin variables without newline
function sandbox_utils.printf(format, ...)

    -- done
    io.write(vformat(format, ...))
end

-- print format string, the builtin variables and colors with newline
function sandbox_utils.cprint(format, ...)

    -- done
    io.write(colors(vformat(format, ...) .. "\n"))
end

-- print format string, the builtin variables and colors without newline
function sandbox_utils.cprintf(format, ...)

    -- done
    io.write(colors(vformat(format, ...)))
end

-- assert
function sandbox_utils.assert(value, format, ...)

    -- check
    if not value then
        if format ~= nil then
            raise(format, ...)
        else
            raise("assertion failed!")  
        end
    end

    -- return it 
    return value
end


-- return module
return sandbox_utils

