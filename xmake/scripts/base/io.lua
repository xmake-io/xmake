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
-- @file        io.lua
--

-- define module: io
local io = io or {}

-- load modules
local utils = require("base/utils")

-- save object with the level
function io._save_with_level(file, object, level)
 
    -- check
    assert(object)

    -- save string
    if type(object) == "string" then  
        file:write(string.format("%q", object))  
    -- save boolean
    elseif type(object) == "boolean" then  
        file:write(tostring(object))  
    -- save number 
    elseif type(object) == "number" then  
        file:write(object)  
    -- save table
    elseif type(object) == "table" then  

        -- save head
        file:write("\n")  
        for l = 1, level do
            file:write("    ")
        end
        file:write("{\n")  

        -- save body
        local i = 0
        for k, v in pairs(object) do  

            -- save spaces
            for l = 1, level do
                file:write("    ")
            end

            -- save separator
            file:write(utils.ifelse(i == 0, "    ", ",   "), k, " = ")  

            -- save this key: value
            if not io._save_with_level(file, v, level + 1) then 
                return false
            end

            -- save newline
            file:write("\n")
            i = i + 1
        end  

        -- save tail
        for l = 1, level do
            file:write("    ")
        end
        file:write("}\n")  
    else  
        -- error
        utils.error("invalid object type: %s", type(object))
        return false
    end  

    -- ok
    return true
end

-- save object
function io.save(file, object, prefix)
   
    -- save prefix
    if prefix and type(prefix) == "string" then
        file:write(prefix)
    end
 
    -- save it
    return io._save_with_level(file, object, 0)
end

-- return module: io
return io
