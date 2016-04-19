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
-- @file        io.lua
--

-- load modules
local io        = require("base/io")
local utils     = require("base/utils")
local raise     = require("sandbox/modules/raise")
local vformat   = require("sandbox/modules/vformat")

-- define module
local sandbox_io = sandbox_io or {}

-- print file
function sandbox_io._print(self, ...)

    -- check
    assert(self._FILE)
    
    -- print it
    return self._FILE:write(vformat(...) .. "\n")
end

-- printf file
function sandbox_io._printf(self, ...)

    -- check
    assert(self._FILE)
    
    -- printf it
    return self._FILE:write(vformat(...))
end

-- gsub the given file and return replaced data
function sandbox_io.gsub(filepath, pattern, replace)
 
    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- replace all
    local data, count, errors = io.gsub(filepath, pattern, replace)
    if not data then
        raise(errors)
    end

    -- ok
    return data, count
end

-- open file
function sandbox_io.open(filepath, mode)
 
    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- open it
    local file, errors = io.open(filepath, mode)
    if not file then
        raise(errors)
    end

    -- replace print with vformat
    file.print  = sandbox_io._print
    file.printf = sandbox_io._printf

    -- ok?
    return file
end

-- load object from the given file
function sandbox_io.load(filepath)
 
    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- done
    local result, errors = io.load(filepath)
    if not result then
        raise(errors)
    end

    -- ok
    return result
end

-- save object the the given filepath
function sandbox_io.save(filepath, object)
    
    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- done
    local ok, errors = io.save(filepath, object)
    if not ok then
        raise(errors)
    end
end

-- read all data from file 
function sandbox_io.read(filepath)

    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- done
    local result, errors = io.readall(filepath)
    if not result then
        raise(errors)
    end

    -- ok
    return result
end

-- write all data to file 
function sandbox_io.write(filepath, data)
 
    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- done
    local ok, errors = io.writall(filepath, data)
    if not ok then
        raise(errors)
    end
end

-- cat the given file 
function sandbox_io.cat(filepath, linecount)
 
    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- cat it
    io.cat(filepath, linecount)
end

-- tail the given file 
function sandbox_io.tail(filepath, linecount)
 
    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- tail it
    io.tail(filepath, linecount)
end

-- return module
return sandbox_io

