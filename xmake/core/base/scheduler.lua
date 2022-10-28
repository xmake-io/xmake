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
-- @file        scheduler.lua
--

-- define module: scheduler
local scheduler  = scheduler or {}
local _coroutine = _coroutine or {}

-- load modules
local table     = require("base/table")
local utils     = require("base/utils")
local option    = require("base/option")
local string    = require("base/string")
local poller    = require("base/poller")
local timer     = require("base/timer")
local hashset   = require("base/hashset")
local coroutine = require("base/coroutine")
local bit       = require("base/bit")

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

-- get the waiting poller object
function _coroutine:waitobj()
    return self._WAITOBJ
end

-- set the waiting poller object
function _coroutine:waitobj_set(obj)
    self._WAITOBJ = obj
end

-- get user private data
function _coroutine:data(name)
    return self._DATA and self._DATA[name]
end

-- set user private data
function _coroutine:data_set(name, data)
    self._DATA = self._DATA or {}
    self._DATA[name] = data
end

-- add user private data
function _coroutine:data_add(name, data)
    self._DATA = self._DATA or {}
    self._DATA[name] = table.unwrap(table.join(self._DATA[name] or {}, data))
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
function _coroutine:is_suspended()
    return self:status() == "suspended"
end

-- is isolated?
function _coroutine:is_isolated()
    return self._ISOLATED
end

-- isolate coroutine environments
function _coroutine:isolate(isolate)
    self._ISOLATED = isolate
end

-- get the current timer task
function _coroutine:_timer_task()
    return self._TIMER_TASK
end

-- set the timer task
function _coroutine:_timer_task_set(task)
    self._TIMER_TASK = task
end

-- tostring(coroutine)
function _coroutine:__tostring()
    return string.format("<co: %s/%s>", self:name(), self:status())
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

-- get poller object data for socket, pipe, process, fwatcher object
function scheduler:_poller_data(obj)
    return self._POLLERDATA and self._POLLERDATA[obj] or nil
end

-- set poller object data
--
-- data.co_recv:            the suspended coroutine for waiting poller/recv
-- data.co_send:            the suspended coroutine for waiting poller/send
-- data.poller_events_wait: the waited events for poller
-- data.poller_events_save: the saved events for poller (triggered)
--
function scheduler:_poller_data_set(obj, data)
    local pollerdata = self._POLLERDATA
    if not pollerdata then
        pollerdata = {}
        self._POLLERDATA = pollerdata
    end
    pollerdata[obj] = data
end

-- resume the suspended coroutine after poller callback
function scheduler:_poller_resume_co(co, events)

    -- cancel timer task if exists
    local timer_task = co:_timer_task()
    if timer_task then
        timer_task.cancel = true
    end

    -- the scheduler has been stopped? mark events as error to stop the coroutine
    if not self._STARTED then
        events = poller.EV_POLLER_ERROR
    end

    -- this coroutine must be suspended
    assert(co:is_suspended())

    -- resume this coroutine task
    co:waitobj_set(nil)
    return self:co_resume(co, (bit.band(events, poller.EV_POLLER_ERROR) ~= 0) and -1 or events)
end

