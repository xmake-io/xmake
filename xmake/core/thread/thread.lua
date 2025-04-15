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
-- @file        thread.lua
--

-- define module
local thread      = thread or {}
local _instance   = _instance or {}

-- load modules
local io        = require("base/io")
local libc      = require("base/libc")
local bytes     = require("base/bytes")
local table     = require("base/table")
local string    = require("base/string")

-- the thread status
thread.STATUS_READY     = 1
thread.STATUS_RUNNING   = 2
thread.STATUS_SUSPENDED = 3
thread.STATUS_DEAD      = 4

-- new a thread
function _instance.new(name, callback, handle, opt)
    local instance   = table.inherit(_instance)
    instance._NAME   = name or "anonymous"
    instance._HANLDE = handler
    instance._STATUS = thread.STATUS_READY
    setmetatable(instance, _instance)
    return instance
end

-- get thread name
function _instance:name()
    return self._NAME
end

-- get cdata of thread
function _instance:cdata()
    return self._HANLDE
end

-- get thread status
function _instance:status()
    return self._STATUS
end

-- is ready?
function _instance:is_ready()
    return self:status() == thread.STATUS_READY
end

-- is running?
function _instance:is_running()
    return self:status() == thread.STATUS_RUNNING
end

-- is suspended?
function _instance:is_suspended()
    return self:status() == thread.STATUS_SUSPENDED
end

-- is dead?
function _instance:is_dead()
    return self:status() == thread.STATUS_DEAD
end

-- start thread
function _instance:start(instance)
end

-- suspend thread
function _instance:suspend(instance)
end

-- resume thread
function _instance:resume(instance)
end

-- wait thread
function _instance:wait(instance, timeout)
end

-- tostring(thread)
function _instance:__tostring()
    local status_strs = self._STATUS_STRS
    if not status_strs then
        status_strs = {
            [thread.STATUS_READY]     = "ready",
            [thread.STATUS_RUNNING]   = "running",
            [thread.STATUS_SUSPENDED] = "suspended",
            [thread.STATUS_DEAD]      = "dead"
        }
        self._STATUS_STRS = status_strs
    end
    return string.format("<thread: %s/%s>", self:name(), status_strs[self:status()])
end

-- gc(thread)
function _instance:__gc()
    if self:cdata() and self:is_dead() and io.thread_close(self:cdata()) then
        self._HANLDE = nil
    end
end

-- new a thread
--
-- @param callback      the thread callback
-- @param opt           the thread options, e.g. {name = "", argv = {}, stacksize = 8192}
--
-- @return the thread instance
--
function thread.new(callback, opt)
    opt = opt or {}
    local name = opt.name
    local argv = opt.argv
    local stacksize = opt.stacksize
    local handle, errors = thread.thread_create(name, callback, argv, stacksize)
    if handle then
        return _instance.new(name, callback, handle, opt)
    else
        return nil, errors or string.format("failed to create thread(%s)!", name)
    end
end

-- get the running thread
function thread.running()
end

-- return module
return thread

