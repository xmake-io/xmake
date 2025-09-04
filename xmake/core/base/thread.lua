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
local thread     = thread or {}
local _thread    = _thread or {}
local _mutex     = _mutex or {}
local _event     = _event or {}
local _semaphore = _semaphore or {}
local _queue     = _queue or {}
local _sharedata = _sharedata or {}

-- load modules
local io        = require("base/io")
local libc      = require("base/libc")
local pipe      = require("base/pipe")
local bytes     = require("base/bytes")
local table     = require("base/table")
local string    = require("base/string")
local scheduler = require("base/scheduler")
local sandbox   = require("sandbox/sandbox")

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

    -- translate arguments (mutex, ...)
    local argv = {}
    for _, arg in ipairs(self._ARGV) do
        if type(arg) == "table" then
            -- is mutex? we can only pass cdata address
            if arg._MUTEX and arg.cdata then
                thread.mutex_incref(arg:cdata())
                arg = {mutex = true, name = arg:name(), caddr = libc.dataptr(arg:cdata(), {ffi = false})}
            -- is event? we can only pass cdata address
            elseif arg._EVENT and arg.cdata then
                thread.event_incref(arg:cdata())
                arg = {event = true, name = arg:name(), caddr = libc.dataptr(arg:cdata(), {ffi = false})}
            -- is semaphore? we can only pass cdata address
            elseif arg._SEMAPHORE and arg.cdata then
                thread.semaphore_incref(arg:cdata())
                arg = {semaphore = true, name = arg:name(), caddr = libc.dataptr(arg:cdata(), {ffi = false})}
            -- is queue? we can only pass cdata address
            elseif arg._QUEUE and arg.cdata then
                thread.queue_incref(arg:cdata())
                arg = {queue = true, name = arg:name(), caddr = libc.dataptr(arg:cdata(), {ffi = false})}
            -- is sharedata? we can only pass cdata address
            elseif arg._SHAREDATA and arg.cdata then
                thread.sharedata_incref(arg:cdata())
                arg = {sharedata = true, name = arg:name(), caddr = libc.dataptr(arg:cdata())}
            end
        end
        table.insert(argv, arg)
    end

    -- init callback info
    local callback = string._dump(self._CALLBACK)
    local callinfo = {name = self:name(), argv = argv}

    -- we need a pipe pair to wait and listen thread exit event
    local rpipe, wpipe = pipe.openpair("BA") -- rpipe (block)
    self._RPIPE = rpipe
    callinfo.wpipe = libc.dataptr(wpipe:cdata(), {ffi = false})
    -- we need to suppress gc to free it, because it has been transfer to thread in another lua state instance
    wpipe._PIPE = nil

    -- serialize and pass callback and arguments to this thread
    -- we do not use string.serialize to serialize callback, because it's slower (deserialize)
    -- and we cannot strip function debug info, we need to reserve _ENV, and other upvalue names
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

    local ok, errors
    local rpipe = self._RPIPE
    if rpipe and scheduler:co_running() then
        ok, errors = rpipe:wait(pipe.EV_READ, timeout)
    else
        ok, errors = thread.thread_wait(self:cdata(), timeout)
    end
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
function _mutex.new(name, cdata)
    local mutex = table.inherit(_mutex)
    mutex._NAME = name
    mutex._MUTEX = cdata
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
    return self._MUTEX
end

-- is locked?
function _mutex:islocked()
    return self._LOCKED_NUM > 0
end

-- lock mutex
--
-- @return          ok, errors
--
function _mutex:lock()
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    if self._LOCKED_NUM > 0 or thread.mutex_lock(self:cdata()) then
        self._LOCKED_NUM = self._LOCKED_NUM + 1
        return true
    else
        return false, string.format("%s: lock failed!", self)
    end
end

-- try to lock mutex
--
-- @param opt       the argument option, {shared = true}
--
-- @return          ok, errors
--
function _mutex:trylock(opt)
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    if self._LOCKED_NUM > 0 or thread.mutex_trylock(self:cdata(), opt) then
        self._LOCKED_NUM = self._LOCKED_NUM + 1
        return true
    else
        return false, string.format("%s: trylock failed!", self)
    end
end

-- unlock mutex
function _mutex:unlock(opt)
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

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
        self._MUTEX = nil
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
        self._MUTEX = nil
        self._LOCKED_NUM = 0
    end
end

-- new an event
function _event.new(name, cdata)
    local event = table.inherit(_event)
    event._NAME = name
    event._EVENT = cdata
    setmetatable(event, _event)
    return event
end

-- get the event name
function _event:name()
    return self._NAME
end

-- get the cdata
function _event:cdata()
    return self._EVENT
end

-- post event
--
-- @return          ok, errors
--
function _event:post()
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    if not thread.event_post(self:cdata()) then
        return false, string.format("%s: post failed!", self)
    end
    return true
end

-- wait event
function _event:wait(timeout)
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    local ok, errors = thread.event_wait(self:cdata(), timeout)
    if ok < 0 then
        return false, string.format("%s: wait failed, errors: %s!", self, errors or "unknown")
    end
    return ok