-- the poller events callback
function scheduler:_poller_events_cb(obj, events)

    -- get poller object data
    local pollerdata = self:_poller_data(obj)
    if not pollerdata then
        return false, string.format("%s: cannot get poller data!", obj)
    end

    -- is process/fwatcher object?
    if obj:otype() == poller.OT_PROC or obj:otype() == poller.OT_FWATCHER then

        -- resume coroutine and return the process exit status/fwatcher event
        pollerdata.object_event = events

        -- waiting process/fwatcher? resume this coroutine
        if pollerdata.co_waiting then
            local co_waiting = pollerdata.co_waiting
            pollerdata.co_waiting = nil
            return self:_poller_resume_co(co_waiting, 1)
        else
            pollerdata.object_pending = 1
        end
        return true
    end

    -- get poller object events
    local events_prev_wait = pollerdata.poller_events_wait
    local events_prev_save = pollerdata.poller_events_save

    -- eof for edge trigger?
    if bit.band(events, poller.EV_POLLER_EOF) ~= 0 then
        -- cache this eof as next recv/send event
        events = bit.band(events, bit.bnot(poller.EV_POLLER_EOF))
        events_prev_save = bit.bor(events_prev_save, events_prev_wait)
        pollerdata.poller_events_save = events_prev_save
    end

    -- get the waiting coroutines
    local co_recv = bit.band(events, poller.EV_POLLER_RECV) ~= 0 and pollerdata.co_recv or nil
    local co_send = bit.band(events, poller.EV_POLLER_SEND) ~= 0 and pollerdata.co_send or nil

    -- return the events result for the waiting coroutines
    if co_recv and co_recv == co_send then
        pollerdata.co_recv = nil
        pollerdata.co_send = nil
        return self:_poller_resume_co(co_recv, events)
    else

        if co_recv then
            pollerdata.co_recv = nil
            local ok, errors = self:_poller_resume_co(co_recv, bit.band(events, bit.bnot(poller.EV_POLLER_SEND)))
            if not ok then
                return false, errors
            end
            events = bit.band(events, bit.bnot(poller.EV_POLLER_RECV))
        end
        if co_send then
            pollerdata.co_send = nil
            local ok, errors = self:_poller_resume_co(co_send, bit.band(events, bit.bnot(poller.EV_POLLER_RECV)))
            if not ok then
                return false, errors
            end
            events = bit.band(events, bit.bnot(poller.EV_POLLER_SEND))
        end

        -- no coroutines are waiting? cache this events
        if bit.band(events, poller.EV_POLLER_RECV) ~= 0 or bit.band(events, poller.EV_POLLER_SEND) ~= 0 then
            events_prev_save = bit.bor(events_prev_save, events)
            pollerdata.poller_events_save = events_prev_save
        end
    end
    return true
end

-- update the current directory hash of current coroutine
function scheduler:_co_curdir_update(curdir)

    -- get running coroutine
    local running = self:co_running()
    if not running then
        return
    end

    -- save the current directory hash
    curdir = curdir or os.curdir()
    local curdir_hash = hash.uuid4(path.absolute(curdir)):sub(1, 8)
    self._CO_CURDIR_HASH = curdir_hash

    -- save the current directory for each coroutine
    local co_curdirs = self._CO_CURDIRS
    if not co_curdirs then
        co_curdirs = {}
        self._CO_CURDIRS = co_curdirs
    end
    co_curdirs[running] = {curdir_hash, curdir}
end

-- update the current environments hash of current coroutine
function scheduler:_co_curenvs_update(envs)

    -- get running coroutine
    local running = self:co_running()
    if not running then
        return
    end

    -- save the current directory hash
    local envs_hash = ""
    envs = envs or os.getenvs()
    for _, key in ipairs(table.orderkeys(envs)) do
        envs_hash = envs_hash .. key:upper() .. envs[key]
    end
    envs_hash = hash.uuid4(envs_hash):sub(1, 8)
    self._CO_CURENVS_HASH = envs_hash

    -- save the current directory for each coroutine
    local co_curenvs = self._CO_CURENVS
    if not co_curenvs then
        co_curenvs = {}
        self._CO_CURENVS = co_curenvs
    end
    co_curenvs[running] = {envs_hash, envs}
end

-- resume it's waiting coroutine if all coroutines are dead in group
function scheduler:_co_groups_resume()

    local resumed_count = 0
    local co_groups = self._CO_GROUPS
    if co_groups then
        local co_groups_waiting = self._CO_GROUPS_WAITING
        local co_resumed_list = {}
        for name, co_group in pairs(co_groups) do

            -- get coroutine and limit in waiting group
            local item = co_groups_waiting and co_groups_waiting[name] or nil
            if item then
                local co_waiting = item[1]
                local limit = item[2]

                -- get dead coroutines count in this group
                local count = 0
                for _, co in ipairs(co_group) do
                    if count < limit then
                        if co:is_dead() then
                            count = count + 1
                        end
                    else
                        break
                    end
                end

                -- resume the waiting coroutine of this group if some coroutines are dead in this group
                if count >= limit and co_waiting and co_waiting:is_suspended() then
                    resumed_count = resumed_count + 1
                    self._CO_GROUPS_WAITING[name] = nil
                    table.insert(co_resumed_list, co_waiting)
                end
            end
        end
        if #co_resumed_list > 0 then
            for _, co_waiting in ipairs(co_resumed_list) do
                local ok, errors = self:co_resume(co_waiting)
                if not ok then
                    return -1, errors
                end
            end
        end
    end
    return resumed_count
