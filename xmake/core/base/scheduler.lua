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
local timer     = require("base/timer")
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

-- get the timer of scheduler
function scheduler:_timer()
    local t = self._TIMER
    if t == nil then
        t = timer:new()
        self._TIMER = t
    end
    return t
end

-- get socket events 
function scheduler:_sockevents(csock)
    return self._SOCKEVENTS and self._SOCKEVENTS[csock] or nil
end

-- set socket events
function scheduler:_sockevents_set(csock, data)
    local sockevents = self._SOCKEVENTS 
    if not sockevents then
        sockevents = {}
        self._SOCKEVENTS = sockevents
    end
    sockevents[csock] = data
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

    -- get the running coroutine
    local running = self:co_running()
    if not running then
        return -1, "we must call waitsock() in coroutine with scheduler!"
    end

    -- the socket events callback
    local function sockevents_cb(events)

        -- TODO
        self:co_resume(running, events)
    end

    -- get the previous socket events
    local events_prev = self:_sockevents(sock:csock())
    if events_prev then
        -- TODO
        print("not impl")
    else
        -- insert socket to poller for waiting events
        local ok, errors = poller:insert(poller.OT_SOCK, sock, events, sockevents_cb)
        if not ok then
            return -1, errors
        end
    end

    -- register timeout task to timer
    if timeout > 0 then
        self:_timer():post(function (cancel) 
            -- TODO
            self:co_resume(running, 0)
        end, timeout)
    end

    -- wait
    return self:co_suspend()
end

-- sleep some times (ms)
function scheduler:sleep(ms)

    -- we need not do sleep 
    if ms == 0 then
        return true
    end

    -- get the running coroutine
    local running = self:co_running()
    if not running then
        return false, "we must call sleep() in coroutine with scheduler!"
    end

    -- register timeout task to timer
    self:_timer():post(function (cancel) 
        self:co_resume(running)
    end, ms)

    -- wait
    self:co_suspend()
    return true
end

-- stop the scheduler loop
function scheduler:stop()
    -- TODO post a kill signal to poller
    -- stop timer and cancel all tasks
    self._STARTED = false
    return true
end

-- run loop, schedule coroutine with socket/io and sub-processes
function scheduler:runloop()

    -- start loop
    self._STARTED = true

    -- run loop
    opt = opt or {}
    local ok = true
    local errors = nil
    local timeout = -1
    while self._STARTED do 

        -- get the next timeout
        timeout = self:_timer():delay() or 1000

        -- wait events
        local count, events = poller:wait(timeout)
        if count < 0 then
            ok = false
            errors = events
            break
        end

        -- resume all suspended tasks with events
        for _, e in ipairs(events) do
            local otype = e[1]
            if otype == poller.OT_SOCK then
                local sockevents = e[2]
                local sockfunc   = e[3]
                if sockfunc then
                    sockfunc(sockevents)
                end
            else
                ok = false
                errors = string.format("invalid poller object type(%d)", otype)
                break
            end
        end

        -- spank the timer and trigger all timeout tasks
        self:_timer():next()
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
