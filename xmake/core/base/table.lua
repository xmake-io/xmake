--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        table.lua
--

-- define module: table
local table = table or {}

-- make string with the level
function table._makestr(self, deflate, level)
    if type(self) == "string" or type(self) == "boolean" or type(self) == "number" then  
        return tostring(self)
    elseif type(self) == "table" and (getmetatable(self) or {}).__tostring then
        return tostring(self)
    elseif type(self) == "table" then  

        -- make head
        local s = ""
        if deflate then
            s = s .. "{"
        else
            s = s .. "\n"
            for l = 1, level do
                s = s .. "    "
            end
            s = s .. "{\n"
        end

        -- make body
        local i = 0
        for k, v in pairs(self) do  

            if deflate then
                s = s .. (i ~= 0 and "," or "")
            else
                for l = 1, level do
                    s = s .. "    "
                end
                if i == 0 then
                    s = s .. "    "
                else
                    s = s .. ",   "
                end
            end
            
            -- make key = value
            if type(k) == "string" then
                if deflate then
                    s = s .. k .. "=" 
                else
                    s = s .. k .. " = " 
                end
            end
            s = s .. table._makestr(v, deflate, level + 1)  

            if not deflate then
                s = s .. "\n"
            end
            i = i + 1
        end  

        -- make tail
        if not deflate then
            for l = 1, level do
                s = s .. "    "
            end
        end
        s = s .. "}"
        return s
    elseif self ~= nil then
        return "<" .. tostring(self) .. ">"
    else
        return "nil"
    end
end

-- clear the table
function table.clear(self)
    for k in next, self do
        rawset(self, k, nil) 
    end
end

-- join all objects and tables
function table.join(...)

    local result = {}
    for _, t in ipairs({...}) do
        if type(t) == "table" then
            for k, v in pairs(t) do
                if type(k) == "number" then table.insert(result, v)
                else result[k] = v end
            end
        else
            table.insert(result, t)
        end
    end
    return result
end

-- join all objects and tables to self
function table.join2(self, ...)

    for _, t in ipairs({...}) do
        if type(t) == "table" then
            for k, v in pairs(t) do
                if type(k) == "number" then table.insert(self, v)
                else self[k] = v end
            end
        else
            table.insert(self, t)
        end
    end
    return self
end

-- append all objects to array
function table.append(array, ...)
    for _, value in ipairs({...}) do
        table.insert(array, value)
    end
    return array
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
    local metainfo = {}
    for _, clasz in ipairs(classes) do
        for k, v in pairs(clasz) do
            if type(v) == "function" then
                if k:startswith("__") then
                    if metainfo[k] == nil then
                        metainfo[k] = v
                    end
                else
                    if instance[k] == nil then
                        instance[k] = v
                    else
                        instance["_super_" .. k] = v
                    end
                end
            end
        end
    end
    setmetatable(instance, metainfo)

    -- ok?
    return instance
end

-- inherit interfaces from the given class
function table.inherit2(self, ...)

    -- check
    assert(self)

    -- init instance
    local classes = {...}
    local metainfo = getmetatable(self) or {}
    for _, clasz in ipairs(classes) do
        for k, v in pairs(clasz) do
            if type(v) == "function" then
                if k:startswith("__") then
                    if metainfo[k] == nil then
                        metainfo[k] = v
                    end
                else
                    if self[k] == nil then
                        self[k] = v
                    else 
                        self["_super_" .. k] = v
                    end
                end
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
function table.is_array(array)
    return type(array) == "table" and array[1] ~= nil
end

-- is dictionary?
function table.is_dictionary(dict)
    return type(dict) == "table" and dict[1] == nil
end

-- dump table
function table.dump(self, deflate)
    io.write(table.makestr(self, deflate))
end

-- make string from the given table
function table.makestr(self, deflate)
    return table._makestr(self, deflate, 0)
end

-- unwrap object if be only one
function table.unwrap(object)
    if type(object) == "table" then
        if #object == 1 then
            return object[1]
        end
    end
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
function table.unique(array, barrier)

    -- remove repeat
    if type(array) == "table" then

        -- not only one?
        if table.getn(array) ~= 1 then

            -- done
            local exists = {}
            local unique = {}
            for _, v in ipairs(array) do

                -- exists barrier? clear the current existed items
                if barrier and barrier(v) then
                    exists = {}
                end

                -- add unique item
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