end

-- get profiler
function scheduler:_profiler()
    local profiler = self._PROFILE
    if profiler == nil then
        profiler = require("base/profiler")
        if not profiler:enabled() then
            profiler = false
        end
    end
    return profiler or nil
end

-- start a new coroutine task
function scheduler:co_start(cotask, ...)
    return self:co_start_named(nil, cotask, ...)
end

-- start a new named coroutine task
function scheduler:co_start_named(coname, cotask, ...)
    return self:co_start_withopt({name = coname}, cotask, ...)
end

-- start a new coroutine task with options
function scheduler:co_start_withopt(opt, cotask, ...)

    -- check coroutine task
    opt = opt or {}
    local coname = opt.name
    if not cotask then
        return nil, string.format("cannot start coroutine, invalid cotask(%s/%s)", coname and coname or "anonymous", cotask)
    end

    -- start coroutine
    local co
    co = _coroutine.new(coname, coroutine.create(function(...)
        local profiler = self:_profiler()
        if profiler and profiler:enabled() then
            profiler:start()
        end
        self:_co_curdir_update()
        self:_co_curenvs_update()
        cotask(...)
        self:co_tasks()[co:thread()] = nil
        if self:co_count() > 0 then
            self._CO_COUNT = self:co_count() - 1
        end
    end))
    if opt.isolate then
        co:isolate(true)
    end
    self:co_tasks()[co:thread()] = co
    self._CO_COUNT = self:co_count() + 1
    if self._STARTED then
        local ok, errors = self:co_resume(co, ...)
        if not ok then
            return nil, errors
        end
    else
        self._CO_READY_TASKS = self._CO_READY_TASKS or {}
        table.insert(self._CO_READY_TASKS, {co, table.pack(...)})
    end

    -- add this coroutine to the pending groups
    local co_groups_pending = self._CO_GROUPS_PENDING
    if co_groups_pending then
        for _, co_group_pending in pairs(co_groups_pending) do
            table.insert(co_group_pending, co)
        end
    end
    return co
end

-- resume the given coroutine
function scheduler:co_resume(co, ...)
    return coroutine.resume(co:thread(), ...)
end

-- suspend the current coroutine
function scheduler:co_suspend(...)

    -- suspend it
    local results = table.pack(coroutine.yield(...))

    -- if the current directory has been changed? restore it
    local running = assert(self:co_running())
    local curdir = self._CO_CURDIR_HASH
    local olddir = self._CO_CURDIRS and self._CO_CURDIRS[running] or nil
    if olddir and curdir ~= olddir[1] then -- hash changed?
        os.cd(olddir[2])
    end

    -- if the current environments has been changed? restore it
    local curenvs = self._CO_CURENVS_HASH
    local oldenvs = self._CO_CURENVS and self._CO_CURENVS[running] or nil
    if oldenvs and curenvs ~= oldenvs[1] and running:is_isolated() then -- hash changed?
        os.setenvs(oldenvs[2])
    end

    -- return results
    return table.unpack(results)
end

-- yield the current coroutine
function scheduler:co_yield()
    return scheduler.co_sleep(self, 1)
end

-- sleep some times (ms)
function scheduler:co_sleep(ms)

    -- we need not do sleep
    if ms == 0 then
        return true
    end

    -- get the running coroutine
    local running = self:co_running()
    if not running then
        return false, "we must call sleep() in coroutine with scheduler!"
    end

    -- is stopped?
    if not self._STARTED then
        return false, "the scheduler is stopped!"
    end

    -- register timeout task to timer
    self:_timer():post(function (cancel)
        if running:is_suspended() then
            return self:co_resume(running)
        end
        return true
    end, ms)

    -- wait
    self:co_suspend()
    return true
end

-- get the given coroutine group
function scheduler:co_group(name)
    return self._CO_GROUPS and self._CO_GROUPS[name]
end

