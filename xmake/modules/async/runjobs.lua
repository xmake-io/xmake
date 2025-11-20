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
-- @file        runjobs.lua
--

-- imports
import("core.base.scheduler")
import("utils.progress")
import("utils.waiting_indicator")

-- print back characters
function _print_backchars(backnum)
    if backnum > 0 then
        local str = ('\b'):rep(backnum) .. (' '):rep(backnum) .. ('\b'):rep(backnum)
        if #str > 0 then
            printf(str)
        end
    end
end

-- init waiting indicator
function _init_waiting_indicator(state, opt)
    opt = opt or {}
    
    -- init waiting indicator helper
    -- we need to hide wait characters if is not a tty
    local waiting_indicator_opt = opt.waiting_indicator
    state.show_waiting_indicator = io.isatty() and (waiting_indicator_opt == true or type(waiting_indicator_opt) == "table")
    state.backnum = 0
    if state.show_waiting_indicator then
        local indicator_opt = nil
        if type(waiting_indicator_opt) == "table" then
            indicator_opt = waiting_indicator_opt
        end
        state.waiting_indicator_helper = waiting_indicator.new(nil, indicator_opt)
    end
end

-- init progress
function _init_progress(state, opt)
    opt = opt or {}

    -- init progress wrapper
    state.progress_finished_count = 0
    state.progress_factor = opt.progress_factor or 1.0
    local progress_wrapper = {}
    progress_wrapper.current = function ()
        return state.progress_finished_count
    end
    progress_wrapper.total = function ()
        return state.total
    end
    progress_wrapper.percent = function ()
        local total = state.total
        if total and total > 0 then
            return math.floor((state.progress_finished_count * state.progress_factor * 100) / total)
        else
            return 0
        end
    end
    debug.setmetatable(progress_wrapper, {
        __tostring = function ()
            return string.format("%d%%", progress_wrapper.percent())
        end
    })
    state.progress_wrapper = progress_wrapper

    -- init progress refresh timeout (for multirow progress refresh timer)
    state.progress_refresh_timeout = 500
end

-- start timer (on_timer callback)
function _start_timer(state, name, opt)
    if opt.on_timer then
        state.on_timer = opt.on_timer
        state.group_timer = state.group_name .. "/timer"
        scheduler.co_group_begin(state.group_timer, function (co_group)
            scheduler.co_start_withopt({name = name .. "/timer", isolate = opt.isolate}, _timer_loop, state)
        end)
    end
end

-- start waiting indicator timer
function _start_waiting_indicator_timer(state, name, opt)
    if state.show_waiting_indicator then
        state.group_waiting_indicator_timer = state.group_name .. "/waiting_indicator"
        scheduler.co_group_begin(state.group_waiting_indicator_timer, function (co_group)
            scheduler.co_start_withopt({name = name .. "/waiting_indicator", isolate = opt.isolate}, _waiting_indicator_loop, state)
        end)
    end
end

-- start progress refresh timer for multirow progress
function _start_progress_refresh_timer(state, name, opt)
    if opt.progress_refresh and progress.is_multirow() then
        state.group_progress_refresh_timer = state.group_name .. "/progress_refresh"
        state.all_tasks_started = false
        -- create semaphore for refresh loop
        state.progress_refresh_semaphore = scheduler.co_semaphore(state.group_name .. "/progress_refresh", 0)
        -- start progress refresh loop
        scheduler.co_group_begin(state.group_progress_refresh_timer, function (co_group)
            scheduler.co_start_withopt({name = name .. "/progress_refresh", isolate = opt.isolate}, _progress_refresh_loop, state)
        end)
    end
end

-- start all timers
function _start_timers(state, name, opt)
    _start_timer(state, name, opt)
    _start_waiting_indicator_timer(state, name, opt)
    _start_progress_refresh_timer(state, name, opt)
end

-- stop all timers and notify them to exit
function _stop_timers(state)
    -- signal progress refresh loop to exit quickly
    if state.group_progress_refresh_timer and state.progress_refresh_semaphore then
        state.progress_refresh_semaphore:post(1)
    end
end

-- wait all timer jobs exited
function _wait_timers(state)
    if state.group_timer then
        scheduler.co_group_wait(state.group_timer)
    end
    if state.group_waiting_indicator_timer then
        scheduler.co_group_wait(state.group_waiting_indicator_timer)
    end
    if state.group_progress_refresh_timer then
        scheduler.co_group_wait(state.group_progress_refresh_timer)
    end
end

-- exit waiting indicator
function _exit_waiting_indicator(state)
    if state.show_waiting_indicator then
        _print_backchars(state.backnum)
        state.waiting_indicator_helper:stop()
    end
end

-- exit progress
function _exit_progress(state)
    progress.show_abort()
end

-- the timer loop
function _timer_loop(state)
    local timeout = state.timeout
    while not state.stop do
        os.sleep(timeout)
        if not state.stop then
            local indices
            if state.running_jobs_indices then
                indices = table.keys(state.running_jobs_indices)
            end
            state.on_timer(indices)
        end
    end
end

