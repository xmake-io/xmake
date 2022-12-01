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

-- define module
local io        = io or {}
local _file     = _file or {}
local _filelock = _filelock or {}

-- load modules
local path      = require("base/path")
local table     = require("base/table")
local string    = require("base/string")
local todisplay = require("base/todisplay")

-- save metatable and builtin functions
io._file        = _file
io._filelock    = _filelock
io._stdfile     = io._stdfile or io.stdfile

-- new a file
function _file.new(filepath, cdata, isstdfile)
    local file = table.inherit(_file)
    file._PATH = isstdfile and filepath or path.absolute(filepath)
    file._FILE = cdata
    setmetatable(file, _file)
    return file
end

-- get the file name
function _file:name()
    if not self._NAME then
        self._NAME = path.filename(self:path())
    end
    return self._NAME
end

-- get the file path
function _file:path()
    return self._PATH
end

-- close file
function _file:close()

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- close file
    ok, errors = io.file_close(self:cdata())
    if ok then
        self._FILE = nil
    end
    return ok, errors
end

-- tostring(file)
function _file:__tostring()
    local str = self:path()
    if #str > 16 then
        str = ".." .. str:sub(#str - 16, #str)
    end
    return "<file: " .. str .. ">"
end

-- todisplay(file)
function _file:__todisplay()
    local size = _file.size(self)
    local filepath = _file.path(self)
    if not size then
        return string.format("file${reset} %s", todisplay(filepath))
    end

    local unit = "B"
    if size >= 1000 then
        size = size / 1024
        unit = "KiB"
    end
    if size >= 1000 then
        size = size / 1024
        unit = "MiB"
    end
    if size >= 1000 then
        size = size / 1024
        unit = "GiB"
    end
    return string.format("file${reset}(${color.dump.number}%.3f%s${reset}) %s", size, unit, todisplay(filepath))
end

-- gc(file)
function _file:__gc()
    if self:cdata() and io.file_close(self:cdata()) then
        -- remove ref to notify gc that it should be freed
        self._FILE = nil
    end
end

-- get file length
function _file:__len()
    return _file.size(self)
end

-- get cdata
function _file:cdata()
    return self._FILE
end

-- get file rawfd
function _file:rawfd()

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return nil, errors
    end

    -- get file rawfd
    local result, errors = io.file_rawfd(self:cdata())
    if not result and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return result, errors
end

-- get file size
function _file:size()

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return nil, errors
    end

    -- get file size
    local result, errors = io.file_size(self:cdata())
    if not result and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return result, errors
end

-- read data from file
--
-- @param fmt       the reading format
-- @param opt       the options
--                  - continuation (concat string with the given continuation characters)
--
function _file:read(fmt, opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return nil, errors
    end

    -- read file
    opt = opt or {}
    local result, errors = io.file_read(self:cdata(), fmt, opt.continuation)
    if errors then
        errors = string.format("%s: %s", self, errors)
    end
    return result, errors
end

-- is readable?
function _file:readable()

    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    return io.file_readable(self:cdata())
end

-- write data to file
function _file:write(...)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- data items
    local items = table.pack(...)
    for idx, item in ipairs(items) do
        if type(item) == "table" and item.caddr and item.size then
            -- write bytes
            items[idx] = {data = item:caddr(), size = item:size()}
        end
    end

    -- write file
    ok, errors = io.file_write(self:cdata(), table.unpack(items))
    if not ok and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return ok, errors
end

-- seek offset at file
function _file:seek(whence, offset)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- seek file
    local result, errors = io.file_seek(self:cdata(), whence, offset)
    if not result and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return result, errors
end

-- flush data to file
function _file:flush()

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- flush file
    ok, errors = io.file_flush(self:cdata())
    if not ok and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return ok, errors
end

-- this file is a tty?
function _file:isatty()

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return nil, errors
    end

    -- is a tty?
    ok, errors = io.file_isatty(self:cdata())
    if ok == nil and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return ok, errors
end

-- ensure the file is opened
function _file:_ensure_opened()
    if not self:cdata() then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

-- read all lines from file
function _file:lines(opt)
    opt = opt or {}
    return function()
        local l = _file.read(self, "l", opt)
        if not l and opt.close_on_finished then
            _file.close(self)
        end
        return l
    end
end

-- print file
function _file:print(...)
    return _file.write(self, string.format(...), "\n")
end

-- printf file
function _file:printf(...)
    return _file.write(self, string.format(...))
end

-- save object
function _file:save(object, opt)
    local str, errors = string.serialize(object, opt)
    if errors then
        return false, errors
    else
        return _file.write(self, str)
    end
end

-- load object
function _file:load()
    local data, err = _file.read(self, "*all")
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
    filelock._PATH = path.absolute(lockpath)
    filelock._LOCK = lock
    filelock._LOCKED_NUM = 0
    setmetatable(filelock, _filelock)
    return filelock
end

-- get the filelock name
function _filelock:name()
    if not self._NAME then
        self._NAME = path.filename(self:path())
    end
    return self._NAME
end

-- get the filelock path
function _filelock:path()
    return self._PATH
end

-- get the cdata
function _filelock:cdata()
    return self._LOCK
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

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- lock it
    if self._LOCKED_NUM > 0 or io.filelock_lock(self:cdata(), opt) then
        self._LOCKED_NUM = self._LOCKED_NUM + 1
        return true
    else
        return false, string.format("%s: lock failed!", self)
    end
end

-- try to lock file
--
-- @param opt       the argument option, {shared = true}
--
-- @return          ok, errors
--
function _filelock:trylock(opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- try lock it
    if self._LOCKED_NUM > 0 or io.filelock_trylock(self:cdata(), opt) then
        self._LOCKED_NUM = self._LOCKED_NUM + 1
        return true
    else
        return false, string.format("%s: trylock failed!", self)
    end
end

-- unlock file
function _filelock:unlock(opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- unlock it
    if self._LOCKED_NUM > 1 or (self._LOCKED_NUM > 0 and io.filelock_unlock(self:cdata())) then
        if self._LOCKED_NUM > 0 then
            self._LOCKED_NUM = self._LOCKED_NUM - 1
        else
            self._LOCKED_NUM = 0
        end
        return true
    else
        return false, string.format("%s: unlock failed!", self)
    end
end

-- close filelock
function _filelock:close()

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- close it
    ok = io.filelock_close(self:cdata())
    if ok then
        self._LOCK = nil
        self._LOCKED_NUM = 0
    end
    return ok
end

-- ensure the file is opened
function _filelock:_ensure_opened()
    if not self:cdata() then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

-- tostring(filelock)
function _filelock:__tostring()
    local str = _filelock.path(self)
    if #str > 16 then
        str = ".." .. str:sub(#str - 16, #str)
    end
    return "<filelock: " .. str .. ">"
end

-- todisplay(filelock)
function _filelock:__todisplay()
    local str = _filelock.path(self)
    return "filelock${reset} " .. todisplay(str)
end

-- gc(filelock)
function _filelock:__gc()
    if self:cdata() and io.filelock_close(self:cdata()) then
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
    local file, errors = io.open(tostring(filepath), "r", opt)
    if not file then
        return nil, errors
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

function io.readable()
    return io.stdin:readable()
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
    local file, errors = io.open(tostring(filepath), "w", opt)
    if not file then
        return false, errors
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
        return _file.new(filepath, file, true)
    else
        return nil, string.format("failed to get std file: %s", filepath)
    end
end

-- open file
--
-- @param filepath      the file path
-- @param mode          the open mode, e.g. 'r', 'rb', 'w+', 'a+', ..
-- @param opt           the options
--                      - encoding, e.g. utf8, utf16, utf16le, utf16be ..
--
function io.open(filepath, mode, opt)

    -- check
    assert(filepath)

    -- init option and mode
    opt  = opt or {}
    mode = mode or "r"

    -- open it
    filepath = tostring(filepath)
    local file = io.file_open(filepath, mode .. (opt.encoding or ""))
    if file then
        return _file.new(filepath, file)
    else
        return nil, string.format("cannot open file: %s, %s", filepath, os.strerror())
    end
end

-- open a filelock
function io.openlock(filepath)

    -- check
    assert(filepath)

    -- open it
    filepath = tostring(filepath)
    local lock = io.filelock_open(filepath)
    if lock then
        return _filelock.new(filepath, lock)
    else
        return nil, string.format("cannot open lock: %s, %s", filepath, os.strerror())
    end
end

-- close file
function io.close(file)
    return (file or io.stdout):close()
end

-- save object the the given filepath
function io.save(filepath, object, opt)
    assert(filepath and object)

    opt = opt or {}
    filepath = tostring(filepath)
    local file, err = io.open(filepath, "wb", opt)
    if err then
        return false, err
    end

    local ok, errors = file:save(object, opt)
    file:close()
    if not ok then
        return false, string.format("save %s failed, %s!", filepath, errors)
    end
    return true
end

-- load object from the given file
function io.load(filepath, opt)
    assert(filepath)

    opt = opt or {}
    filepath = tostring(filepath)
    local file, err = io.open(filepath, "rb", opt)
    if err then
        return nil, err
    end
    local result, errors = file:load()
    file:close()
    return result, errors
end

-- gsub the given file and return replaced data
function io.gsub(filepath, pattern, replace, opt)

    -- read all data from file
    opt = opt or {}
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
    return data, count
end

-- replace text of the given file and return new file data
function io.replace(filepath, pattern, replace, opt)
    opt = opt or {}
    local data, errors = io.readfile(filepath, opt)
    if not data then return nil, 0, errors end

    local count = 0
    if type(data) == "string" then
        data, count = data:replace(pattern, replace, opt)
    else
        return nil, 0, string.format("data is not string!")
    end
    if count ~= 0 then
        local ok, errors = io.writefile(filepath, data, opt)
        if not ok then return nil, 0, errors end
    end
    return data, count
end

-- insert text before line number in the given file and return new file data
function io.insert(filepath, lineidx, text, opt)
    opt = opt or {}
    local data, errors = io.readfile(filepath, opt)
    if not data then return nil, errors end

    local newdata
    if type(data) == "string" then
        newdata = {}
        for idx, line in ipairs(data:split("\n")) do
            if idx == lineidx then
                table.insert(newdata, text)
            end
            table.insert(newdata, line)
        end
    else
        return nil, string.format("data is not string!")
    end
    if newdata and #newdata > 0 then
        local rn = data:find("\r\n", 1, true)
        data = table.concat(newdata, rn and "\r\n" or "\n")
        local ok, errors = io.writefile(filepath, data, opt)
        if not ok then return nil, errors end
    end
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
            io.write(line, "\n")

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
