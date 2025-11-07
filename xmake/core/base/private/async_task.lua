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
local path   = require("base/path")
local pipe_event = require("base/private/pipe_event")

-- the task status
local is_stopped = false
local is_started = false

-- the task event and queue
local task_event = nil
local task_queue = nil
local task_mutex = nil

-- object pool for sharedata
local sharedata_pool = {}

function async_task._absolute_dirs(searchdirs)
    local dirs = {}
    if searchdirs then
        for _, directory in ipairs(searchdirs) do
            local dir = tostring(directory)
            if #dir > 0 then
                table.insert(dirs, path.absolute(dir))
            end
        end
    end
    return dirs
end

function async_task._get_event()
    return pipe_event.new("async_task")
end

function async_task._put_event(event)
    if event then
        event:close()
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
            local event, errors = thread._deserialize_object(cmd.event_data)
            assert(event, errors or "failed to deserialize event")
            cmd.event = event
        end
        if cmd.result_data then
            local result, errors = thread._deserialize_object(cmd.result_data)
            assert(result, errors or "failed to deserialize result")
            cmd.result = result
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
    local function _runcmd_find_file(cmd)
        local find_file = require("sandbox/modules/import/lib/detect/find_file")
        return find_file._find_from_directories(cmd.name, cmd.searchdirs or {}, cmd.suffixes or {})
    end
    local function _runcmd_find_path(cmd)
        local find_path = require("sandbox/modules/import/lib/detect/find_path")
        return find_path._find_from_directories(cmd.name, cmd.searchdirs or {}, cmd.suffixes or {})
    end
    local function _runcmd_find_directory(cmd)
        local find_directory = require("sandbox/modules/import/lib/detect/find_directory")
        return find_directory._find_from_directories(cmd.name, cmd.searchdirs or {}, cmd.suffixes or {})
    end
    local function _runcmd_find_library(cmd)
        local find_library = require("sandbox/modules/import/lib/detect/find_library")
        return find_library._find_from_directories(cmd.names or {}, cmd.searchdirs or {}, cmd.kinds or {}, cmd.suffixes or {}, cmd.opt or {})
    end
    local runops = {
        cp    = _runcmd_cp,
        rm    = _runcmd_rm,
        rmdir = _runcmd_rmdir,
        match = _runcmd_match,
        find_file = _runcmd_find_file,
        find_path = _runcmd_find_path,
        find_directory = _runcmd_find_directory,
        find_library = _runcmd_find_library
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
            dprint("async_task: handling tasks(%d) ..", #cmds)
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
            is_stopped = true

            -- Perhaps the thread hasn't started yet.
            -- Let's wait a while and let it finish executing the tasks in the current queue.
            utils.dprint("async_task: wait the pending tasks(%d) for exiting ..", task_queue:size())
            task_mutex:lock()
            local is_empty = task_queue:empty()
            task_mutex:unlock()
            if not is_empty then
                task_event:post()
                os.sleep(300)
            end
            task_is_stopped:set(true)
            task_event:post()

            utils.dprint("async_task: wait thread for exiting ..")
            task_thread:wait(-1)
            utils.dprint("async_task: wait finished")
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
    local cmd_event
    local cmd_result

    -- create pipe and result for non-detach mode
    if not is_detach then
        cmd_event = async_task._get_event()
        if not cmd_event then
            return false, "failed to acquire event"
        end
        cmd_result = async_task._get_sharedata()
        cmd.result_data = thread._serialize_object(cmd_result)
        if not cmd.result_data then
            async_task._put_sharedata(cmd_result)
            async_task._put_event(cmd_event)
            return false, "failed to serialize sharedata"
        end
        cmd.event_data = thread._serialize_object(cmd_event)
        if not cmd.event_data then
            async_task._put_sharedata(cmd_result)
            async_task._put_event(cmd_event)
            return false, "failed to serialize event"
        end
    end

    task_mutex:lock()
    task_queue:push(cmd)
    task_mutex:unlock()

    task_event:post()

    if is_detach then
        return true
    end

    local wait_ok, wait_errors = cmd_event:wait(-1)

    local result
    if wait_ok then
        result = cmd_result:get()
    end
    async_task._put_sharedata(cmd_result)
    async_task._put_event(cmd_event)

    if not wait_ok then
        return false, wait_errors or "wait event failed"
    end

    if result and result.ok then
        if return_data then
            local data = result.data
            if type(data) == "table" then
                return data, #data
            elseif data ~= nil then
                return data
            else
                return nil, 0
            end
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

-- find file
function async_task.find_file(name, searchdirs, opt)
    opt = opt or {}
    local ok, errors = async_task._ensure_started()
    if not ok then
        return nil, errors
    end
    local dirs = async_task._absolute_dirs(searchdirs)
    local suffixes = {}
    if opt.suffixes then
        for _, suffix in ipairs(opt.suffixes) do
            table.insert(suffixes, tostring(suffix))
        end
    end
    local cmd = {kind = "find_file", name = tostring(name), searchdirs = dirs, suffixes = suffixes}
    return async_task._post_task(cmd, false, true)
end

-- find path
function async_task.find_path(name, searchdirs, opt)
    opt = opt or {}
    local ok, errors = async_task._ensure_started()
    if not ok then
        return nil, errors
    end
    local dirs = async_task._absolute_dirs(searchdirs)
    local suffixes = {}
    if opt.suffixes then
        for _, suffix in ipairs(opt.suffixes) do
            table.insert(suffixes, tostring(suffix))
        end
    end
    local cmd = {kind = "find_path", name = tostring(name), searchdirs = dirs, suffixes = suffixes}
    return async_task._post_task(cmd, false, true)
end

-- find directory
function async_task.find_directory(name, searchdirs, opt)
    opt = opt or {}
    local ok, errors = async_task._ensure_started()
    if not ok then
        return nil, errors
    end
    local dirs = async_task._absolute_dirs(searchdirs)
    local suffixes = {}
    if opt.suffixes then
        for _, suffix in ipairs(opt.suffixes) do
            table.insert(suffixes, tostring(suffix))
        end
    end
    local cmd = {kind = "find_directory", name = tostring(name), searchdirs = dirs, suffixes = suffixes}
    return async_task._post_task(cmd, false, true)
end

-- find library
function async_task.find_library(names, searchdirs, kinds, opt)
    opt = opt or {}
    local ok, errors = async_task._ensure_started()
    if not ok then
        return nil, errors
    end
    local dirs = async_task._absolute_dirs(searchdirs)
    local suffixes = {}
    if opt.suffixes then
        for _, suffix in ipairs(opt.suffixes) do
            table.insert(suffixes, tostring(suffix))
        end
    end
    local names_list = {}
    if names then
        if type(names) == "table" then
            for _, name in ipairs(names) do
                table.insert(names_list, tostring(name))
            end
        else
            table.insert(names_list, tostring(names))
        end
    end
    local kinds_list = {}
    if kinds then
        for _, kind in ipairs(kinds) do
            table.insert(kinds_list, tostring(kind))
        end
    end
    local cmd = {kind = "find_library", names = names_list, searchdirs = dirs, kinds = kinds_list, suffixes = suffixes, opt = {plat = opt.plat}}
    return async_task._post_task(cmd, false, true)
end

-- return module: async_task
return async_task

