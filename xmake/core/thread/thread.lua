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
local io      = require("base/io")
local libc    = require("base/libc")
local bytes   = require("base/bytes")
local table   = require("base/table")
local string  = require("base/string")
local sandbox = require("sandbox/sandbox")

-- the thread status
thread.STATUS_READY     = 1
thread.STATUS_RUNNING   = 2
thread.STATUS_SUSPENDED = 3
thread.STATUS_DEAD      = 4

-- new a thread
function _instance.new(callback, opt)
    opt = opt or {}
    local instance = table.inherit(_instance)
    instance._NAME      = opt.name or "anonymous"
    instance._ARGV      = opt.argv
    instance._CALLBACK  = callback
    instance._STACKSIZE = opt.stacksize or 0
    instance._STATUS    = thread.STATUS_READY
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
function _instance:start()
    if not self:is_ready() then
        return nil, string.format("%s: cannot start non-ready thread!", self)
    end
    assert(not self:cdata())

    -- serialize and pass callback and arguments to this thread
    local callinfo = {
        callback = self._CALLBACK,
        argv = self._ARGV
    }
    callinfo = string.serialize(callinfo, {strip = true, indent = false})

    -- init and start thread
    local handle, errors = thread.thread_init(self:name(), callinfo, self._STACKSIZE)
    if not handle then
        return nil, errors or string.format("%s: failed to create thread!", self)
    end

    self._HANLDE = handle
    self._STATUS = thread.STATUS_RUNNING
    return true
end

-- suspend thread
function _instance:suspend()
    if not self:is_running() then
        return nil, string.format("%s: cannot suspend non-running thread!", self)
    end
    assert(self:cdata())

    local ok, errors = thread.thread_suspend(self:cdata())
    if not ok then
        return nil, errors or string.format("%s: failed to suspend thread!", self)
    end

    self._STATUS = thread.STATUS_SUSPENDED
    return true
end

-- resume thread
function _instance:resume()
    if not self:is_suspended() then
        return nil, string.format("%s: cannot suspend non-suspended thread!", self)
    end
    assert(self:cdata())

    local ok, errors = thread.thread_resume(self:cdata())
    if not ok then
        return nil, errors or string.format("%s: failed to resume thread!", self)
    end

    self._STATUS = thread.STATUS_RUNNING
    return true
end

-- wait thread
function _instance:wait(timeout)
    if self:is_dead() then
        return 1
    elseif self:is_ready() then
        return -1, string.format("%s: cannot wait ready thread!", self)
    end
    assert(self:cdata())

    local ok, errors = thread.thread_wait(self:cdata(), timeout)
    if ok < 0 then
        return -1, errors or string.format("%s: failed to resume thread!", self)
    end

    if ok > 0 then
        self._STATUS = thread.STATUS_DEAD
    end
    return ok
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
    if self:cdata() and self:is_dead() and io.thread_exit(self:cdata()) then
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
    if callback == nil then
        return nil, "invalid thread, callback is nil"
    end
    return _instance.new(callback, opt)
end

-- get the running thread
function thread.running()
    -- TODO
end

-- run thread
function thread._run_thread(callinfo_str)

    -- get callback info
    local callinfo, errors = string.deserialize(callinfo_str)
    if not callinfo then
        return false, string.format("invalid thread callinfo, %s!", errors or "unknown")
    end
    local callback = callinfo.callback
    if not callback then
        return false, string.format("no callback")
    end

    -- bind sandbox
--    local sandbox_inst, errors = sandbox.new(callback, {
--        filter = interp:filter(), rootdir = interp:rootdir(), namespace = interp:namespace()})
    local sandbox_inst, errors = sandbox.new(callback)
    if not sandbox_inst then
        return false, errors
    end

    -- do callback
    return sandbox.load(sandbox_inst:script(), table.unpack(callinfo.argv or {}))
end

-- return module
return thread

