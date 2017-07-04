--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        table.lua
--

-- define module: table
local table = table or {}

-- clear the table
function table.clear(self)

    -- check
    assert(self and type(self) == "table")

    -- clear it
    for k in next, self do
        rawset(self, k, nil) 
    end
end

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

-- copy the table to self
function table.copy(copied)

    -- init it
    copied = copied or {}

    -- copy it
    local result = {}
    for k, v in pairs(table.wrap(copied)) do
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
    for k, v in pairs(table.wrap(copied)) do
        self[k] = v
    end

end

-- inherit interfaces and create a new instance
function table.inherit(...)

    -- init instance
    local classes = {...}
    local instance = {}
    for _, clasz in ipairs(classes) do
        for k, v in pairs(clasz) do
            if type(v) == "function" then
                instance[k] = v
            end
        end
    end

    -- ok?
    return instance
end

-- inherit interfaces from the given class
function table.inherit2(self, ...)

    -- check
    assert(self)

    -- init instance
    local classes = {...}
    for _, clasz in ipairs(classes) do
        for k, v in pairs(clasz) do
            if type(v) == "function" and self[k] == nil then
                self[k] = v
            end
        end
    end

    -- ok?
    return self
end

-- slice table array
function table.slice(self, first, last, step)

    -- slice it
    local sliced = {}
    for i = first or 1, last or #self, step or 1 do
        sliced[#sliced + 1] = self[i]
    end
    return sliced
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
 
    -- dump basic type
    if type(self) == "string" or type(self) == "boolean" or type(self) == "number" then  
        io.write(tostring(self))  
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
                table._dump(v, exclude, level + 1)  

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
        io.write("<" .. tostring(self) .. ">")
    end
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

-- unwrap object if be only one
function table.unwrap(object)

    -- check
    assert(object)

    -- unwrap it
    if type(object) == "table" and table.getn(object) == 1 then
        for _, v in pairs(object) do
            return v
        end
    end

    -- ok
    return object
end

-- wrap object to table
function table.wrap(object)

    -- no object?
    if nil == object then
        return {}
    end

    -- wrap it if not table
    if type(object) ~= "table" then
        return {object}
    end

    -- ok
    return object
end

-- remove repeat from the given array
function table.unique(array)

    -- remove repeat
    if type(array) == "table" then

        -- not only one?
        if table.getn(array) ~= 1 then

            -- done
            local exists = {}
            local unique = {}
            for _, v in ipairs(array) do
                if type(v) == "string" then
                    if not exists[v] then
                        exists[v] = true
                        table.insert(unique, v)
                    end
                else
                    local key = "\"" .. tostring(v) .. "\""
                    if not exists[key] then
                        exists[key] = true
                        table.insert(unique, v)
                    end
                end
            end

            -- update it
            array = unique
        end
    end

    -- ok
    return array
end

-- return module: table
return table