-- the refresh loop for multirow progress (independent timer with its own timeout)
function _progress_refresh_loop(state)
    -- wait until all tasks have been started using semaphore
    if state.progress_refresh_semaphore and not state.stop then
        state.progress_refresh_semaphore:wait(-1)
    else
        return
    end

    -- start refreshing progress using semaphore wait with timeout for quick exit
    while not state.stop do
        -- wait for refresh timeout, allows quick exit when state.stop is set via post
        state.progress_refresh_semaphore:wait(state.progress_refresh_timeout)

        -- refresh progress if not stopped
        if not state.stop then
            progress.refresh()
        end
    end
end

-- the waiting indicator loop
function _waiting_indicator_loop(state)
    local timeout = state.timeout
    local waiting_indicator_helper = state.waiting_indicator_helper
    while not state.stop do
        os.sleep(timeout)
        if not state.stop then

            -- show waitchars
            local tips = nil
            local waitobjs = scheduler.co_group_waitobjs(state.group_name)
            if waitobjs:size() > 0 then
                local names = {}
                for _, obj in waitobjs:keys() do
                    if obj:otype() == scheduler.OT_PROC then
                        table.insert(names, obj:name())
                    elseif obj:otype() == scheduler.OT_SOCK then
                        table.insert(names, "sock")
                    elseif obj:otype() == scheduler.OT_PIPE then
                        table.insert(names, "pipe")
                    end
                end
                names = table.unique(names)
                if #names > 0 then
                    names = table.concat(names, ",")
                    if #names > 16 then
                        names = names:sub(1, 16) .. ".."
                    end
                    tips = string.format("(%d/%s)", waitobjs:size(), names)
                end
            end

            -- print back characters
            waiting_indicator_helper:clear()
            _print_backchars(state.backnum)

            if tips then
                cprintf("${dim}%s${clear} ", tips)
                state.backnum = #tips + 1
            end
            waiting_indicator_helper:write()
        end
    end
end

-- consume jobs
function _consume_jobs_loop(state, run_in_remote)
    local jobs = state.jobs
    local jobs_cb = state.jobs_cb
    local total = state.total
    local curdir = state.curdir
    local semaphore = state.semaphore
    local distcc_semaphore = state.distcc_semaphore
    local co_running = scheduler.co_running()
    while state.finished_count < total and not state.stop do

        -- get free job
        local job
        local job_func = jobs_cb
        local job_distcc = false
        if not job_func then
            job = jobs:getfree()
            if job then
                if job.distcc then
                    job_distcc = true
                end
                job_func = job.run
                -- notify other coroutines to consume jobs
                if run_in_remote then
                    if state.distcc_waiting_count > 0 then
                        local left_count = total - state.finished_count
                        local post_count = math.min(left_count, state.distcc_waiting_count)
                        distcc_semaphore:post(post_count)
                    end
                else
                    if state.waiting_count > 0 then
                        local left_count = total - state.finished_count
                        local post_count = math.min(left_count, state.waiting_count)
                        semaphore:post(post_count)
                    end
                end
            elseif state.finished_count < total then
                -- no free jobs now, wait other coroutines
                if run_in_remote then
                    state.distcc_waiting_count = state.distcc_waiting_count + 1
                    distcc_semaphore:wait(-1)
                    state.distcc_waiting_count = state.distcc_waiting_count - 1
                else
                    state.waiting_count = state.waiting_count + 1
                    semaphore:wait(-1)
                    state.waiting_count = state.waiting_count - 1
                end
            else
                break
            end
        end

        try
        {
            function ()

                -- mark the current coroutine to run remote job
                if run_in_remote and co_running then
                    co_running:data_set("distcc.distccjob", job_distcc)
                end

                -- run job
                co_running:data_set("runjobs.running", true)
                local job_index = state.finished_count + 1
                state.running_jobs_indices[job_index] = job_index
                if job_func then
                    if curdir then
                        os.cd(curdir)
                    end

                    -- to avoid running the same task repeatedly,
                    -- we need to update the completion count in advance.
                    state.finished_count = state.finished_count + 1

                    -- check if all tasks have been started (all consumed, but may still be running)
                    if state.finished_count >= total and not state.all_tasks_started then
                        state.all_tasks_started = true
                        -- notify refresh loop that all tasks have been started
                        if state.progress_refresh_semaphore then
                            state.progress_refresh_semaphore:post(1)
                        end
                    end

                    job_func(job_index, total, {progress = state.progress_wrapper})

                    -- update progress
                    state.progress_finished_count = state.progress_finished_count + 1
                end
                state.running_jobs_indices[job_index] = nil
                co_running:data_set("runjobs.running", false)
            end,
            catch
            {
                function (errors)
                    -- stop timer and disable show waitchars first
                    state.stop = true

                    -- stop progress and waiting indicator
                    _exit_progress(state)
                    _exit_waiting_indicator(state)

                    -- we need re-throw this errors outside scheduler
                    state.abort = true
                    if state.abort_errors == nil then
                        state.abort_errors = errors
                    end

                    -- kill all waited objects in this group
                    local waitobjs = scheduler.co_group_waitobjs(state.group_name)
                    if waitobjs:size() > 0 then
                        for _, obj in waitobjs:keys() do
                            -- TODO, kill pipe is not supported now
                            if obj.kill then
                                obj:kill()
                            end
                        end
                    end
                end
            },
            finally
            {
                function ()
                    if job then
                        jobs:remove(job)
                    end
                end
            }
        }
    end

    -- notify left waiting coroutines
    if state.distcc_waiting_count > 0 then
        distcc_semaphore:post(state.distcc_waiting_count)
    end
    if state.waiting_count > 0 then
        semaphore:post(state.waiting_count)
    end
