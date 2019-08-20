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
local io        = io or {}
local _file     = _file or {}
local _filelock = _filelock or {}

-- load modules
local path   = require("base/path")
local table  = require("base/table")
local string = require("base/string")

-- save metatable and builtin functions
io._file        = _file
io._filelock    = _filelock
io._stdfile     = io._stdfile or io.stdfile

-- new an file
function _file.new(filepath, fileref)
    local file = table.inherit(_file)
    file._NAME = path.filename(filepath)
    file._PATH = path.absolute(filepath)
    file._FILE = fileref
    setmetatable(file, _file)
    return file
end

-- get the file name 
function _file:name()
    return self._NAME
end

-- get the file path 
function _file:path()
    return self._PATH
end

-- close file
function _file:close()
    if not self._FILE then
        return false, string.format("file(%s) has been closed!", self:name())
    end
    local ok, errors = io.file_close(self._FILE)
    if ok then
        self._FILE = nil
    end
    return ok, errors
end

-- tostring(file)
function _file:__tostring()
    return "file: " .. self:name()
end

-- gc(file)
function _file:__gc()
    if self._FILE and io.file_close(self._FILE) then
        self._FILE = nil
    end
end

-- get file length
function _file:__len()
    return self:size()
end

-- get file rawfd
function _file:rawfd()
    if not self._FILE then
        return false, string.format("file(%s) has been closed!", self:name())
    end
    local result, errors = io.file_rawfd(self._FILE)
    if not result and errors then
        errors = string.format("file(%s): %s", self:name(), errors)
    end
    return result, errors
end

-- get file size
function _file:size()
    if not self._FILE then
        return false, string.format("file(%s) has been closed!", self:name())
    end
    local result, errors = io.file_size(self._FILE)
    if not result and errors then
        errors = string.format("file(%s): %s", self:name(), errors)
    end
    return result, errors
end

-- read data from file
function _file:read(fmt, opt)
    if not self._FILE then
        return false, string.format("file(%s) has been closed!", self:name())
    end
    opt = opt or {}
    local result, errors = io.file_read(self._FILE, fmt, opt.continuation)
    if errors then
        errors = string.format("file(%s): %s", self:name(), errors)
    end
    return result, errors
end

-- write data to file
function _file:write(...)
    if not self._FILE then
        return false, string.format("file(%s) has been closed!", self:name())
    end
    local ok, errors = io.file_write(self._FILE, ...)
    if not ok and errors then
        errors = string.format("file(%s): %s", self:name(), errors)
    end
    return ok, errors
end

-- seek offset at file
function _file:seek(whence, offset)
    if not self._FILE then
        return false, string.format("file(%s) has been closed!", self:name())
    end
    local result, errors = io.file_seek(self._FILE, whence, offset)
    if not result and errors then
        errors = string.format("file(%s): %s", self:name(), errors)
    end
    return result, errors
end

-- flush data to file
function _file:flush()
    if not self._FILE then
        return false, string.format("file(%s) has been closed!", self:name())
    end
    local ok, errors = io.file_flush(self._FILE)
    if not ok and errors then
        errors = string.format("file(%s): %s", self:name(), errors)
    end
    return ok, errors
end

-- this file is a tty?
function _file:isatty()
    if not self._FILE then
        return false, string.format("file(%s) has been closed!", self:name())
    end
    local ok, errors = io.file_isatty(self._FILE)
    if ok == nil and errors then
        errors = string.format("file(%s): %s", self:name(), errors)
    end
    return ok, errors
end

-- iterator of lines
function _file._lines_iter(data)
    local l = data.file:read("l", data.opt)
    if not l and data.opt.close_on_finished then
        data.file:close()
    end
    return l
end

-- read all lines from a file
function _file:lines(opt)
    return _file._lines_iter, { file = assert(self), opt = opt or {} }
end

-- print file
function _file:print(...)
    return self:write(string.format(...), "\n")
end

-- printf file
function _file:printf(...)
    return self:write(string.format(...))
end

