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
-- @file        thread.lua
--

-- define module
local thread    = thread or {}
local _thread   = _thread or {}
local _mutex    = _mutex or {}

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
function _thread.new(callback, opt)
    opt = opt or {}
    local instance = table.inherit(_thread)
    instance._NAME      = opt.name or "anonymous"
    instance._ARGV      = opt.argv
    instance._CALLBACK  = callback
    instance._STACKSIZE = opt.stacksize or 0
    instance._STATUS    = thread.STATUS_READY
    setmetatable(instance, _thread)
    return instance
end

-- get thread name
function _thread:name()
    return self._NAME
end

-- get cdata of thread
function _thread:cdata()
    return self._HANLDE
end

-- get thread status
function _thread:status()
    return self._STATUS
end

-- is ready?
function _thread:is_ready()
    return self:status() == thread.STATUS_READY
end

-- is running?
function _thread:is_running()
    return self:status() == thread.STATUS_RUNNING
end

-- is suspended?
function _thread:is_suspended()
    return self:status() == thread.STATUS_SUSPENDED
end

-- is dead?
function _thread:is_dead()
    return self:status() == thread.STATUS_DEAD
end

-- start thread
function _thread:start()
    if not self:is_ready() then
        return nil, string.format("%s: cannot start non-ready thread!", self)
    end
    assert(not self:cdata())

    -- serialize and pass callback and arguments to this thread
    -- we do not use string.serialize to serialize callback, because it's slower (deserialize)
    -- and we cannot strip function debug info, we need to reserve _ENV, and other upvalue names
    local callback = string._dump(self._CALLBACK)
    local callinfo = {name = self:name(), argv = self._ARGV}
    callinfo = string.serialize(callinfo, {strip = true, indent = false})

    -- init and start thread
    local handle, errors = thread.thread_init(self:name(), callback, callinfo, self._STACKSIZE)
    if not handle then
        return nil, errors or string.format("%s: failed to create thread!", self)
    end

    self._HANLDE = handle
    self._STATUS = thread.STATUS_RUNNING
    return true
end

-- suspend thread
function _thread:suspend()
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
function _thread:resume()
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
function _thread:wait(timeout)
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
function _thread:__tostring()
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
function _thread:__gc()
    if self:cdata() and self:is_dead() and thread.thread_exit(self:cdata()) then
        self._HANLDE = nil
    end
end

-- new an mutex
function _mutex.new(name, lock)
    local mutex = table.inherit(_mutex)
    mutex._NAME = name
    mutex._LOCK = lock
    mutex._LOCKED_NUM = 0
    setmetatable(mutex, _mutex)
    return mutex
end

-- get the mutex name
function _mutex:name()
    return self._NAME
end

-- get the cdata
function _mutex:cdata()
    return self._LOCK
end

-- is locked?
function _mutex:islocked()
    return self._LOCKED_NUM > 0
end

-- lock file
--
-- @param opt       the argument option, {shared = true}
--
-- @return          ok, errors
--
function _mutex:lock(opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- lock it
    if self._LOCKED_NUM > 0 or thread.mutex_lock(self:cdata(), opt) then
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
function _mutex:trylock(opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- try lock it
    if self._LOCKED_NUM > 0 or thread.mutex_trylock(self:cdata(), opt) then
        self._LOCKED_NUM = self._LOCKED_NUM + 1
        return true
    else
        return false, string.format("%s: trylock failed!", self)
    end
end

-- unlock file
function _mutex:unlock(opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- unlock it
    if self._LOCKED_NUM > 1 or (self._LOCKED_NUM > 0 and thread.mutex_unlock(self:cdata())) then
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

-- close mutex
function _mutex:close()

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- close it
    ok = thread.mutex_exit(self:cdata())
    if ok then
        self._LOCK = nil
        self._LOCKED_NUM = 0
    end
    return ok
end

-- ensure the file is opened
function _mutex:_ensure_opened()
    if not self:cdata() then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

-- tostring(mutex)
function _mutex:__tostring()
    return "<mutex: " .. (self:name() or tostring(self:cdata())) .. ">"
end

-- gc(mutex)
function _mutex:__gc()
    if self:cdata() and thread.mutex_exit(self:cdata()) then
        self._LOCK = nil
        self._LOCKED_NUM = 0
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
    return _thread.new(callback, opt)
end

-- get the running thread name
function thread.running()
    return thread._RUNNING
end

-- run thread
function thread._run_thread(callback_str, callinfo_str)

    -- load callback info
    local callinfo
    local argv
    local threadname
    if callinfo_str then
        local result, errors = string.deserialize(callinfo_str)
        if not result then
            return false, string.format("invalid thread callinfo, %s!", errors or "unknown")
        end
        callinfo = result
        if callinfo then
            argv = callinfo.argv
            threadname = callinfo.name
        end
    end

    -- load callback
    local callback
    local fenvs = {}
    if callback_str then
        local script, errors = load(callback_str, "=(thread)", "b", fenvs)
        if not script then
            return false, string.format("cannot load thread(%s) callback, %s!", threadname or "unknown", errors or "unknown")
        end
        for i = 1, math.huge do
            local upname, upvalue = debug.getupvalue(script, i)
            if upname == nil or upname == "" then
                break
            end
            if upvalue == nil then
                return false, string.format("we cannot access upvalue(%s) in thread(%s) callback!", upname, threadname or "unknown")
            end
        end
        callback = script
    end
    if not callback then
        return false, "no thread callback"
    end

    -- bind sandbox
--    local sandbox_inst, errors = sandbox.new(callback, {
--        filter = interp:filter(), rootdir = interp:rootdir(), namespace = interp:namespace()})
    local sandbox_inst, errors = sandbox.new(callback)
    if not sandbox_inst then
        return false, errors
    end

    -- save the running thread name
    thread._RUNNING = threadname

    -- do callback
    return sandbox.load(sandbox_inst:script(), table.unpack(argv or {}))
end

-- open a mutex
function thread.mutex(name)
    local mutex = thread.mutex_init()
    if mutex then
        return _mutex.new(name, mutex)
    else
        return nil, string.format("cannot open mutex: %s", os.strerror())
    end
end

-- return module
return thread

