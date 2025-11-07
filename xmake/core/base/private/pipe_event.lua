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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        pipe_event.lua
--

-- define module
local pipe_event = pipe_event or {}
local _instance = _instance or {}

-- load modules
local pipe   = require("base/pipe")
local libc   = require("base/libc")
local bytes  = require("base/bytes")
local table  = require("base/table")

function _instance.new(name)
    local event = table.inherit(_instance)
    event._PIPE_EVENT = true
    event._BUFFER = bytes(2)
    event._NAME = name or "pipe_event"
    local reader, writer, errors = pipe.openpair("BA")
    if not reader or not writer then
        if reader then reader:close() end
        if writer then writer:close() end
        return nil, errors or "failed to open pipe"
    end
    event._READER = reader
    event._WRITER = writer
    event._WRITER_PTR = nil
    return event
end

function _instance:name()
    return self._NAME
end

function _instance:post()
    local writer = self._WRITER
    if not writer then
        return false, "pipe event writer closed"
    end
    local ok, errors = writer:write("1")
    if ok < 0 then
        return false, errors or "pipe event post failed"
    end
    writer:close()
    self._WRITER = nil
    self._WRITER_PTR = nil
    return true
end

function _instance:wait(timeout)
    if not self._READER then
        return false, "pipe event reader closed"
    end
    local events, errors = self._READER:wait(pipe.EV_READ, timeout or -1)
    if events < 0 then
        return false, errors
    end
    local read, read_errors = self._READER:read(self._BUFFER, 1)
    if read < 0 then
        return false, read_errors
    end
    return read
end

function _instance:close()
    if self._READER then
        self._READER:close()
    end
    if self._WRITER then
        self._WRITER:close()
    end
    self._READER = nil
    self._WRITER = nil
    self._WRITER_PTR = nil
end

-- return pipe cdata for serialization (writer pointer is stable for passing across threads)
function _instance:cdata()
    if self._WRITER then
        return self._WRITER:cdata()
    end
    return self._WRITER_PTR
end

function _instance:__gc()
    self:close()
end

function _instance:_serialize()
    if not self._WRITER and self._WRITER_PTR then
        return {ptr = self._WRITER_PTR, name = self:name()}
    end
    if not self._WRITER then
        return nil
    end
    local ptr = libc.dataptr(self._WRITER:cdata(), {ffi = false})
    if not ptr then
        return nil
    end
    self._WRITER._PIPE = nil
    self._WRITER = nil
    self._WRITER_PTR = ptr
    return {ptr = ptr, name = self:name()}
end

function _instance:_deserialize(data)
    if not data or not data.ptr then
        return false, "invalid pipe event data"
    end
    self:close()
    local writer = pipe.new(libc.ptraddr(data.ptr, {ffi = false}))
    if not writer then
        return false, "invalid pipe pointer"
    end
    self._NAME = data.name or self._NAME or "pipe_event"
    self._WRITER = writer
    self._WRITER_PTR = data.ptr
    return true
end

function pipe_event.new(name)
    return _instance.new(name)
end

return pipe_event