-- save object
function _file:save(object, opt)
    local str, errors = string.serialize(object, opt)
    if errors then
        return false, errors
    else
        return self:write(str)
    end
end

-- load object
function _file:load()
    local data, err = self:read("*all")
    if err then
        return nil, err
    end
    if data and type(data) == "string" then
        return data:deserialize()
    end
end

-- new an filelock
function _filelock.new(lockpath, lock)
    local filelock = table.inherit(_filelock)
    filelock._NAME = path.filename(lockpath)
    filelock._PATH = path.absolute(lockpath)
    filelock._LOCK = lock
    filelock._LOCKED_NUM = 0
    setmetatable(filelock, _filelock)
    return filelock
end

-- get the filelock name 
function _filelock:name()
    return self._NAME
end

-- get the filelock path 
function _filelock:path()
    return self._PATH
end

-- is locked?
function _filelock:islocked()
    return self._LOCKED_NUM > 0
end

-- lock file
--
-- @param opt       the argument option, {shared = true}
--
-- @return          ok, errors
--
function _filelock:lock(opt)
    if not self._LOCK then
        return false, string.format("filelock(%s) has been closed!", self:name())
    end
    if self._LOCKED_NUM > 0 or io.filelock_lock(self._LOCK, opt) then
        self._LOCKED_NUM = self._LOCKED_NUM + 1
        return true
    else
        return false, string.format("filelock(%s): lock %s failed!", self:name(), self:path())
    end
end

-- try to lock file
--
-- @param opt       the argument option, {shared = true}
--
-- @return          ok, errors
--
function _filelock:trylock(opt)
    if not self._LOCK then
        return false, string.format("filelock(%s) has been closed!", self:name())
    end
    if self._LOCKED_NUM > 0 or io.filelock_trylock(self._LOCK, opt) then
        self._LOCKED_NUM = self._LOCKED_NUM + 1
        return true
    else
        return false, string.format("filelock(%s): trylock %s failed!", self:name(), self:path())
    end
end

-- unlock file
function _filelock:unlock(opt)
    if not self._LOCK then
        return false, string.format("filelock(%s) has been closed!", self:name())
    end
    if self._LOCKED_NUM > 1 or (self._LOCKED_NUM > 0 and io.filelock_unlock(self._LOCK)) then
        if self._LOCKED_NUM > 0 then
            self._LOCKED_NUM = self._LOCKED_NUM - 1
        else 
            self._LOCKED_NUM = 0
        end
        return true
    else
        return false, string.format("filelock(%s): unlock %s failed!", self:name(), self:path())
    end
end

-- close filelock
function _filelock:close()
    if not self._LOCK then
        return false, string.format("filelock(%s) has been closed!", self:name())
    end
    local ok = io.filelock_close(self._LOCK)
    if ok then
        self._LOCK = nil
        self._LOCKED_NUM = 0
    end
    return ok
end

-- tostring(filelock)
function _filelock:__tostring()
    return "filelock: " .. self:name()
end

-- gc(filelock)
function _filelock:__gc()
    if self._LOCK and io.filelock_close(self._LOCK) then
        self._LOCK = nil
        self._LOCKED_NUM = 0
    end
end

-- read all lines from file
function io.lines(filepath, opt)

    -- close on finished
    opt = opt or {}
    if opt.close_on_finished == nil then
        opt.close_on_finished = true
    end

    -- open file
    local file = io.open(filepath, "r", opt)
    if not file then
        return function() return nil end
    end

    return file:lines(opt)
end

-- read all data from file
function io.readfile(filepath, opt)

    opt = opt or {}

    -- open file
    local file = io.open(filepath, "r", opt)
    if not file then
        -- error
        return nil, string.format("open %s failed!", filepath)
    end

    -- read all
    local data, err = file:read("*all", opt)

    -- exit file
    file:close()

    -- ok?
    return data, err
end

function io.read(fmt, opt)
    return io.stdin:read(fmt, opt)
end

function io.write(...)
    return io.stdout:write(...)
end

function io.print(...)
    return io.stdout:print(...)
