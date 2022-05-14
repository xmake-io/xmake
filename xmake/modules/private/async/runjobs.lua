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

-- asynchronous run jobs
--
-- e.g.
-- runjobs("test", function (index) print("hello") end, {total = 100, comax = 6, timeout = 1000, on_timer = function (running_jobs_indices) end})
-- runjobs("test", function () os.sleep(10000) end, { progress = true })
-- runjobs("test", function () os.sleep(10000) end, { progress = { chars = {'/','\'} } }) -- see module utils.progress
--
-- local jobs = jobpool.new()
-- local root = jobs:addjob("job/root", function (idx, total)
--   print(idx, total)
-- end)
-- for i = 1, 3 do
--     local job = jobs:addjob("job/" .. i, function (idx, total)
--         print(idx, total)
--     end, {rootjob = root})
-- end
-- runjobs("test", jobs, {comax = 6, timeout = 1000, on_timer = function (running_jobs_indices) end})
--
-- distributed build:
-- runjobs("test", jobs, {comax = 6, distcc = distcc_build_client.singleton()}
--
function main(name, jobs, opt)

    -- init options
    op = opt or {}
    local total = opt.total or (type(jobs) == "table" and jobs:size()) or 1
    local comax = opt.comax or math.min(total, 4)
    local distcc = opt.distcc
    local timeout = opt.timeout or 500
    local group_name = name
    local jobs_cb = type(jobs) == "function" and jobs or nil
    assert(timeout < 60000, "runjobs: invalid timeout!")
    assert(jobs, "runjobs: no jobs!")

    -- show waiting tips?
    local showprogress = io.isatty() and (opt.progress or opt.showtips) -- we need hide wait characters if is not a tty
    local progress_helper
    local backnum = 0
    if showprogress then
        local opt = nil
        if type(showprogress) == 'table' then opt = showprogress end
        progress_helper = progress.new(nil, opt)
    end

    -- isolate environments
    local is_isolated = false
    local co_running = scheduler.co_running()
    if co_running and opt.isolate then
        is_isolated = co_running:is_isolated()
        co_running:isolate(true)
    end

    -- run timer
    local stop = false
    local running_jobs_indices = {}
    local group_timer
    if opt.on_timer then
        group_timer = group_name .. "/timer"
        scheduler.co_group_begin(group_timer, function (co_group)
            scheduler.co_start_withopt({name = name .. "/timer", isolate = opt.isolate}, function ()
                while not stop do
                    os.sleep(timeout)
                    if not stop then
                        local indices
                        if running_jobs_indices then
                            indices = table.keys(running_jobs_indices)
                        end
                        opt.on_timer(indices)
                    end
                end
            end)
        end)
    elseif showprogress then
        group_timer = group_name .. "/timer"
        scheduler.co_group_begin(group_timer, function (co_group)
            scheduler.co_start_withopt({name = name .. "/tips", isolate = opt.isolate}, function ()
                while not stop do
                    os.sleep(timeout)
                    if not stop then

                        -- show waitchars
                        local tips = nil
                        local waitobjs = scheduler.co_group_waitobjs(group_name)
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
                        _print_backchars(backnum)

                        if tips then
                            cprintf("${dim}%s${clear} ", tips)
                            backnum = #tips + 1
                        end
                        progress_helper:write()
                    end
                end
            end)
        end)
    end

    -- run jobs
    local index = 0
    local count = 0
    local count_as_index = opt.count_as_index
    local priority_prev = 0
    local priority_curr = 0
    local job_pending = nil
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
                local jobname
                local distccjob = false
                if not jobs_cb then

                    -- get job priority
                    local job, priority
                    if job_pending then
                        job = job_pending
                        priority = priority_prev
                    else
                        job, priority = jobs:pop()
                    end
                    if not job then
                        break
                    end

                    -- priority changed? we need wait all running jobs exited
                    priority_curr = priority or priority_prev
                    assert(priority_curr >= priority_prev, "runjobs: invalid priority(%d < %d)!", priority_curr, priority_prev)
                    if priority_curr > priority_prev then
                        job_pending = job
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
                            if distcc then
                                local co_running = scheduler.co_running()
                                if co_running then
                                    co_running:data_set("distcc.distccjob", distccjob)
                                end
                            end
                            running_jobs_indices[i] = i
                            if jobfunc then
                                if opt.curdir then
                                    os.cd(opt.curdir)
                                end
                                jobfunc(count_as_index and count or i, total)
                                count = count + 1
                            end
                            running_jobs_indices[i] = nil
                        end,
                        catch
                        {
                            function (errors)

                                -- stop timer and disable show waitchars first
                                stop = true

                                -- remove wait charactor
                                if showprogress then
                                    _print_backchars(backnum)
                                    progress_helper:stop()
                                end

                                -- do exit callback
                                if opt.on_exit then
                                    opt.on_exit(errors)
                                end

                                -- re-throw this errors and abort scheduler
                                raise(errors)
                            end
                        }
                    }
                end, index)
            end
        end)

        -- need only one job exited if be same priority
        if priority_curr == priority_prev then
            scheduler.co_group_wait(group_name, {limit = 1})
        else
            -- need to wait all running jobs exited first if be different priority
            scheduler.co_group_wait(group_name)
            priority_prev = priority_curr
        end
    end

    -- wait all jobs exited
    scheduler.co_group_wait(group_name)

    -- wait timer job exited
    if group_timer then
        stop = true
        scheduler.co_group_wait(group_timer)
    end

    -- restore isolated environments
    if co_running and opt.isolate then
        co_running:isolate(is_isolated)
    end

    -- remove wait charactor
    if showprogress then
        _print_backchars(backnum)
        progress_helper:stop()
    end

    -- do exit callback
    if opt.on_exit then
        opt.on_exit()
    end
end
