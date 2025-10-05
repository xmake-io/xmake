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

-- print back characters
function _print_backchars(backnum)
    if backnum > 0 then
        local str = ('\b'):rep(backnum) .. (' '):rep(backnum) .. ('\b'):rep(backnum)
        if #str > 0 then
            printf(str)
        end
    end
end

-- init progress
function _init_progress(state, opt)
    opt = opt or {}

    -- init progress helper
    -- we need to hide wait characters if is not a tty
    state.show_progress = io.isatty() and (opt.progress or opt.showtips)
    state.backnum = 0
    if state.show_progress then
        local progress_opt = nil
        if type(state.show_progress) == "table" then
            progress_opt = state.show_progress
        end
        state.progress_helper = progress.new(nil, progress_opt)
    end

    -- init progress wrapper
    state.count = 0
    state.progress_factor = opt.progress_factor or 1.0
    local progress_wrapper = {}
    progress_wrapper.current = function ()
        return state.count
    end
    progress_wrapper.total = function ()
        return state.total
    end
    progress_wrapper.percent = function ()
        local total = state.total
        if total and total > 0 then
            return math.floor((state.count * state.progress_factor * 100) / total)
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

-- the progress loop
function _progress_loop(state)
    local timeout = state.timeout
    local progress_helper = state.progress_helper
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
            progress_helper:clear()
            _print_backchars(state.backnum)

            if tips then
                cprintf("${dim}%s${clear} ", tips)
                state.backnum = #tips + 1
            end
            progress_helper:write()
        end
    end
end

-- comsume jobs
function _comsume_jobs_loop()
end

-- asynchronous run jobs
--
-- e.g.
-- runjobs("test", function (index) print("hello") end, {total = 100, comax = 6, timeout = 1000, on_timer = function (running_jobs_indices) end})
-- runjobs("test", function () os.sleep(10000) end, { progress = true })
-- runjobs("test", function () os.sleep(10000) end, { progress = { chars = {'/','\'} } }) -- see module utils.progress
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
    state.comax = opt.comax or math.min(state.total, 4)
    state.distcc = opt.distcc
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

    -- show waiting tips?
    _init_progress(state, opt)

    -- isolate environments
    local is_isolated = false
    local co_running = scheduler.co_running()
    if co_running and opt.isolate then
        is_isolated = co_running:is_isolated()
        co_running:isolate(true)
    end

    -- run timer
    state.stop = false
    state.running_jobs_indices = {}
    local group_timer
    if opt.on_timer then
        state.on_timer = opt.on_timer
        group_timer = state.group_name .. "/timer"
        scheduler.co_group_begin(group_timer, function (co_group)
            scheduler.co_start_withopt({name = name .. "/timer", isolate = opt.isolate}, _timer_loop, state)
        end)
    elseif state.show_progress then
        group_timer = state.group_name .. "/timer"
        scheduler.co_group_begin(group_timer, function (co_group)
            scheduler.co_start_withopt({name = name .. "/tips", isolate = opt.isolate}, _progress_loop, state)
        end)
    end

    -- run jobs
    local index = 0
    local abort = false
    local abort_errors
    local job_pending
    local total = state.total
    local comax = state.comax
    local distcc = state.distcc
    local group_name = state.group_name
    local jobs_cb = state.jobs_cb
    local jobs = state.jobs
    while index < total do
        scheduler.co_group_begin(group_name, function (co_group)
            local freemax = comax - #co_group
            local local_max = math.min(index + freemax, total)
            local total_max = local_max
            if distcc then
                total_max = math.min(index + freemax + distcc:freejobs(), total)
            end
            local jobfunc = jobs_cb
            while index < total_max do

                -- uses job pool?
                local job
                local jobname
                local distccjob = false
                if not jobs_cb then

                    -- get free job
                    job = job_pending and job_pending or jobs:getfree()
                    if not job then
                        break
                    end

                    -- we can only continue to run the job with distcc if local jobs are full
                    if distcc and index >= local_max then
                        if job.distcc then
                            distccjob = true
                        else
                            job_pending = job
                            break
                        end
                    end

                    -- get run function
                    jobfunc = job.run
                    jobname = job.name
                    job_pending = nil
                else
                    jobname = tostring(index)
                end

                -- start this job
                index = index + 1
                scheduler.co_start_withopt({name = name .. '/' .. jobname, isolate = opt.isolate}, function(i)
                    try
                    {
                        function()
                            if state.stop then
                                return
                            end
                            if distcc then
                                local co_running = scheduler.co_running()
                                if co_running then
                                    co_running:data_set("distcc.distccjob", distccjob)
                                end
                            end
                            state.running_jobs_indices[i] = i
                            if jobfunc then
                                if opt.curdir then
                                    os.cd(opt.curdir)
                                end
                                state.count = state.count + 1
                                jobfunc(i, total, {progress = state.progress_wrapper})
                            end
                            state.running_jobs_indices[i] = nil
                        end,
                        catch
                        {
                            function (errors)

                                -- stop timer and disable show waitchars first
                                state.stop = true

                                -- remove wait charactor
                                if state.show_progress then
                                    _print_backchars(state.backnum)
                                    state.progress_helper:stop()
                                end

                                -- we need re-throw this errors outside scheduler
                                abort = true
                                if abort_errors == nil then
                                    abort_errors = errors
                                end

                                -- kill all waited objects in this group
                                local waitobjs = scheduler.co_group_waitobjs(group_name)
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
                end, index)
            end
        end)

        -- wait for free jobs
        scheduler.co_group_wait(group_name, {limit = 1})
    end

    -- wait all jobs exited
    scheduler.co_group_wait(group_name)

    -- wait timer job exited
    if group_timer then
        state.stop = true
        scheduler.co_group_wait(group_timer)
    end

    -- restore isolated environments
    if co_running and opt.isolate then
        co_running:isolate(is_isolated)
    end

    -- remove wait charactor
    if state.show_progress then
        _print_backchars(state.backnum)
        state.progress_helper:stop()
    end

    -- do exit callback
    if opt.on_exit then
        opt.on_exit(abort_errors)
    end

    -- re-throw abort errors
    --
    -- @note we cannot throw it in coroutine,
    -- because his causes a direct exit from the entire runloop and
    -- a quick escape from nested try-catch blocks and coroutines groups.
    -- so we can not catch runjobs errors, e.g. build fails
    if abort then
        raise(abort_errors)
    end
end