-- begin coroutine group
function scheduler:co_group_begin(name, scopefunc)

    -- enter groups
    self._CO_GROUPS = self._CO_GROUPS or {}
    self._CO_GROUPS_PENDING = self._CO_GROUPS_PENDING or {}
    if self._CO_GROUPS_PENDING[name] then
        return false, string.format("co_group(%s): already exists!", name)
    end
    self._CO_GROUPS_PENDING[name] = self._CO_GROUPS_PENDING[name] or {}

    -- call the scope function
    local co_group = self._CO_GROUPS[name] or {}
    local ok, errors = utils.trycall(scopefunc, nil, co_group)
    if not ok then
        return false, errors
    end

    -- leave groups
    self._CO_GROUPS[name] = co_group
    table.join2(self._CO_GROUPS[name], self._CO_GROUPS_PENDING[name])
    self._CO_GROUPS_PENDING[name] = nil
    return true
end

-- wait for finishing the given coroutine group
function scheduler:co_group_wait(name, opt)

    -- get coroutine group
    local co_group = self:co_group(name)
    if not co_group or #co_group == 0 then
        -- no coroutines in this group
        return true
    end

    -- get the running coroutine
    local running = self:co_running()
    if not running then
        return false, "we must call co_group_wait() in coroutine with scheduler!"
    end

    -- is stopped?
    if not self._STARTED then
        return false, "the scheduler is stopped!"
    end

    -- get limit count
    local limit = opt and opt.limit or #co_group

    -- wait it
    local count
    repeat
        count = 0
        for _, co in ipairs(co_group) do
            if count < limit then
                if co:is_dead() then
                    count = count + 1
                end
            else
                break
            end
        end
        if count < limit then
            self._CO_GROUPS_WAITING = self._CO_GROUPS_WAITING or {}
            self._CO_GROUPS_WAITING[name] = {running, limit}
            self:co_suspend()
        end
    until count >= limit

    -- remove all dead coroutines in group
    if limit == #co_group and count == limit then
        self._CO_GROUPS[name] = nil
    else
        for i = #co_group, 1, -1 do
            local co = co_group[i]
            if co:is_dead() then
                table.remove(co_group, i)
            end
        end
    end
    return true
end

-- get waiting objects for the given group name
function scheduler:co_group_waitobjs(name)
    local objs = hashset.new()
    for _, co in ipairs(table.wrap(self:co_group(name))) do
        if not co:is_dead() then
            local obj = co:waitobj()
            if obj then
                objs:insert(obj)
            end
        end
    end
    return objs
end

-- get the current running coroutine
function scheduler:co_running()
    if self._ENABLED then
        local running = coroutine.running()
        return running and self:co_tasks()[running] or nil
    end
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

-- get all coroutine count
function scheduler:co_count()
    return self._CO_COUNT or 0
end