end

-- close event
function _event:close()
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    ok = thread.event_exit(self:cdata())
    if ok then
        self._EVENT = nil
    end
    return ok
end

-- ensure the file is opened
function _event:_ensure_opened()
    if not self:cdata() then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

-- tostring(event)
function _event:__tostring()
    return "<event: " .. (self:name() or tostring(self:cdata())) .. ">"
end

-- gc(event)
function _event:__gc()
    if self:cdata() and thread.event_exit(self:cdata()) then
        self._EVENT = nil
    end
end

-- new an semaphore
function _semaphore.new(name, cdata)
    local semaphore = table.inherit(_semaphore)
    semaphore._NAME = name
    semaphore._SEMAPHORE = cdata
    setmetatable(semaphore, _semaphore)
    return semaphore
end

-- get the semaphore name
function _semaphore:name()
    return self._NAME
end

-- get the cdata
function _semaphore:cdata()
    return self._SEMAPHORE
end

-- post semaphore
--
-- @param value     the semaphore value
--
-- @return          ok, errors
--
function _semaphore:post(value)
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    if not thread.semaphore_post(self:cdata(), value) then
        return false, string.format("%s: post failed!", self)
    end
    return true
end

-- wait semaphore
function _semaphore:wait(timeout)
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    local ok, errors = thread.semaphore_wait(self:cdata(), timeout)
    if ok < 0 then
        return false, string.format("%s: wait failed, errors: %s!", self, errors or "unknown")
    end
    return ok
end

-- close semaphore
function _semaphore:close()
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    ok = thread.semaphore_exit(self:cdata())
    if ok then
        self._SEMAPHORE = nil
    end
    return ok
end

-- ensure the file is opened
function _semaphore:_ensure_opened()
    if not self:cdata() then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

-- tostring(semaphore)
function _semaphore:__tostring()
    return "<semaphore: " .. (self:name() or tostring(self:cdata())) .. ">"
end

-- gc(semaphore)
function _semaphore:__gc()
    if self:cdata() and thread.semaphore_exit(self:cdata()) then
        self._SEMAPHORE = nil
    end
end

-- new an queue
function _queue.new(name, cdata)
    local queue = table.inherit(_queue)
    queue._NAME = name
    queue._QUEUE = cdata
    setmetatable(queue, _queue)
    return queue
end

-- get the queue name
function _queue:name()
    return self._NAME
end

-- get the cdata
function _queue:cdata()
    return self._QUEUE
end

-- get queue size
function _queue:size()
    local ok, errors = self:_ensure_opened()
    if not ok then
        return nil, errors
    end

    return thread.queue_size(self:cdata())
end

-- is empty queue?
function _queue:empty()
    local ok, errors = self:_ensure_opened()
    if not ok then
        return nil, errors
    end

    return thread.queue_size(self:cdata()) == 0
end

-- clear queue
function _queue:clear()
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    local ok, errors = thread.queue_clear(self:cdata())
    if not ok then
        return false, string.format("%s: clear failed, errors: %s!", self, errors or "unknown")
    end
    return ok
end

-- push queue item
function _queue:push(value)
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    if type(value) == "table" then
        value = string.serialize(value, {strip = true, indent = false})
        if value == nil then
            return false, string.format("%s: cannot serialize value: %s", self, value)
        end
        value = "__table_" .. value
    end

    local ok, errors = thread.queue_push(self:cdata(), value)
    if not ok then
        return false, string.format("%s: push item failed, errors: %s!", self, errors or "unknown")
    end
    return ok
end

-- pop queue item
function _queue:pop()
    local ok, errors = self:_ensure_opened()
    if not ok then
        return nil, errors or "unknown"
    end

    local value, errors = thread.queue_pop(self:cdata())
    if value == nil and errors then
        return nil, string.format("%s: push item failed, errors: %s!", self, errors or "unknown")
    end

    if type(value) == "string" and value:startswith("__table_") then
        value = value:sub(9)
        value, errors = string.deserialize(value)
        if not value then
            return nil, string.format("invalid queue item, %s!", errors or "unknown")
        end
    end
    return value
end

-- close queue
function _queue:close()
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    ok = thread.queue_exit(self:cdata())
    if ok then
        self._QUEUE = nil
    end
    return ok
end

-- ensure the file is opened
function _queue:_ensure_opened()
    if not self:cdata() then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

-- tostring(queue)
function _queue:__tostring()
    return "<queue: " .. (self:name() or tostring(self:cdata())) .. ">"
end

-- gc(queue)
function _queue:__gc()
    if self:cdata() and thread.queue_exit(self:cdata()) then
        self._QUEUE = nil
    end
end

-- new an sharedata
function _sharedata.new(name, cdata)
    local sharedata = table.inherit(_sharedata)
    sharedata._NAME = name
    sharedata._SHAREDATA = cdata
    setmetatable(sharedata, _sharedata)
    return sharedata
end