end

-- asynchronous run jobs
--
-- e.g.
-- runjobs("test", function (index) print("hello") end, {total = 100, comax = 6, timeout = 1000, on_timer = function (running_jobs_indices) end})
-- runjobs("test", function () os.sleep(10000) end, { waiting_indicator = true })
-- runjobs("test", function () os.sleep(10000) end, { waiting_indicator = { chars = {'/','\'} } }) -- see module utils.waiting_indicator
-- runjobs("test", function () os.sleep(10000) end, { waiting_indicator = true, progress_refresh = true }) -- enable progress refresh timer for multirow progress
--
-- local jobs = jobpool.new()
-- local root = jobs:addjob("job/root", function (index, total, opt)
--   print(index, total, opt.progress)
-- end)
-- for i = 1, 3 do
--     local job = jobs:addjob("job/" .. i, function (index, total, opt)
--         print(index, total, opt.progress)
--     end, {rootjob = root})
-- end
-- runjobs("test", jobs, {comax = 6, timeout = 1000, on_timer = function (running_jobs_indices) end})
--
-- distributed build:
-- runjobs("test", jobs, {comax = 6, distcc = distcc_build_client.singleton()}
--
function main(name, jobs, opt)
    opt = opt or {}

    -- init state
    local state = {}
    state.total = opt.total or (type(jobs) == "table" and jobs:size()) or 1
    state.comax = opt.comax and tonumber(opt.comax) or math.min(state.total, 4)
    state.timeout = opt.timeout or 500
    state.group_name = name
    state.jobs_cb = type(jobs) == "function" and jobs or nil
    assert(state.timeout < 60000, "runjobs: invalid timeout!")

    -- build jobs queue
    if type(jobs) == "table" and jobs.build then
        jobs = jobs:build()
    end
    assert(jobs, "runjobs: no jobs!")
    state.jobs = jobs

    -- init waiting indicator
    _init_waiting_indicator(state, opt)
    
    -- init progress
    _init_progress(state, opt)

    -- isolate environments
    local is_isolated = false
    local co_running = scheduler.co_running()
    if co_running and opt.isolate then
        is_isolated = co_running:is_isolated()
        co_running:isolate(true)
    end

    -- init timer state
    state.stop = false
    state.running_jobs_indices = {}

    -- start all timers
    _start_timers(state, name, opt)

    -- run jobs
    local distcc = opt.distcc
    state.abort = false
    state.abort_errors = nil
    state.finished_count = 0
    state.curdir = opt.curdir
    state.waiting_count = 0
    state.distcc_waiting_count = 0
    scheduler.co_group_begin(state.group_name, function (co_group)
        state.semaphore = scheduler.co_semaphore(state.group_name, 0)
        if distcc then
            state.distcc_semaphore = scheduler.co_semaphore(state.group_name .. "/distcc", 0)
        end
        -- @note we can set `remote_only = true` to run all jobs in remote only
        local local_comax = 0
        if not opt.remote_only then
            local_comax = math.min(state.total, state.comax)
            for id = 1, local_comax do
                scheduler.co_start_withopt({name = name .. '/' .. tostring(id), isolate = opt.isolate}, _consume_jobs_loop, state, false)
            end
        end
        if distcc then
            local left_comax = state.total - local_comax
            local remote_comax = math.min(distcc:freejobs(), left_comax)
            for id = 1, remote_comax do
                scheduler.co_start_withopt({name = name .. '/distcc/' .. tostring(id), isolate = opt.isolate}, _consume_jobs_loop, state, true)
            end
        end
    end)

    -- wait all jobs exited
    scheduler.co_group_wait(state.group_name)

    -- stop all timers and notify them to exit
    state.stop = true
    _stop_timers(state)
    
    -- wait all timer jobs exited
    _wait_timers(state)

    -- restore isolated environments
    if co_running and opt.isolate then
        co_running:isolate(is_isolated)
    end

    -- exit progress
    _exit_progress(state)

    -- exit waiting indicator
    _exit_waiting_indicator(state)

    -- do exit callback
    if opt.on_exit then
        opt.on_exit(state.abort_errors)
    end

    -- re-throw abort errors
    --
    -- @note we cannot throw it in coroutine,
    -- because his causes a direct exit from the entire runloop and
    -- a quick escape from nested try-catch blocks and coroutines groups.
    -- so we can not catch runjobs errors, e.g. build fails
    if state.abort then
        raise(state.abort_errors)
    end
end