-- wait poller object io events, only for socket and pipe object
function scheduler:poller_wait(obj, events, timeout)

    -- get the running coroutine
    local running = self:co_running()
    if not running then
        return -1, "we must call poller_wait() in coroutine with scheduler!"
    end

    -- is stopped?
    if not self._STARTED then
        return -1, "the scheduler is stopped!"
    end

    -- check the object type
    local otype = obj:otype()
    if otype ~= poller.OT_SOCK and otype ~= poller.OT_PIPE then
        return -1, string.format("%s: invalid object type(%d)!", obj, otype)
    end

    -- get and allocate poller object data
    local pollerdata = self:_poller_data(obj)
    if not pollerdata then
        pollerdata = {poller_events_wait = 0, poller_events_save = 0}
        self:_poller_data_set(obj, pollerdata)
    end

    -- enable edge-trigger mode if be supported
    if self._SUPPORT_EV_POLLER_CLEAR and (otype == poller.OT_SOCK or otype == poller.OT_PIPE) then
        events = bit.bor(events, poller.EV_POLLER_CLEAR)
    end

    -- get the previous poller object events
    local events_wait = events
    if pollerdata.poller_events_wait ~= 0 then

        -- return the cached events directly if the waiting events exists cache
        local events_prev_wait = pollerdata.poller_events_wait
        local events_prev_save = pollerdata.poller_events_save
        if events_prev_save ~= 0 and bit.band(events_prev_wait, events) ~= 0 then

            -- check error?
            if bit.band(events_prev_save, poller.EV_POLLER_ERROR) ~= 0 then
                pollerdata.poller_events_save = 0
                return -1, string.format("%s: events error!", obj)
            end

            -- clear cache events
            pollerdata.poller_events_save = bit.band(events_prev_save, bit.bnot(events))

            -- return the cached events
            return bit.band(events_prev_save, events)
        end

        -- modify the wait events and reserve the pending events in other coroutine
        events_wait = events_prev_wait
        if bit.band(events_wait, poller.EV_POLLER_RECV) ~= 0 and not pollerdata.co_recv then
            events_wait = bit.band(events_wait, bit.bnot(poller.EV_POLLER_RECV))
        end
        if bit.band(events_wait, poller.EV_POLLER_SEND) ~= 0 and not pollerdata.co_send then
            events_wait = bit.band(events_wait, bit.bnot(poller.EV_POLLER_SEND))
        end
        events_wait = bit.bor(events_wait, events)

        -- modify poller object from poller for waiting events if the waiting events has been changed
        if bit.band(events_prev_wait, events_wait) ~= events_wait then

            -- maybe wait recv/send at same time
            local ok, errors = poller:modify(obj, events_wait, self._poller_events_cb)
            if not ok then
                return -1, errors
            end
        end
    else

        -- insert poller object events
        local ok, errors = poller:insert(obj, events_wait, self._poller_events_cb)
        if not ok then
            return -1, errors
        end
    end

    -- register timeout task to timer
    local timer_task = nil
    if timeout > 0 then
        timer_task = self:_timer():post(function (cancel)
            if not cancel and running:is_suspended() then
                running:waitobj_set(nil)
                return self:co_resume(running, 0)
            end
            return true
        end, timeout)
    end
    running:_timer_task_set(timer_task)

    -- save waiting events
    pollerdata.poller_events_wait = events_wait
    pollerdata.poller_events_save = 0

    -- save the current coroutine
    if bit.band(events, poller.EV_POLLER_RECV) ~= 0 then
        pollerdata.co_recv = running
    end
    if bit.band(events, poller.EV_POLLER_SEND) ~= 0 then
        pollerdata.co_send = running
    end

    -- save the waiting poller object
    running:waitobj_set(obj)

    -- wait
    return self:co_suspend()
end

-- wait poller object/process status
function scheduler:poller_waitproc(obj, timeout)

    -- get the running coroutine
    local running = self:co_running()
    if not running then
        return -1, "we must call poller_wait() in coroutine with scheduler!"
    end

    -- is stopped?
    if not self._STARTED then
        return -1, "the scheduler is stopped!"
    end

    -- check the object type
    local otype = obj:otype()
    if otype ~= poller.OT_PROC then
        return -1, string.format("%s: invalid object type(%d)!", obj, otype)
    end

    -- get and allocate poller object data
    local pollerdata = self:_poller_data(obj)
    if not pollerdata then
        pollerdata = {object_pending = 0, object_event = 0}
        self:_poller_data_set(obj, pollerdata)
    end

    -- has pending process status?
    if pollerdata.object_pending ~= 0 then
        pollerdata.object_pending = 0
        return 1, pollerdata.object_event
    end

    -- insert poller object to poller for waiting process
    local ok, errors = poller:insert(obj, 0, self._poller_events_cb)
    if not ok then
        return -1, errors
    end

    -- register timeout task to timer
    local timer_task = nil
    if timeout > 0 then
        timer_task = self:_timer():post(function (cancel)
            if not cancel and running:is_suspended() then
                pollerdata.co_waiting = nil
                running:waitobj_set(nil)
                return self:co_resume(running, 0)
            end
            return true
        end, timeout)
    end
    running:_timer_task_set(timer_task)

    -- set process status
    pollerdata.object_event  = 0
    pollerdata.object_pending = 0
    pollerdata.co_waiting   = running

    -- save the waiting poller object
    running:waitobj_set(obj)

    -- wait
    local ok = self:co_suspend()
    return ok, pollerdata.object_event
end

