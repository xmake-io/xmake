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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
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
local sandbox_io_file     = sandbox_io_file or {}
local sandbox_io_filelock = sandbox_io_filelock or {}
sandbox_io.lines          = io.lines

-- get file size
function sandbox_io_file.size(file)
    local result, errors = file:_size()
    if not result then
        raise(errors)
    end
    return result
end

-- get file rawfd
function sandbox_io_file.rawfd(file)
    local result, errors = file:_rawfd()
    if not result then
        raise(errors)
    end
    return result
end

-- close file
function sandbox_io_file.close(file)
    local ok, errors = file:_close()
    if not ok then
        raise(errors)
    end
    return ok
end

-- flush file
function sandbox_io_file.flush(file)
    local ok, errors = file:_flush()
    if not ok then
        raise(errors)
    end
    return ok
end

-- this file is a tty?
function sandbox_io_file.isatty(file)
    local ok, errors = file:_isatty()
    if ok == nil then
        raise(errors)
    end
    return ok
end

-- seek offset at file
function sandbox_io_file.seek(file, whence, offset)
    local result, errors = file:_seek(whence, offset)
    if not result then
        raise(errors)
    end
    return result
end

-- read data from file
function sandbox_io_file.read(file, fmt, opt)
    local result, errors = file:_read(fmt, opt)
    if errors then
        raise(errors)
    end
    return result
end

-- readable for file
function sandbox_io_file.readable(file)
    local ok, errors = file:_readable()
    if errors then
        raise(errors)
    end
    return ok
end

-- write data to file
function sandbox_io_file.write(file, ...)
    local ok, errors = file:_write(...)
    if not ok then
        raise(errors)
    end
end

-- print file
function sandbox_io_file.print(file, ...)
    sandbox_io_file.write(file, vformat(...), "\n")
end

-- printf file
function sandbox_io_file.printf(file, ...)
    sandbox_io_file.write(file, vformat(...))
end

-- writef file (without value filter)
function sandbox_io_file.writef(file, ...)
    sandbox_io_file.write(file, string.format(...))
end

-- load object from file
function sandbox_io_file.load(file)
    local result, errors = file:_load()
    if errors then
        raise(errors)
    end
    return result
end

-- save object to file
function sandbox_io_file.save(file, object, opt)
    local ok, errors = file:_save(object, opt)
    if not ok then
        raise(errors)
    end
    return ok
end

-- lock filelock
function sandbox_io_filelock.lock(lock, opt)
    local ok, errors = lock:_lock(opt)
    if not ok then
        raise(errors)
    end
end

-- unlock filelock
function sandbox_io_filelock.unlock(lock)
    local ok, errors = lock:_unlock()
    if not ok then
        raise(errors)
    end
end

-- close filelock
function sandbox_io_filelock.close(lock)
    local ok, errors = lock:_close()
    if not ok then
        raise(errors)
    end
end

-- gsub the given file and return replaced data
function sandbox_io.gsub(filepath, pattern, replace, opt)
    assert(filepath)
    filepath = vformat(filepath)
    local data, count, errors = io.gsub(filepath, pattern, replace, opt)
    if not data then
        raise(errors)
    end
    return data, count
end

-- replace text of the given file and return new data
function sandbox_io.replace(filepath, pattern, replace, opt)
    assert(filepath)
    filepath = vformat(filepath)
    local data, count, errors = io.replace(filepath, pattern, replace, opt)
    if not data then
        raise(errors)
    end
    return data, count
end

-- insert text before line number in the given file and return new data
function sandbox_io.insert(filepath, lineidx, text, opt)
    assert(filepath)
    filepath = vformat(filepath)
    local data, errors = io.insert(filepath, lineidx, text, opt)
    if not data then
        raise(errors)
    end
    return data
end

-- get std file
function sandbox_io.stdfile(filepath)
    assert(filepath)
    local file, errors = io.stdfile(filepath)
    if not file then
        raise(errors)
    end

    -- hook file interfaces
    local hooked = {}
    for name, func in pairs(sandbox_io_file) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = file["_" .. name] or file[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        file[name] = func
    end
    return file
end

-- open file
function sandbox_io.open(filepath, mode, opt)
    assert(filepath)
    filepath = vformat(filepath)
    local file, errors = io.open(filepath, mode, opt)
    if not file then
        raise(errors)
    end

    -- hook file interfaces
    local hooked = {}
    for name, func in pairs(sandbox_io_file) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = file["_" .. name] or file[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        file[name] = func
    end
    return file
end

-- open file lock
function sandbox_io.openlock(filepath)
    assert(filepath)
    filepath = vformat(filepath)
    local lock, errors = io.openlock(filepath)
    if not lock then
        raise(errors)
    end

    -- hook filelock interfaces
    local hooked = {}
    for name, func in pairs(sandbox_io_filelock) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = lock["_" .. name] or lock[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        lock[name] = func
    end
    return lock
end

-- load object from the given file
function sandbox_io.load(filepath, opt)
    assert(filepath)
    filepath = vformat(filepath)
    local result, errors = io.load(filepath, opt)
    if errors ~= nil then
        raise(errors)
    end
    return result
end

-- save object the the given filepath
function sandbox_io.save(filepath, object, opt)
    assert(filepath)
    filepath = vformat(filepath)
    local ok, errors = io.save(filepath, object, opt)
    if not ok then
        raise(errors)
    end
end

-- read all data from file
function sandbox_io.readfile(filepath, opt)
    assert(filepath)
    filepath = vformat(filepath)
    local result, errors = io.readfile(filepath, opt)
    if not result then
        raise(errors)
    end
    return result
end

-- direct read from stdin
function sandbox_io.read(fmt, opt)
    return sandbox_io.stdin:read(fmt, opt)
end

-- has readable for stdin?
function sandbox_io.readable()
    return sandbox_io.stdin:readable()
end

-- direct write to stdout
function sandbox_io.write(...)
    sandbox_io.stdout:write(...)
end

--- flush file
function sandbox_io.flush(file)
    return (file or sandbox_io.stdout):flush()
end

-- isatty
function sandbox_io.isatty(file)
    file = file or sandbox_io.stdout
    return file:isatty()
end

-- write all data to file
function sandbox_io.writefile(filepath, data, opt)
    assert(filepath)
    filepath = vformat(filepath)
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
    assert(filepath)
    filepath = vformat(filepath)
    io.cat(filepath, linecount, opt)
end

-- tail the given file
function sandbox_io.tail(filepath, linecount, opt)
    assert(filepath)
    filepath = vformat(filepath)
    io.tail(filepath, linecount, opt)
end

-- lazy loading stdfile
setmetatable(sandbox_io, { __index = function (tbl, key)
        local val = rawget(tbl, key)
        if val == nil and (key == "stdin" or key == "stdout" or key == "stderr") then
            val = sandbox_io.stdfile("/dev/" .. key)
            if val ~= nil then
                rawset(tbl, key, val)
            end
        end
        return val
    end})

-- return module
return sandbox_io

