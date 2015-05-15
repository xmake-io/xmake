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
-- @file        utils.lua
--

-- define module: utils
local utils = utils or {}

-- the printf function
function utils.printf(msg, ...)
    print(string.format(msg, ...))
end

-- the verbose function
function utils.verbose(msg, ...)
    if xmake._OPTIONS.verbose then
        print(string.format(msg, ...))
    end
end

-- the error function
function utils.error(msg, ...)
    print("error: " .. string.format(msg, ...))
end

-- the warning function
function utils.warning(msg, ...)
    print("warning: " .. string.format(msg, ...))
end

-- ifelse, a? b : c
function utils.ifelse(a, b, c)
    if a then return b else return c end
end

-- dump object with the level
function utils._dump_with_level(object, exclude, level)
 
    -- check
    assert(object)

    -- dump string
    if type(object) == "string" then  
        io.write(string.format("%q", object))  
    -- dump boolean
    elseif type(object) == "boolean" then  
        io.write(tostring(object))  
    -- dump number 
    elseif type(object) == "number" then  
        io.write(object)  
    -- dump function 
    elseif type(object) == "function" then  
        io.write("<function>")  
    -- dump table
    elseif type(object) == "table" then  

        -- dump head
        io.write("\n")  
        for l = 1, level do
            io.write("    ")
        end
        io.write("{\n")  

        -- dump body
        local i = 0
        for k, v in pairs(object) do  

            -- exclude some keys
            if not exclude or type(k) ~= "string" or not k:find(exclude) then

                -- dump spaces
                for l = 1, level do
                    io.write("    ")
                end

                -- dump separator
                io.write(utils.ifelse(i == 0, "    ", ",   "))
                
                -- dump key
                if type(k) == "string" then
                    io.write(k, " = ")  
                end

                -- dump value
                if not utils._dump_with_level(v, exclude, level + 1) then 
                    return false
                end

                -- dump newline
                io.write("\n")
                i = i + 1
            end
        end  

        -- dump tail
        for l = 1, level do
            io.write("    ")
        end
        io.write("}\n")  
    else  
        -- error
        utils.error("invalid object type: %s", type(object))
        return false
    end  

    -- ok
    return true
end

-- dump object
function utils.dump(object, exclude)
  
    -- dump it
    utils._dump_with_level(object, exclude, 0)

    -- return it
    return object
end

-- return module: utils
return utils