-- wait poller object/fwatcher status
function scheduler:poller_waitfs(obj, timeout)

    -- get the running coroutine
    local running = self:co_running()
    if not running then
        return -1, "we must call poller_wait() in coroutine with scheduler!"
    end

    -- is stopped?
    if not self._STARTED then
        return -1, "the scheduler is stopped!"
    end

    -- check the object type
    local otype = obj:otype()
    if otype ~= poller.OT_FWATCHER then
        return -1, string.format("%s: invalid object type(%d)!", obj, otype)
    end

    -- get and allocate poller object data
    local pollerdata = self:_poller_data(obj)
    if not pollerdata then
        pollerdata = {object_pending = 0, object_event = 0}
        self:_poller_data_set(obj, pollerdata)
    end

    -- has pending process status?
    if pollerdata.object_pending ~= 0 then
        pollerdata.object_pending = 0
        return 1, pollerdata.object_event
    end

    -- insert poller object to poller for waiting fwatcher
    local ok, errors = poller:insert(obj, 0, self._poller_events_cb)
    if not ok then
        return -1, errors
    end

    -- register timeout task to timer
    local timer_task = nil
    if timeout > 0 then
        timer_task = self:_timer():post(function (cancel)
            if not cancel and running:is_suspended() then
                pollerdata.co_waiting = nil
                running:waitobj_set(nil)
                return self:co_resume(running, 0)
            end
            return true
        end, timeout)
    end
    running:_timer_task_set(timer_task)

    -- set fwatcher status
    pollerdata.object_event  = 0
    pollerdata.object_pending = 0
    pollerdata.co_waiting   = running

    -- save the waiting poller object
    running:waitobj_set(obj)

    -- wait
    local ok = self:co_suspend()
    return ok, pollerdata.object_event
end

-- cancel poller object events
function scheduler:poller_cancel(obj)

    -- reset the pollerdata data
    local pollerdata = self:_poller_data(obj)
    if pollerdata then
        if pollerdata.poller_events_wait ~= 0 or obj:otype() == poller.OT_PROC or obj:otype() == poller.OT_FWATCHER then
            local ok, errors = poller:remove(obj)
            if not ok then
                return false, errors
            end
        end
        self:_poller_data_set(obj, nil)
    end
    return true
end

-- enable or disable to scheduler
function scheduler:enable(enabled)
    self._ENABLED = enabled
end

-- stop the scheduler loop
function scheduler:stop()
    -- mark scheduler status as stopped and spank the poller:wait()
    self._STARTED = false
    poller:spank()
    return true
end

-- run loop, schedule coroutine with socket/io, sub-processes, fwatcher
function scheduler:runloop()

    -- start loop
    self._STARTED = true
    self._ENABLED = true

    -- ensure poller has been initialized first (for windows/iocp) and check edge-trigger mode (for epoll/kqueue)
    if poller:support(poller.EV_POLLER_CLEAR) then
        self._SUPPORT_EV_POLLER_CLEAR = true
    end

    -- set on change directory callback for scheduler
    os._sched_chdir_set(function (curdir)
        self:_co_curdir_update(curdir)
    end)

    -- set on change environments callback for scheduler
    os._sched_chenvs_set(function (envs)
        self:_co_curenvs_update(envs)
    end)

    -- start all ready coroutine tasks
    local co_ready_tasks = self._CO_READY_TASKS
    if co_ready_tasks then
        for _, task in pairs(co_ready_tasks) do
            local co   = task[1]
            local argv = task[2]
            local ok, errors = self:co_resume(co, table.unpack(argv))
            if not ok then
                return false, errors
            end
        end
    end
    self._CO_READY_TASKS = nil

    -- run loop
    opt = opt or {}
    local ok = true
    local errors = nil
    local timeout = -1
    while self._STARTED and self:co_count() > 0 do

        -- resume it's waiting coroutine if some coroutines are dead in group
        local resumed_count, resumed_errors = self:_co_groups_resume()
        if resumed_count < 0 then
            ok = false
            errors = resumed_errors
            break
        elseif resumed_count == 0 then

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
                local obj       = e[1]
                local objevents = e[2]
                local eventfunc = e[3]
                if eventfunc then
                    ok, errors = eventfunc(self, obj, objevents)
                    if not ok then
                        break
                    end
                end
            end
            if not ok then
                break
            end
        end

        -- spank the timer and trigger all timeout tasks
        ok, errors = self:_timer():next()
        if not ok then
            break
        end
    end

    -- mark the loop as stopped first
    self._STARTED = false

    -- cancel all timeout tasks and trigger them
    self:_timer():kill()

    -- finished and we need not resume other pending coroutines, because xmake will be aborted directly if fails
    return ok, errors
end

-- return module: scheduler
return scheduler
