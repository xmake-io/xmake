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
function table.copy2(self, copied)

    -- check
    assert(self and copied)

    -- clear self first
    table.clear(self)

    -- copy it
    for k, v in pairs(copied) do
        self[k] = v
    end

end

-- return module: table
return table
