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
local path  = require("base/path")
local utils = require("base/utils")

-- save object with the level
function io._save_with_level(file, object, level)
 
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

            -- save spaces and separator
            for l = 1, level do
                file:write("    ")
            end

            file:write(utils.ifelse(i == 0, "    ", ",   "))
            
            -- save key
            if type(k) == "string" then
                file:write(string.format("[%q]", k), " = ")  
            end

            -- save value
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

-- save object to given file
function io._save(file, object)
   
    -- save it
    return io._save_with_level(file, object, 0)
end

-- create directory and open a writable file
function io.openmk(filepath)

    -- check
    assert(filepath)

    -- get the file directory
    local dir = path.directory(filepath)

    -- ensure the file directory 
    if not os.isdir(dir) then os.mkdir(dir) end

    -- open it
    return io.open(filepath, "w")
end

-- read all data from file 
function io.readall(filepath)

    -- open file
    local file = io.open(filepath, "r")
    if not file then
        -- error
        return nil, string.format("open %s failed!", filepath)
    end

    -- read all
    local data = file:read("*all")

    -- exit file
    file:close()

    -- ok?
    return data
end

-- write all data to file 
function io.writall(filepath, data)

    -- open file
    local file = io.open(filepath, "w")
    if not file then
        -- error
        return false, string.format("open %s failed!", filepath)
    end

    -- write all
    file:write(data)

    -- exit file
    file:close()

    -- ok?
    return true
end

-- save object the the given filepath
function io.save(filepath, object)
    
    -- open the file
    local file = io.openmk(filepath)
    if not file then
        -- error
        return false, string.format("open %s failed!", filepath)
    end

    -- save object to file
    if not io._save(file, object) then
        -- error 
        file:close()
        return false, string.format("save %s failed!", filepath)
    end

    -- close file
    file:close()
   
    -- ok
    return true
end
 
-- load object from the given file
function io.load(filepath)

    -- open the file
    local file = io.open(filepath, "r")
    if not file then
        -- error
        return nil, string.format("open %s failed!", filepath)
    end

    -- load data
    local result = nil
    local errors = nil
    local data = file:read("*all")
    if data and type(data) == "string" then

        -- load script
        local script, errs = loadstring("return " .. data)
        if script then
            
            -- load object
            local ok, object = pcall(script)
            if ok and object then
                result = object
            elseif object then
                -- error
                errors = object
            else
                -- error
                errors = string.format("load %s failed!", filepath)
            end
        -- errors
        else errors = errs end
    end

    -- close file
    file:close()

    -- ok?
    return result, errors
end

-- gsub the given file and return replaced data
function io.gsub(filepath, pattern, replace)

    -- read all data from file
    local data, errors = io.readall(filepath)
    if not data then return nil, 0, errors end

    -- replace it
    local count = 0
    if type(data) == "string" then
        data, count = data:gsub(pattern, replace)
    else
        return nil, 0, string.format("data is not string!")
    end

    -- replace ok?
    if count ~= 0 then
        -- write all data to file
        local ok, errors = io.writall(filepath, data) 
        if not ok then return nil, 0, errors end
    end

    -- ok
    return data, count
end

-- cat the given file 
function io.cat(filepath, linecount)

    -- open file
    local file = io.open(filepath, "r")
    if file then

        -- show file
        local count = 1
        for line in file:lines() do

            -- show line
            print(line)

            -- end?
            if linecount and count >= linecount then
                break
            end

            -- update the line count
            count = count + 1
        end 

        -- exit file
        file:close() 
    end
end

-- tail the given file 
function io.tail(filepath, linecount)

    -- open file
    local file = io.open(filepath, "r")
    if file then

        -- read lines
        local lines = {}
        for line in file:lines() do
            table.insert(lines, line)
        end

        -- tail lines
        local tails = {}
        if #lines ~= 0 then
            local count = 1
            for index = #lines, 1, -1 do

                -- show line
                table.insert(tails, lines[index])

                -- end?
                if linecount and count >= linecount then
                    break
                end

                -- update the line count
                count = count + 1
            end
        end

        -- show tails
        if #tails ~= 0 then
            for index = #tails, 1, -1 do

                -- show tail
                print(tails[index])

            end
        end

        -- exit file
        file:close() 
    end
end

-- return module: io
return io
