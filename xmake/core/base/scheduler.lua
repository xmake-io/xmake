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
local dlist     = require("base/dlist")
local table     = require("base/table")
local option    = require("base/option")
local string    = require("base/string")
local coroutine = require("base/coroutine")

-- new a coroutine instance
function _coroutine.new(rawco)
    local instance   = table.inherit(_coroutine)
    instance._RAWCO  = rawco 
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
function _coroutine:rawco()
    return self._RAWCO
end

-- get the coroutine status
function _coroutine:status()
    return coroutine.status(self:rawco())
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
function _coroutine:is_suspended()
    return self:status() == "suspended"
end

-- resume the coroutine
function _coroutine:resume(...)
    return coroutine.resume(self:rawco(), ...)
end

-- yield the coroutine
function _coroutine:yield(...)
    return coroutine.yield(self:rawco(), ...)
end

-- tostring(socket)
function _coroutine:__tostring()
    return string.format("<co: %s/%s>", self:rawco(), self:name())
end

-- gc(coroutine)
function _coroutine:__gc()
    self._RAWCO = nil
end

-- get the main loop coroutine
function scheduler:_co_mainloop()
    return self._CO_MAINLOOP
end

-- create the coroutine instance
function scheduler:_co_create(func)
    local rawco = coroutine.create(func)
    if not rawco then
        return nil, "create coroutine failed!"
    end
    return _coroutine.new(rawco)
end

-- suspend the current coroutine 
function scheduler:_co_suspend(...)

    -- get the next ready coroutine first
    local co_next = self:_co_next_ready()

    -- make the running coroutine as suspended
    self:_co_mark_suspended(self:running())

    -- switch to next coroutine 
    if (co_next ~= self:running()) then
        return self:_co_switch(co_next, ...)
    end
    
    -- no more coroutine? switch to mainloop coroutine
    return self:_co_switch(self:_co_mainloop(), ...)
end

-- TODO
-- resume the given coroutine
function scheduler:_co_resume()
end

-- switch to the given coroutine
function scheduler:_co_switch(co, ...)

    -- mark it as the running coroutine
    self._RUNNING = co

    -- switch to this coroutine
    return co:resume(...)
end

-- TODO we need support socket/pipe io and processes as same time
function scheduler:_poller_loop()
    print("poller loop")
end

-- ensure to start the poller loop
function scheduler:_poller_loop_ensure()

    -- ensure to run on coroutine with scheduler
    if not self:running() then
        return false, "please wait events on coroutine with scheduler!"
    end

    -- start the poller loop
    if not self._POLLER_STARTED then
        local co, errors = self:run(self._poller_loop, self)
        if not co then
            return false, "start poller loop failed!"
        end
        co:name_set("poller_loop")
        self._POLLER_STARTED = true
    end
    return true
end

-- the scheduler loop coroutine
function scheduler:_mainloop(opt)

    -- run loop
    local co_list_ready = self:_co_list_ready()
    while co_list_ready:size() > 0 do

        -- get the first ready coroutine
        local co_ready = co_list_ready:first()

        -- switch to this coroutine
        local ok, result_or_errors = self:_co_switch(co_ready)
        if not ok then
            os.raise(result_or_errors)
        end
           
        -- this coroutine has been finished? we remove it from the ready queue
        if co_ready:is_dead() then
            self:_co_mark_dead(co_ready)
        end
    end
end

-- start scheduler loop
function scheduler:_startloop()
    self._RUNNING = nil
    self._CO_MAINLOOP = nil
    self._POLLER_STARTED = false
end

-- stop scheduler loop
function scheduler:_stoploop()
    self._RUNNING = nil
    self._CO_MAINLOOP = nil
    self._POLLER_STARTED = false
end

-- get all ready coroutines list
-- 
-- ready: ready -> ready -> .. -> running -> .. -> ready -> ..->
--         |                                                    |   <-> poller_loop
--          ---------------------------<------------------------
--                                |        |
--                                 mainloop
--
function scheduler:_co_list_ready()
    local co_list_ready = self._CO_LIST_READY
    if not co_list_ready then
        co_list_ready = dlist()
        self._CO_LIST_READY = co_list_ready
    end
    return co_list_ready
end

-- get all suspended coroutines list
function scheduler:_co_list_suspended()
    local co_list_suspended = self._CO_LIST_SUSPENDED
    if not co_list_suspended then
        co_list_suspended = dlist()
        self._CO_LIST_SUSPENDED = co_list_suspended
    end
    return co_list_suspended
end

-- get the next ready coroutine
function scheduler:_co_next_ready()
    return self:_co_list_ready():next(self:running())
end

-- mark the given coroutine as suspended
function scheduler:_co_mark_suspended(co)

    -- cannot be mainloop coroutine
    assert(co ~= self:_co_mainloop())

    -- remove this coroutine from the ready coroutines
    self:_co_list_ready():remove(co)

    -- append this coroutine to suspended coroutines
    self:_co_list_suspended():push(co)
end

-- mark the given coroutine as dead
function scheduler:_co_mark_dead(co)

    -- cannot be mainloop coroutine
    assert(co ~= self:_co_mainloop())

    -- remove this coroutine from the ready coroutines
    self:_co_list_ready():remove(co)
end

-- run new coroutine function, it will insert to the pending queue
function scheduler:run(func, ...)
    local argv = table.pack(...)
    local co, errors = self:_co_create(function () return func(table.unpack(argv)) end)
    if not co then
        return nil, errors 
    end
    self:_co_list_ready():push(co)
    return co
end

-- get the current running coroutine in scheduler
function scheduler:running()
    return self._RUNNING 
end

-- wait socket events
function scheduler:waitsock(sock, events, timeout)

    -- ensure the poller loop
    local ok, errors = self:_poller_loop_ensure()
    if not ok then
        return -1, errors
    end

    -- TODO
    self:_co_suspend()
    return 0
end

-- sleep some times (ms)
function scheduler:sleep(ms)

    -- ensure the poller loop
    local ok, errors = self:_poller_loop_ensure()
    if not ok then
        return false, errors
    end

    -- TODO
    self:_co_suspend()
    return true
end

-- run loop, schedule coroutine with socket/io and sub-processes
function scheduler:runloop(opt)

    -- ensure only one scheduler
    if self._RUNNING then
        return false, "there is already a running scheduler!"
    end

    -- start scheduler
    self:_startloop()

    -- create the main loop
    local co_mainloop, errors = self:_co_create(self._mainloop)
    if not co_mainloop then
        return false, errors 
    end
    co_mainloop:name_set("mainloop")
    self._CO_MAINLOOP = co_mainloop

    -- start the main loop
    local ok, errors = self:_co_switch(co_mainloop, self, opt)
    if not ok then
        return false, errors
    end

    -- stop scheduler
    self:_stoploop()
    return true
end

-- return module: scheduler
return scheduler
