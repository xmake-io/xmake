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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        pipe.lua
--

-- define module
local pipe      = pipe or {}
local _instance = _instance or {}

-- load modules
local io        = require("base/io")
local bytes     = require("base/bytes")
local table     = require("base/table")
local string    = require("base/string")
local scheduler = require("base/scheduler")

-- the pipe events, @see tbox/platform/pipe.h
pipe.EV_READ  = 1
pipe.EV_WRITE = 2
pipe.EV_CONN  = 2

-- new a pipe file
function _instance.new(cdata, name)
    local pipefile = table.inherit(_instance)
    pipefile._NAME = name
    pipefile._PIPE = cdata
    setmetatable(pipefile, _instance)
    return pipefile
end

-- get the pipe name
function _instance:name()
    return self._NAME
end

-- get poller object type, poller.OT_PIPE
function _instance:otype()
    return 2
end

-- get cdata of pipe file
function _instance:cdata()
    return self._PIPE
end

-- write data to pipe file
function _instance:write(data, opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- data is bytes? unpack the raw address
    local datasize = #data
    if type(data) == "table" and data.caddr then
        datasize = data:size()
        data = {data = data:caddr(), size = data:size()}
    end

    -- init start and last
    opt = opt or {}
    local start = opt.start or 1
    local last = opt.last or datasize

    -- check start and last
    if start > last or start < 1 then
        return -1, string.format("%s: invalid start(%d) and last(%d)!", self, start, last)
    end

    -- write it
    local write = 0
    local real = 0
    local errors = nil
    if opt.block then
        local size = last + 1 - start
        while start <= last do
            real, errors = io.pipe_write(self:cdata(), data, start, last)
            if real > 0 then
                write = write + real
                start = start + real
            elseif real == 0 then
                local events, waiterrs = _instance.wait(self, pipe.EV_WRITE, opt.timeout or -1)
                if events ~= pipe.EV_WRITE then
                    errors = waiterrs
                    break
                end
            else
                break
            end
        end
        if write ~= size then
            write = -1
        end
    else
        write, errors = io.pipe_write(self:cdata(), data, start, last)
        if write < 0 and errors then
            errors = string.format("%s: %s", self, errors)
        end
    end
    return write, errors
end

-- read data from pipe
function _instance:read(size, opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- check size
    if size == 0 then
        return 0
    elseif size == nil or size < 0 then
        return -1, string.format("%s: invalid size(%d)!", self, size)
    end

    -- read it
    opt = opt or {}
    local read = 0
    local real = 0
    local data_or_errors = nil
    if opt.block then
        local results = {}
        while read < size do
            local buff = self:_readbuff()
            real, data_or_errors = io.pipe_read(self:cdata(), buff:caddr(), math.min(buff:size(), size - read))
            if real > 0 then
                read = read + real
                table.insert(results, bytes(buff, 1, real))
                self:_readbuff_clear()
            elseif real == 0 then
                local events, waiterrs = _instance.wait(self, pipe.EV_READ, opt.timeout or -1)
                if events ~= pipe.EV_READ then
                    data_or_errors = waiterrs
                    break
                end
            else
                break
            end
        end
        if read == size then
            data_or_errors = bytes(results)
        else
            read = -1
        end
    else
        local buff = self:_readbuff()
        read, data_or_errors = io.pipe_read(self:cdata(), buff:caddr(), math.min(buff:size(), size))
        if read > 0 then
            data_or_errors = bytes(buff, 1, read)
            self:_readbuff_clear()
        end
    end
    if read < 0 and data_or_errors then
        data_or_errors = string.format("%s: %s", self, data_or_errors)
    end
    return read, data_or_errors
end

-- connect pipe, only for named pipe (server-side)
function _instance:connect(opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- only for named pipe
    if not self:name() then
        return -1, string.format("%s: cannot connect to anonymous pipe!", self)
    end

    -- connect it
    local ok, errors = io.pipe_connect(self:cdata())
    if ok == 0 then
        opt = opt or {}
        local events, waiterrs = _instance.wait(self, pipe.EV_CONN, opt.timeout or -1)
        if events == pipe.EV_CONN then
            ok, errors = io.pipe_connect(self:cdata())
        else
            errors = waiterrs
        end
    end
    if ok < 0 and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return ok, errors
end

-- wait pipe events
function _instance:wait(events, timeout)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- wait events
    local result = -1
    local errors = nil
    if scheduler:co_running() then
        result, errors = scheduler:poller_wait(self, events, timeout or -1)
    else
        result, errors = io.pipe_wait(self:cdata(), events, timeout or -1)
    end
    if result < 0 and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return result, errors
end

-- close pipe file
function _instance:close()

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- cancel pipe events from the scheduler
    if scheduler:co_running() then
        ok, errors = scheduler:poller_cancel(self)
        if not ok then
            return false, errors
        end
    end

    -- close it
    ok = io.pipe_close(self:cdata())
    if ok then
        self._PIPE = nil
    end
    return ok
end

-- get the read buffer
function _instance:_readbuff()
    local readbuff = self._READBUFF
    if not readbuff then
        readbuff = bytes(8192)
        self._READBUFF = readbuff
    end
    return readbuff
end

-- clear the read buffer
function _instance:_readbuff_clear()
    self._READBUFF = nil
end

-- ensure the pipe is opened
function _instance:_ensure_opened()
    if not self:cdata() then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

-- tostring(pipe)
function _instance:__tostring()
    return "<pipe: " .. (self:name() or "anonymous") .. ">"
end

-- gc(pipe)
function _instance:__gc()
    if self:cdata() and io.pipe_close(self:cdata()) then
        self._PIPE = nil
    end
end

-- open a named pipe file
--
-- 1. named pipe (server-side):
--
-- local pipe, errors = pipe.open("xxx", 'w')
-- if pipe then
--    if pipe:connect() then
--        pipe:write(...)
--    end
--    pipe:close()
-- end
--
-- 2. named pipe (client-side):
--
-- local pipe, errors = pipe.open("xxx")
-- if pipe then
--    pipe:read(...)
--    pipe:close()
-- end
--
function pipe.open(name, mode, buffsize)

    -- open named pipe
    local pipefile, errors = io.pipe_open(name, mode, buffsize or 0)
    if pipefile then
        return _instance.new(pipefile, name)
    else
        return nil, string.format("failed to open pipe: %s, %s", name, errors or "unknown reason")
    end
end

-- open anonymous pipe pair
--
-- local rpipe, wpipe, errors = pipe.openpair()
-- rpipe:read(...)
-- wpipe:write(...)
--
function pipe.openpair(buffsize)

    -- open anonymous pipe pair
    local rpipefile, wpipefile, errors = io.pipe_openpair(buffsize or 0)
    if rpipefile and wpipefile then
        return _instance.new(rpipefile), _instance.new(wpipefile)
    else
        return nil, nil, string.format("failed to open anonymous pipe pair, %s", errors or "unknown reason")
    end
end

-- return module
return pipe
