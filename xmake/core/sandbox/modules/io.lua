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

-- load modules
local io        = require("base/io")
local utils     = require("base/utils")
local string    = require("base/string")
local raise     = require("sandbox/modules/raise")
local vformat   = require("sandbox/modules/vformat")

-- define module
local sandbox_io          = sandbox_io or {}
local sandbox_io_file     = sandbox_io._file or {}
local sandbox_io_filelock = sandbox_io._filelock or {}
sandbox_io._file     = sandbox_io_file
sandbox_io._filelock = sandbox_io_filelock

-- inherit some builtin interfaces
sandbox_io.lines  = io.lines
sandbox_io.read   = io.read
sandbox_io.isatty = io.isatty

-- inherit matatable of file
if sandbox_io_file.__index ~= sandbox_io_file then
    sandbox_io_file.__index = sandbox_io_file
    for k, v in pairs(io._file) do
        if type(v) == "function" then
            sandbox_io_file[k] = function(s, ...)
                local result, err = v(s._FILE, ...)
                if result == nil and err ~= nil then
                    raise(err)
                end
                -- wrap to sandbox_file again
                if result == s._FILE then
                    result = s
                end
                return result
            end
        end
    end
    -- file:lines does not use its second return value for error
    sandbox_io_file.lines = io._file.lines
end

-- get file size
function sandbox_io_file:size()
    -- __len on tables is scheduled to be supported in 5.2.
    return sandbox_io_file.__len(self)
end

-- print file
function sandbox_io_file:print(...)
    return self:write(vformat(...), "\n")
end

-- printf file
function sandbox_io_file:printf(...)
    return self:write(vformat(...))
end

-- writef file
function sandbox_io_file:writef(...)
    return self:write(string.format(...))
end

-- gsub the given file and return replaced data
function sandbox_io.gsub(filepath, pattern, replace, opt)

    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- replace all
    local data, count, errors = io.gsub(filepath, pattern, replace, opt)
    if not data then
        raise(errors)
    end

    -- ok
    return data, count
end

-- open file
function sandbox_io.open(filepath, mode, opt)

    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- open it
    local file, errors = io.open(filepath, mode, opt)
    if not file then
        raise(errors)
    end

    -- wrap file
    file = { _FILE = file }

    -- replace print with vformat
    setmetatable(file, sandbox_io_file);

    -- ok?
    return file
end

-- open file lock
function sandbox_io.openlock(filepath)

    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- open lock
    local filelock, errors = io.openlock(filepath)
    if not filelock then
        raise(errors)
    end
    return filelock
end

-- load object from the given file
function sandbox_io.load(filepath, opt)
 
    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- done
    local result, errors = io.load(filepath, opt)
    if not result then
        raise(errors)
    end

    -- ok
    return result
end

-- save object the the given filepath
function sandbox_io.save(filepath, object, opt)

    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- done
    local ok, errors = io.save(filepath, object, opt)
    if not ok then
        raise(errors)
    end
end

-- read all data from file 
function sandbox_io.readfile(filepath, opt)

    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- done
    local result, errors = io.readfile(filepath, opt)
    if not result then
        raise(errors)
    end

    -- ok
    return result
end

--- direct write to stdout
function sandbox_io.write(...)
    sandbox_io.stdout:write(...)
end

--- flush file
function sandbox_io.flush(file)
    return (file or sandbox_io.stdout):flush()
end

-- write all data to file
function sandbox_io.writefile(filepath, data, opt)

    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- done
    local ok, errors = io.writefile(filepath, data, opt)
    if not ok then
        raise(errors)
    end
end

-- print line to file
function sandbox_io.print(filepath, ...)
    sandbox_io.writefile(filepath, vformat(...) .. "\n")
end

-- print string to file
function sandbox_io.printf(filepath, ...)
    sandbox_io.writefile(filepath, vformat(...))
end

-- cat the given file
function sandbox_io.cat(filepath, linecount, opt)

    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- cat it
    io.cat(filepath, linecount, opt)
end

-- tail the given file
function sandbox_io.tail(filepath, linecount, opt)

    -- check
    assert(filepath)

    -- format it first
    filepath = vformat(filepath)

    -- tail it
    io.tail(filepath, linecount, opt)
end

-- wrap std files
sandbox_io.stdin  = { _FILE = io.stdin  }
sandbox_io.stderr = { _FILE = io.stderr }
sandbox_io.stdout = { _FILE = io.stdout }
setmetatable(sandbox_io.stdin, sandbox_io_file);
setmetatable(sandbox_io.stderr, sandbox_io_file);
setmetatable(sandbox_io.stdout, sandbox_io_file);

-- return module
return sandbox_io

