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
-- @file        scheduler.lua
--

-- define module: scheduler
local scheduler  = scheduler or {}
local _coroutine = _coroutine or {}

-- load modules
local table     = require("base/table")
local option    = require("base/option")
local string    = require("base/string")
local poller    = require("base/poller")
local coroutine = require("base/coroutine")

-- new a coroutine instance
function _coroutine.new(name, thread)
    local instance   = table.inherit(_coroutine)
    instance._NAME   = name
    instance._THREAD = thread
    setmetatable(instance, _coroutine)
    return instance
end

-- get the coroutine name
function _coroutine:name()
    return self._NAME or "none"
end

-- set the coroutine name
function _coroutine:name_set(name)
    self._NAME = name
end

-- get the raw coroutine thread 
function _coroutine:thread()
    return self._THREAD
end

-- get the coroutine status
function _coroutine:status()
    return coroutine.status(self:thread())
end

-- is dead?
function _coroutine:is_dead()
    return self:status() == "dead"
end

-- is running?
function _coroutine:is_running()
    return self:status() == "running"
end

-- is suspended?
function _coroutine:is_suspend()
    return self:status() == "suspend"
end

-- tostring(socket)
function _coroutine:__tostring()
    return string.format("<co: %s/%s>", self:thread(), self:name())
end

-- gc(coroutine)
function _coroutine:__gc()
    self._THREAD = nil
end

-- wait the current coroutine
function scheduler:_co_wait()
    -- TODO
    self:co_suspend()
end

-- wake the given coroutine
function scheduler:_co_wake(co)
    -- TODO
end

-- start a new coroutine task
function scheduler:co_start(cotask, ...)
    return self:co_start_named(nil, cotask, ...)
end

-- start a new named coroutine task
function scheduler:co_start_named(coname, cotask, ...)
    local co = _coroutine.new(coname, coroutine.create(cotask))
    self:co_tasks()[co:thread()] = co
    local ok, errors = scheduler:co_resume(co, ...)
    self:co_tasks()[co:thread()] = nil
    if not ok then
        return nil, errors
    end
    return co
end

-- resume the given coroutine
function scheduler:co_resume(co, ...)
    return coroutine.resume(co:thread(), ...)
end

-- suspend the current coroutine
function scheduler:co_suspend(...)
    return coroutine.yield(...)
end

-- get the current running coroutine 
function scheduler:co_running()
    local running = coroutine.running()
    return running and self:co_tasks()[running] or nil 
end

-- get all coroutine tasks
function scheduler:co_tasks()
    local cotasks = self._CO_TASKS
    if not cotasks then
        cotasks = {}
        self._CO_TASKS = cotasks
    end
    return cotasks
end

-- wait socket events
function scheduler:waitsock(sock, events, timeout)

    -- TODO
    return 0
end

-- sleep some times (ms)
function scheduler:sleep(ms)

    print("sleep", ms)

    self:_co_wait()
    return true
end

-- the loop is started?
function scheduler:is_started()
    return self._STARTED
end

-- stop the scheduler loop
function scheduler:stop()
    -- TODO post a kill signal to poller
    self._STARTED = false
end

-- run loop, schedule coroutine with socket/io and sub-processes
function scheduler:runloop(opt)

    -- start loop
    self._STARTED = true

    -- run loop
    opt = opt or {}
    local ok = true
    local errors = nil
    local timeout = opt.timeout or -1
    while self._STARTED do 

        -- wait events
        local count, events = poller:wait(timeout)
        if count < 0 then
            ok = false
            errors = events
            break
        end

        -- spank the timer and trigger all timeout tasks
        -- TODO

        -- resume all suspended tasks with events
        -- TODO
    end

    -- mark the loop as stopped first
    self._STARTED = false

    -- TODO resume all suspended tasks
    -- we cannot suspend them now, all tasks will be exited directly and free all resources.
    -- ...

    -- finished
    return ok, errors
end

-- return module: scheduler
return scheduler
