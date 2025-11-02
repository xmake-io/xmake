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

-- the task status
local is_stopped = false
local is_started = false

-- the task event and queue
local task_event = nil
local task_queue = nil

-- the asynchronous task loop
function async_task._loop(event, queue, is_stopped)
    print("started")
    --utils.dprint("async_task: started")
    while not is_stopped:get() do
        if event:wait(-1) > 0 then
            while not queue:empty() do
                print(queue:pop())
            end
        end
    end
    print("exit")
    --utils.dprint("async_task: exited")
end

-- start the asynchronous task
function async_task._start()
    assert(task_queue == nil and task_event == nil)
    task_event = thread.event()
    task_queue = thread.queue()
    local task_is_stopped = thread.sharedata()
    local task_thread = thread.new(async_task._loop, {name = "core.base.async_task", argv = {task_event, task_queue, task_is_stopped}})
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
            if not task_queue:empty() then
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

-- copy files or directories
function async_task.cp(srcpath, dstpath, opt)
    local ok, errors = async_task._ensure_started()
    if not ok then
        return false, errors
    end

    task_queue:push({kind = "cp", srcpath = srcpath, dstpath = dstpath})
    task_event:post()
    return true
end

-- remove files or directories
function async_task.rm(filepath, opt)
    local ok, errors = async_task._ensure_started()
    if not ok then
        return false, errors
    end

    task_queue:push({kind = "rm", filepath = filepath})
    task_event:post()
    return true
end

-- remove directories
function async_task.rmdir(dir, opt)
    local ok, errors = async_task._ensure_started()
    if not ok then
        return false, errors
    end

    task_queue:push({kind = "rmdir", dir = dir})
    task_event:post()
    return true
end

-- return module: async_task
return async_task