-- get the sharedata name
function _sharedata:name()
    return self._NAME
end

-- get the cdata
function _sharedata:cdata()
    return self._SHAREDATA
end

-- clear sharedata
function _sharedata:clear()
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    local ok, errors = thread.sharedata_clear(self:cdata())
    if not ok then
        return false, string.format("%s: clear failed, errors: %s!", self, errors or "unknown")
    end
    return ok
end

-- set sharedata
function _sharedata:set(value)
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    if type(value) == "table" then
        value = string.serialize(value, {strip = true, indent = false})
        if value == nil then
            return false, string.format("%s: cannot serialize value: %s", self, value)
        end
        value = "__table_" .. value
    end

    local ok, errors = thread.sharedata_set(self:cdata(), value)
    if not ok then
        return false, string.format("%s: set sharedata failed, errors: %s!", self, errors or "unknown")
    end
    return ok
end

-- get sharedata
function _sharedata:get()
    local ok, errors = self:_ensure_opened()
    if not ok then
        return nil, errors or "unknown"
    end

    local value, errors = thread.sharedata_get(self:cdata())
    if value == nil and errors then
        return nil, string.format("%s: get sharedata failed, errors: %s!", self, errors or "unknown")
    end

    if type(value) == "string" and value:startswith("__table_") then
        value = value:sub(9)
        value, errors = string.deserialize(value)
        if not value then
            return nil, string.format("invalid sharedata, %s!", errors or "unknown")
        end
    end
    return value
end

-- close sharedata
function _sharedata:close()
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    ok = thread.sharedata_exit(self:cdata())
    if ok then
        self._SHAREDATA = nil
    end
    return ok
end

-- ensure the file is opened
function _sharedata:_ensure_opened()
    if not self:cdata() then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

-- tostring(sharedata)
function _sharedata:__tostring()
    return "<sharedata: " .. (self:name() or tostring(self:cdata())) .. ">"
end

-- gc(sharedata)
function _sharedata:__gc()
    if self:cdata() and thread.sharedata_exit(self:cdata()) then
        self._SHAREDATA = nil
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
    local wpipe
    if callinfo_str then
        local result, errors = string.deserialize(callinfo_str)
        if not result then
            return false, string.format("invalid thread callinfo, %s!", errors or "unknown")
        end
        callinfo = result
        if callinfo then
            argv = callinfo.argv
            threadname = callinfo.name
            wpipe = pipe.new(libc.ptraddr(callinfo.wpipe, {ffi = false}))
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
    local sandbox_inst, errors = sandbox.new(callback)
    if not sandbox_inst then
        return false, errors
    end

    -- save the running thread name
    thread._RUNNING = threadname

    -- translate arguments (mutex, ...)
    if argv then
        local newargv = {}
        for _, arg in ipairs(argv) do
            if type(arg) == "table" and arg.mutex and arg.caddr then
                arg = _mutex.new(arg.name, libc.ptraddr(arg.caddr, {ffi = false}))
            elseif type(arg) == "table" and arg.event and arg.caddr then
                arg = _event.new(arg.name, libc.ptraddr(arg.caddr, {ffi = false}))
            elseif type(arg) == "table" and arg.semaphore and arg.caddr then
                arg = _semaphore.new(arg.name, libc.ptraddr(arg.caddr, {ffi = false}))
            elseif type(arg) == "table" and arg.queue and arg.caddr then
                arg = _queue.new(arg.name, libc.ptraddr(arg.caddr, {ffi = false}))
            elseif type(arg) == "table" and arg.sharedata and arg.caddr then
                arg = _sharedata.new(arg.name, libc.ptraddr(arg.caddr, {ffi = false}))
            end
            table.insert(newargv, arg)
        end
        argv = newargv
    end

    -- do callback
    local ok, errors = sandbox.load(sandbox_inst:script(), table.unpack(argv or {}))

    -- thread is finished, we need to notify the waited thread
    if wpipe then
        local ok, errors = wpipe:write("exited")
        if ok == nil then
            return false, errors
        end
    end
    return ok, errors
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

-- open a event
function thread.event(name)
    local event = thread.event_init()
    if event then
        return _event.new(name, event)
    else
        return nil, string.format("cannot open event: %s", os.strerror())
    end
end

-- open a semaphore
function thread.semaphore(name, value)
    local semaphore = thread.semaphore_init(value or 0)
    if semaphore then
        return _semaphore.new(name, semaphore)
    else
        return nil, string.format("cannot open semaphore: %s", os.strerror())
    end
end

-- open a queue
function thread.queue(name)
    local queue = thread.queue_init()
    if queue then
        return _queue.new(name, queue)
    else
        return nil, string.format("cannot open queue: %s", os.strerror())
    end
end

-- open a sharedata
function thread.sharedata(name)
    local sharedata = thread.sharedata_init()
    if sharedata then
        return _sharedata.new(name, sharedata)
    else
        return nil, string.format("cannot open sharedata: %s", os.strerror())
    end
end

-- return module
return thread

