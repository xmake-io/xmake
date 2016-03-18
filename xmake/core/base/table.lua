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
-- @file        table.lua
--

-- define module: table
local table = table or {}

-- join all objects and tables
function table.join(...)

    -- done
    local args = {...}
    local result = {}
    for _, t in ipairs(args) do
        if type(t) == "table" then
            for k, v in pairs(t) do
                if type(k) == "number" then table.insert(result, v)
                else result[k] = v end
            end
        else
            table.insert(result, t)
        end
    end

    -- ok?
    return result
end

-- join all objects and tables to self
function table.join2(self, ...)

    -- check
    assert(self and type(self) == "table")

    -- done
    local args = {...}
    for _, t in ipairs(args) do
        if type(t) == "table" then
            for k, v in pairs(t) do
                if type(k) == "number" then table.insert(self, v)
                else self[k] = v end
            end
        else
            table.insert(self, t)
        end
    end

    -- ok?
    return self
end

-- clear the table
function table.clear(self)

    -- check
    assert(self and type(self) == "table")

    -- clear it
    for k in next, self do
        rawset(self, k, nil) 
    end
end

-- copy the table to self
function table.copy(copied)

    -- init it
    copied = copied or {}

    -- copy it
    local result = {}
    for k, v in pairs(copied) do
        result[k] = v
    end

    -- ok
    return result
end

-- copy the table to self
function table.copy2(self, copied)

    -- check
    assert(self)

    -- init it
    copied = copied or {}

    -- clear self first
    table.clear(self)

    -- copy it
    for k, v in pairs(copied) do
        self[k] = v
    end

end

-- is array?
function table.is_array(self)

    -- not table?
    if type(self) ~= "table" then
        return false
    end

    -- is array?
    for k, v in pairs(self) do
        if type(k) == "number" then
            return true
        end
        break
    end

    -- dictionary
    return false
end

-- is dictionary?
function table.is_dictionary(self)

    -- not table?
    if type(self) ~= "table" then
        return false
    end

    -- is dictionary?
    for k, v in pairs(self) do
        if type(k) == "string" then
            return true
        end
        break
    end

    -- array
    return false
end

-- dump it with the level
function table._dump(self, exclude, level)
 
    -- dump string
    if type(self) == "string" then  
        io.write(string.format("%q", self))  
    -- dump boolean
    elseif type(self) == "boolean" then  
        io.write(tostring(self))  
    -- dump number 
    elseif type(self) == "number" then  
        io.write(self)  
    -- dump function 
    elseif type(self) == "function" then  
        io.write("<function>")  
    -- dump table
    elseif type(self) == "table" then  

        -- dump head
        io.write("\n")  
        for l = 1, level do
            io.write("    ")
        end
        io.write("{\n")

        -- dump body
        local i = 0
        for k, v in pairs(self) do  

            -- exclude some keys
            if not exclude or type(k) ~= "string" or not k:find(exclude) then

                -- dump spaces and separator
                for l = 1, level do
                    io.write("    ")
                end

                if i == 0 then
                    io.write("    ")
                else
                    io.write(",   ")
                end
                
                -- dump key
                if type(k) == "string" then
                    io.write(k, " = ")  
                end

                -- dump value
                if not table._dump(v, exclude, level + 1) then 
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
    -- dump userdata
    elseif type(self) == "userdata" then  
        io.write("<userdata>")  
    else  
        -- error
        print("error: invalid object type: %s", type(self))
        return false
    end  

    -- ok
    return true
end

-- dump it
function table.dump(self, exclude, prefix)

    -- dump prefix
    if prefix then
        io.write(prefix)
    end
  
    -- dump it
    table._dump(self, exclude, 0)

    -- return it
    return self
end

-- return module: table
return table