end

function io.printf(...)
    return io.stdout:printf(...)
end

function io.flush()
    return io.stdout:flush()
end

-- write data to file
function io.writefile(filepath, data, opt)

    -- init option
    opt = opt or {}

    -- open file
    local file = io.open(filepath, "w", opt)
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

-- isatty
function io.isatty(file)
    file = file or io.stdout
    return file:isatty()
end

-- get std file, /dev/stdin, /dev/stdout, /dev/stderr
function io.stdfile(filepath)
    local file = nil
    if filepath == "/dev/stdin" then
        file = io._stdfile(1)
    elseif filepath == "/dev/stdout" then
        file = io._stdfile(2)
    elseif filepath == "/dev/stderr" then
        file = io._stdfile(3)
    end
    if file then
        return _file.new(filepath, file)
    else
        return nil, string.format("failed to get std file: %s", filepath)
    end
end

-- open file
function io.open(filepath, mode, opt)

    -- check
    assert(filepath)

    -- init option and mode
    opt  = opt or {}
    mode = mode or "r"

    -- open it
    local file = io.file_open(filepath, mode .. (opt.encoding or ""))
    if file then
        return _file.new(filepath, file)
    else
        return nil, string.format("failed to open file: %s", filepath)
    end
end

-- open a filelock
function io.openlock(filepath)

    -- check
    assert(filepath)

    -- open it
    local lock = io.filelock_open(filepath)
    if lock then
        return _filelock.new(filepath, lock)
    else
        return nil, string.format("failed to open lock: %s", filepath)
    end
end

-- close file
function io.close(file)
    return (file or io.stdout):close()
end

-- save object the the given filepath
function io.save(filepath, object, opt)

    -- check
    assert(filepath and object)

    -- init option
    opt = opt or {}

    -- open the file
    local file, err = io.open(filepath, "wb", opt)
    if err then
        -- error
        return false, err
    end

    -- save object to file
    local ok, errors = file:save(object, opt)
    -- close file
    file:close()
    if not ok then
        -- error
        return false, string.format("save %s failed, %s!", filepath, errors)
    end

    -- ok
    return true
end

-- load object from the given file
function io.load(filepath, opt)

    -- check
    assert(filepath)

    -- init option
    opt = opt or {}

    -- open the file
    local file, err = io.open(filepath, "rb", opt)
    if err then
        -- error
        return nil, err
    end

    -- load object
    local result, errors = file:load()

    -- close file
    file:close()

    -- ok?
    return result, errors
end

-- gsub the given file and return replaced data
function io.gsub(filepath, pattern, replace, opt)

    -- init option
    opt = opt or {}

    -- read all data from file
    local data, errors = io.readfile(filepath, opt)
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
        local ok, errors = io.writefile(filepath, data, opt)
        if not ok then return nil, 0, errors end
    end

    -- ok
    return data, count
end

-- cat the given file
function io.cat(filepath, linecount, opt)

    -- init option
    opt = opt or {}

    -- open file
    local file = io.open(filepath, "r", opt)
    if file then

        -- show file
        local count = 1
        for line in file:lines(opt) do

            -- show line
            io.print(line)

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
function io.tail(filepath, linecount, opt)

    -- init option
    opt = opt or {}

    -- all?
    if linecount < 0 then
        return io.cat(filepath, opt)
    end

    -- open file
    local file = io.open(filepath, "r", opt)
    if file then

        -- read lines
        local lines = {}
        for line in file:lines(opt) do
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
                io.print(tails[index])

            end
        end

        -- exit file
        file:close()
    end
end

-- lazy loading stdfile
io.stdin  = nil
io.stdout = nil
io.stderr = nil
setmetatable(io, { __index = function (tbl, key)    
        local val = rawget(tbl, key)
        if val == nil and (key == "stdin" or key == "stdout" or key == "stderr") then
            val = io.stdfile("/dev/" .. key)
            if val ~= nil then
                rawset(tbl, key, val)
            end
        end
        return val
    end})

-- return module
return io
