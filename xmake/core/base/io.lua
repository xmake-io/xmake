--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        io.lua
--

-- define module
local io    = io or {}
local _file = _file or {}

-- load modules
local path   = require("base/path")
local table  = require("base/table")
local utils  = require("base/utils")
local string = require("base/string")

-- save original apis
io._open   = io._open or io.open
io._isatty = io._isatty or io.isatty

-- seek file
function _file:seek(...)
    return self._FILE:seek(...)
end

-- read file
function _file:read(...)
    return self._FILE:read(...)
end

-- write file
function _file:write(...)
    return self._FILE:write(...)
end

-- print file
function _file:print(...)
    return self._FILE:write(string.format(...) .. "\n")
end

-- printf file
function _file:printf(...)
    return self._FILE:write(string.format(...))
end

-- get lines
function _file:lines()
    return self._FILE:lines()
end

-- close file
function _file:close()
    return self._FILE:close()
end

-- save object
function _file:save(object)
    local str, errors = string.serialize(object, false)
    if str then
        self:write(str)
    end
    return str, errors
end

-- load object
function _file:load()
    local data = self:read("*all")
    if data and type(data) == "string" then
        return data:deserialize()
    end
end

-- read all data from file 
function io.readfile(filepath)

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

-- write data to file 
function io.writefile(filepath, data)

    -- open file
    local file = io.open(filepath, "w")
    if not file then
        return false, string.format("open %s failed!", filepath)
    end

    -- write all
    file:write(data)

    -- exit file
    file:close()

    -- ok?
    return true
end

-- replace the original isatty interface
function io.isatty(fd)
    if io._ISATTY == nil then
        io._ISATTY = io._isatty(fd or io.stdout)
    end
    return io._ISATTY
end

-- replace the original open interface
function io.open(filepath, mode)

    -- check
    assert(filepath)

    -- write file?
    if mode == "w" then

        -- get the file directory
        local dir = path.directory(filepath)

        -- ensure the file directory 
        if not os.isdir(dir) then
            os.mkdir(dir) 
        end
    end

    -- init file instance
    local file = table.inherit(_file)

    -- open it
    local handle, errors = io._open(path.translate(filepath), mode)
    if not handle then
        return nil, errors
    end

    -- save file handle
    file._FILE = handle

    -- ok?
    return file, errors
end

-- save object the the given filepath
function io.save(filepath, object)

    -- check 
    assert(filepath and object)

    -- ensure directory
    local dir = path.directory(filepath)
    if not os.isdir(dir) then
        os.mkdir(dir)
    end
    
    -- open the file
    local file = io.open(filepath, "w")
    if not file then
        -- error
        return false, string.format("open %s failed!", filepath)
    end

    -- save object to file
    local ok, errors = file:save(object)
    if not ok then
        -- error 
        file:close()
        return false, string.format("save %s failed, %s!", filepath, errors)
    end

    -- close file
    file:close()
   
    -- ok
    return true
end
 
-- load object from the given file
function io.load(filepath)

    -- check
    assert(filepath)

    -- open the file
    local file = io.open(filepath, "r")
    if not file then
        -- error
        return nil, string.format("open %s failed!", filepath)
    end

    -- load object
    local result, errors = file:load()

    -- close file
    file:close()

    -- ok?
    return result, errors
end

-- gsub the given file and return replaced data
function io.gsub(filepath, pattern, replace)

    -- read all data from file
    local data, errors = io.readfile(filepath)
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
        local ok, errors = io.writefile(filepath, data) 
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

    -- all?
    if linecount < 0 then
        return io.cat(filepath)
    end

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

-- return module
return io
