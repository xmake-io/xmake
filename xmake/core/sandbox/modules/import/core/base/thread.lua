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

-- load modules
local utils     = require("base/utils")
local string    = require("base/string")
local thread    = require("base/thread")
local raise     = require("sandbox/modules/raise")

-- define module
local sandbox_core_base_thread           = sandbox_core_base_thread or {}
local sandbox_core_base_thread_instance  = sandbox_core_base_thread_instance or {}
local sandbox_core_base_thread_mutex     = sandbox_core_base_thread_mutex or {}
local sandbox_core_base_thread_event     = sandbox_core_base_thread_event or {}
local sandbox_core_base_thread_semaphore = sandbox_core_base_thread_semaphore or {}
local sandbox_core_base_thread_queue     = sandbox_core_base_thread_queue or {}
local sandbox_core_base_thread_sharedata = sandbox_core_base_thread_sharedata or {}

-- export the thread status
sandbox_core_base_thread.STATUS_READY     = thread.STATUS_READY
sandbox_core_base_thread.STATUS_RUNNING   = thread.STATUS_RUNNING
sandbox_core_base_thread.STATUS_SUSPENDED = thread.STATUS_SUSPENDED
sandbox_core_base_thread.STATUS_DEAD      = thread.STATUS_DEAD

-- wrap thread
function _thread_wrap(instance)

    -- hook thread interfaces
    local hooked = {}
    for name, func in pairs(sandbox_core_base_thread_instance) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = instance["_" .. name] or instance[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        instance[name] = func
    end
    return instance
end

-- start thread
function sandbox_core_base_thread_instance.start(instance)
    local ok, errors = instance:_start()
    if not ok then
        raise(errors)
    end
    return instance
end

-- suspend thread
function sandbox_core_base_thread_instance.suspend(instance)
    local ok, errors = instance:_suspend()
    if not ok then
        raise(errors)
    end
end

-- resume thread
function sandbox_core_base_thread_instance.resume(instance)
    local ok, errors = instance:_resume()
    if not ok then
        raise(errors)
    end
end

-- wait thread
function sandbox_core_base_thread_instance.wait(instance, timeout)
    local ok, errors = instance:_wait(timeout)
    if ok < 0 then
        raise(errors)
    end
end

-- lock mutex
function sandbox_core_base_thread_mutex.lock(mutex)
    local ok, errors = mutex:_lock()
    if not ok then
        raise(errors)
    end
end

-- unlock mutex
function sandbox_core_base_thread_mutex.unlock(mutex)
    local ok, errors = mutex:_unlock()
    if not ok then
        raise(errors)
    end
end

-- close mutex
function sandbox_core_base_thread_mutex.close(mutex)
    local ok, errors = mutex:_close()
    if not ok then
        raise(errors)
    end
end

-- post event
function sandbox_core_base_thread_event.post(event)
    local ok, errors = event:_post()
    if not ok then
        raise(errors)
    end
end

-- wait event
function sandbox_core_base_thread_event.wait(event, timeout)
    local ok, errors = event:_wait(timeout)
    if ok < 0 then
        raise(errors)
    end
    return ok
end

-- close event
function sandbox_core_base_thread_event.close(event)
    local ok, errors = event:_close()
    if not ok then
        raise(errors)
    end
end

-- post semaphore
function sandbox_core_base_thread_semaphore.post(semaphore, value)
    local ok, errors = semaphore:_post(value)
    if not ok then
        raise(errors)
    end
end

-- wait semaphore
function sandbox_core_base_thread_semaphore.wait(semaphore, timeout)
    local ok, errors = semaphore:_wait(timeout)
    if ok < 0 then
        raise(errors)
    end
    return ok
end

-- close semaphore
function sandbox_core_base_thread_semaphore.close(semaphore)
    local ok, errors = semaphore:_close()
    if not ok then
        raise(errors)
    end
end

-- get queue size
function sandbox_core_base_thread_queue.size(queue)
    local size, errors = queue:_size()
    if not size then
        raise(errors)
    end
    return size
end

-- is empty queue?
function sandbox_core_base_thread_queue.empty(queue)
    local ok, errors = queue:_empty()
    if ok == nil then
        raise(errors)
    end
    return ok
end

-- clear queue
function sandbox_core_base_thread_queue.clear(queue)
    local ok, errors = queue:_clear()
    if not ok then
        raise(errors)
    end
    return ok
end

-- push queue item
function sandbox_core_base_thread_queue.push(queue, value)
    local ok, errors = queue:_push(value)
    if not ok then
        raise(errors)
    end
    return ok
end

-- pop queue item
function sandbox_core_base_thread_queue.pop(queue)
    local value, errors = queue:_pop()
    if value == nil and errors then
        raise(errors)
    end
    return value
end

-- close queue
function sandbox_core_base_thread_queue.close(queue)
    local ok, errors = queue:_close()
    if not ok then
        raise(errors)
    end
end

-- clear sharedata
function sandbox_core_base_thread_sharedata.clear(sharedata)
    local ok, errors = sharedata:_clear()
    if not ok then
        raise(errors)
    end
    return ok
end

-- set sharedata
function sandbox_core_base_thread_sharedata.set(sharedata, value)
    local ok, errors = sharedata:_set(value)
    if not ok then
        raise(errors)
    end
    return ok
end

-- get sharedata
function sandbox_core_base_thread_sharedata.get(sharedata)
    local value, errors = sharedata:_get()
    if value == nil and errors then
        raise(errors)
    end
    return value
end

-- close sharedata
function sandbox_core_base_thread_sharedata.close(sharedata)
    local ok, errors = sharedata:_close()
    if not ok then
        raise(errors)
    end
end

-- new thread
function sandbox_core_base_thread.new(callback, opt)
    local instance, errors = thread.new(callback, opt)
    if not instance then
        raise(errors)
    end
    return _thread_wrap(instance)
end

-- start a thread
function sandbox_core_base_thread.start(callback, ...)
    return sandbox_core_base_thread.start_withopt(callback, {argv = table.pack(...)})
end

-- start a named thread
function sandbox_core_base_thread.start_named(name, callback, ...)
    return sandbox_core_base_thread.start_withopt(callback, {name = name, argv = table.pack(...)})
end

-- start a thread with options
function sandbox_core_base_thread.start_withopt(callback, opt)
    return sandbox_core_base_thread.new(callback, opt):start()
end

-- get the running thread
function sandbox_core_base_thread.running()
    local instance, errors = thread.running()
    if not instance then
        raise(errors)
    end
    return instance
end

-- open a mutex
function sandbox_core_base_thread.mutex(name)
    local mutex, errors = thread.mutex(name)
    if not mutex then
        raise(errors)
    end

    -- hook filemutex interfaces
    local hooked = {}
    for name, func in pairs(sandbox_core_base_thread_mutex) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = mutex["_" .. name] or mutex[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        mutex[name] = func
    end
    return mutex
end

-- open a event
function sandbox_core_base_thread.event(name)
    local event, errors = thread.event(name)
    if not event then
        raise(errors)
    end

    -- hook fileevent interfaces
    local hooked = {}
    for name, func in pairs(sandbox_core_base_thread_event) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = event["_" .. name] or event[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        event[name] = func
    end
    return event
end

-- open a semaphore
function sandbox_core_base_thread.semaphore(name, value)
    local semaphore, errors = thread.semaphore(name, value)
    if not semaphore then
        raise(errors)
    end

    -- hook filesemaphore interfaces
    local hooked = {}
    for name, func in pairs(sandbox_core_base_thread_semaphore) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = semaphore["_" .. name] or semaphore[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        semaphore[name] = func
    end
    return semaphore
end

-- open a queue
function sandbox_core_base_thread.queue(name)
    local queue, errors = thread.queue(name)
    if not queue then
        raise(errors)
    end

    -- hook filequeue interfaces
    local hooked = {}
    for name, func in pairs(sandbox_core_base_thread_queue) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = queue["_" .. name] or queue[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        queue[name] = func
    end
    return queue
end

-- open a sharedata
function sandbox_core_base_thread.sharedata(name)
    local sharedata, errors = thread.sharedata(name)
    if not sharedata then
        raise(errors)
    end

    -- hook filesharedata interfaces
    local hooked = {}
    for name, func in pairs(sandbox_core_base_thread_sharedata) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = sharedata["_" .. name] or sharedata[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        sharedata[name] = func
    end
    return sharedata
end

-- return module
return sandbox_core_base_thread

