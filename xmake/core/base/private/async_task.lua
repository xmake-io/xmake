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
-- @file        async_task.lua
--

-- define module: async_task
local async_task = async_task or {}

-- load modules
local os     = require("base/os")
local utils  = require("base/utils")
local thread = require("base/thread")
local option = require("base/option")

-- the task status
local is_stopped = false
local is_started = false

-- the task event and queue
local task_event = nil
local task_queue = nil
local task_mutex = nil

-- object pool for event and sharedata
local event_pool = {}
local sharedata_pool = {}

-- get event from pool or create new one
function async_task._get_event()
    local event = table.remove(event_pool)
    if not event then
        event = thread.event()
    end
    return event
end

-- return event to pool
function async_task._put_event(event)
    if event then
        table.insert(event_pool, event)
    end
end

-- get sharedata from pool or create new one
function async_task._get_sharedata()
    local sharedata = table.remove(sharedata_pool)
    if not sharedata then
        sharedata = thread.sharedata()
    else
        sharedata:clear()
    end
    return sharedata
end

-- return sharedata to pool
function async_task._put_sharedata(sharedata)
    if sharedata then
        table.insert(sharedata_pool, sharedata)
    end
end

-- the asynchronous task loop
function async_task._loop(event, queue, mutex, is_stopped, is_diagnosis)
    local os = require("base/os")
    local try = require("sandbox/modules/try")
    local thread = require("base/thread")

    local function dprint(...)
        if is_diagnosis then
            print(...)
        end
    end

    local function _restore_thread_objects(cmd)
        if cmd.event_data then
            cmd.event = thread._deserialize_object(cmd.event_data)
        end
        if cmd.result_data then
            cmd.result = thread._deserialize_object(cmd.result_data)
        end
    end

    local function _runcmd_cp(cmd)
        os.cp(cmd.srcpath, cmd.dstpath)
    end
    local function _runcmd_rm(cmd)
        os.rm(cmd.filepath)
    end
    local function _runcmd_rmdir(cmd)
        os.rmdir(cmd.dir)
    end
    local function _runcmd_match(cmd)
        return os.match(cmd.pattern, cmd.mode)
    end
    local runops = {
        cp    = _runcmd_cp,
        rm    = _runcmd_rm,
        rmdir = _runcmd_rmdir,
        match = _runcmd_match
    }
    local function _runcmd(cmd)

        _restore_thread_objects(cmd)

        local ok = true
        local errors
        local result_data
        local runop = runops[cmd.kind]
        if runop then
            try
            {
                function ()
                    local ret = runop(cmd)
                    if ret then
                        result_data = ret
                    end
                end,
                catch
                {
                    function (errs)
                        ok = false
                        errors = tostring(errs)
                    end
                }
            }
        end

        -- notify completion if event is provided
        if cmd.event and cmd.result then
            cmd.result:set({ok = ok, errors = errors, data = result_data})
            cmd.event:post()
        end
    end

    dprint("async_task: started")
    while not is_stopped:get() do
        if event:wait(-1) > 0 then

            -- fetch all tasks from queue at once
            local cmds = {}
            mutex:lock()
            while not queue:empty() do
                local cmd = queue:pop()
                if cmd then
                    table.insert(cmds, cmd)
                end
            end
            mutex:unlock()

            -- execute tasks without holding lock
            for _, cmd in ipairs(cmds) do
                _runcmd(cmd)
            end
        end
    end
    dprint("async_task: exited")
end

-- start the asynchronous task
function async_task._start()
    assert(task_queue == nil and task_event == nil and task_mutex == nil)
    task_event = thread.event()
    task_queue = thread.queue()
    task_mutex = thread.mutex()
    local task_is_stopped = thread.sharedata()
    local task_thread = thread.new(async_task._loop, {
        name = "core.base.async_task", internal = true,
        argv = {task_event, task_queue, task_mutex, task_is_stopped, option.get("diagnosis")}})
    local ok, errors = task_thread:start()
    if not ok then
        return false, errors
    end
    os.atexit(function (errors)
        if task_thread then
            utils.dprint("async_task: wait for exiting ..")
            is_stopped = true
            -- Perhaps the thread hasn't started yet.
            -- Let's wait a while and let it finish executing the tasks in the current queue.
            task_mutex:lock()
            local is_empty = task_queue:empty()
            task_mutex:unlock()
            if not is_empty then
                task_event:post()
                os.sleep(300)
            end
            task_is_stopped:set(true)
            task_event:post()
            task_thread:wait(-1)
        end
    end)
    return true
end

-- ensure the asynchronous task is started
function async_task._ensure_started()
    if is_stopped then
        return false, string.format("async_task has been stopped")
    end
    if not is_started then
        local ok, errors = async_task._start()
        if ok then
            is_started = true
        end
        return ok, errors
    end
    assert(task_queue and task_event)
    return true
end

-- post task and wait for result
function async_task._post_task(cmd, is_detach, return_data)
    local cmd_event, cmd_result

    -- create event and result for non-detach mode
    if not is_detach then
        cmd_event = async_task._get_event()
        cmd_result = async_task._get_sharedata()

        -- serialize thread objects for passing to worker thread
        cmd.event_data = thread._serialize_object(cmd_event)
        cmd.result_data = thread._serialize_object(cmd_result)
    end

    task_mutex:lock()
    task_queue:push(cmd)
    local queue_size = task_queue:size()
    task_mutex:unlock()

    if is_detach then
        -- We cache some tasks before executing them to avoid frequent thread switching.
        if queue_size > 10 then
            task_event:post()
        end
        return true
    else
        -- wait for completion
        task_event:post()
        cmd_event:wait(-1)
        local result = cmd_result:get()
        async_task._put_event(cmd_event)
        async_task._put_sharedata(cmd_result)
        if result and result.ok then
            if return_data then
                return result.data, #result.data
            else
                return true
            end
        else
            if return_data then
                return nil, 0
            else
                return false, result and result.errors or "unknown error"
            end
        end
    end
end

-- copy files or directories
function async_task.cp(srcpath, dstpath, opt)
    opt = opt or {}
    local ok, errors = async_task._ensure_started()
    if not ok then
        return false, errors
    end
    local cmd = {kind = "cp", srcpath = path.absolute(tostring(srcpath)), dstpath = path.absolute(tostring(dstpath))}
    return async_task._post_task(cmd, opt.detach, false)
end

-- remove files or directories
function async_task.rm(filepath, opt)
    opt = opt or {}
    local ok, errors = async_task._ensure_started()
    if not ok then
        return false, errors
    end
    local cmd = {kind = "rm", filepath = path.absolute(tostring(filepath))}
    return async_task._post_task(cmd, opt.detach, false)
end

-- remove directories
function async_task.rmdir(dir, opt)
    opt = opt or {}
    local ok, errors = async_task._ensure_started()
    if not ok then
        return false, errors
    end
    local cmd = {kind = "rmdir", dir = path.absolute(tostring(dir))}
    return async_task._post_task(cmd, opt.detach, false)
end

-- match files or directories
function async_task.match(pattern, mode)
    local ok, errors = async_task._ensure_started()
    if not ok then
        return nil, errors
    end
    local cmd = {kind = "match", pattern = path.absolute(tostring(pattern)), mode = mode}
    return async_task._post_task(cmd, false, true)
end

-- return module: async_task
return async_task

