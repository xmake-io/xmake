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
-- @file        io.lua
--

-- load modules
local io        = require("base/io")
local utils     = require("base/utils")
local string    = require("base/string")
local raise     = require("sandbox/modules/raise")
local vformat   = require("sandbox/modules/vformat")

-- define module
local sandbox_io = sandbox_io or {}

-- inherit some builtin interfaces
sandbox_io.flush  = io.flush
sandbox_io.seek   = io.seek
sandbox_io.read   = io.read
sandbox_io.write  = io.write
sandbox_io.stdin  = io.stdin
sandbox_io.stderr = io.stderr
sandbox_io.stdout = io.stdout
sandbox_io.isatty = io.isatty

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

    -- add writef with format
    file.writef = sandbox_io._writef

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
function sandbox_io.readfile(filepath)

    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- done
    local result, errors = io.readfile(filepath)
    if not result then
        raise(errors)
    end

    -- ok
    return result
end

-- write all data to file 
function sandbox_io.writefile(filepath, data)
 
    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- done
    local ok, errors = io.writefile(filepath, data)
    if not ok then
        raise(errors)
    end
end

-- print line to file
function sandbox_io.print(filepath, ...)
    sandbox_io.writefile(filepath, vformat(...) .. "\n")
end

-- print data to file
function sandbox_io.printf(filepath, ...)
    sandbox_io.writefile(filepath, vformat(...))
end

-- printf file
function sandbox_io._printf(self, ...)

    -- check
    assert(self._FILE)
    
    -- printf it
    return self._FILE:write(vformat(...))
end

-- writef file
function sandbox_io._writef(self, ...)

    -- check
    assert(self._FILE)
    
    -- printf it
    return self._FILE:write(string.format(...))
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

