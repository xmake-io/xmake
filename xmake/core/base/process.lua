--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        process.lua
--

-- define module: process
local process = process or {}

-- load modules
local utils     = require("base/utils")
local string    = require("base/string")
local coroutine = require("base/coroutine")

-- async run task and echo waiting info
function process.asyncrun(task, waitchars)

    -- create a coroutine task
    task = coroutine.create(task)

    -- trace
    local waitindex = 0
    local waitchars = waitchars or {'\\', '|', '/', '-'}
    utils.printf(waitchars[waitindex + 1])

    -- start and wait this task
    local ok, errors = coroutine.resume(task)
    if not ok then

        -- remove wait charactor
        utils.printf("\b")

        -- failed
        return false, errors
    end

    -- wait and poll task
    while coroutine.status(task) ~= "dead" do

        -- trace
        waitindex = ((waitindex + 1) % #waitchars)
        utils.printf("\b" .. waitchars[waitindex + 1])

        -- wait some time
        os.sleep(300)
        
        -- continue to poll this task
        local ok, errors = coroutine.resume(task, 0)
        if not ok then

            -- remove wait charactor
            utils.printf("\b")

            -- failed
            return false, errors
        end
    end

    -- remove wait charactor
    utils.printf("\b")

    -- ok
    return true
end

-- run jobs with processes
function process.runjobs(jobfunc, total, comax, timeout, timer)

    -- init max coroutine count
    comax = comax or total

    -- init timeout
    timeout = timeout or -1

    -- make objects
    local index   = 1
    local tasks   = {}
    local procs   = {}
    local indices = {}
    local time    = os.mclock()
    repeat

        -- wait processes
        local tasks_finished = {}
        local procs_count = #procs
        if procs_count > 0 then

            -- wait them
            local count, procinfos = process.waitlist(procs, utils.ifelse(procs_count < comax and index <= total, 0, timeout))
            if count < 0 then
                return false, string.format("wait processes(%d) failed(%d)", #procs, count)
            end

            -- timer is triggered? call timer
            if timer and os.mclock() - time > timeout then
                timer(indices)
                time = os.mclock()
            end

            -- wait ok
            for _, procinfo in ipairs(procinfos) do
                
                -- the process info
                local proc      = procinfo[1]
                local procid    = procinfo[2]
                local status    = procinfo[3]

                -- check
                assert(procs[procid] == proc)

                -- resume this task
                local job_task = tasks[procid]
                local ok, job_proc_or_errors = coroutine.resume(job_task, 1, status)
                if not ok then
                    return false, job_proc_or_errors
                end

                -- the other process is pending for this task?
                if coroutine.status(job_task) ~= "dead" then

                    -- check
                    assert(job_proc_or_errors)

                    -- update the pending process
                    procs[procid] = job_proc_or_errors

                -- this task has been finised?
                else

                    -- mark this task as finised
                    tasks_finished[procid] = true
                end
            end
        end

        -- update the pending tasks and procs
        local tasks_pending     = {}
        local procs_pending     = {}
        local indices_pending   = {}
        for taskid, job_task in ipairs(tasks) do
            if not tasks_finished[taskid] then
                table.insert(tasks_pending,     job_task)
                table.insert(procs_pending,     procs[taskid])
                table.insert(indices_pending,   indices[taskid])
            end
        end
        tasks   = tasks_pending
        procs   = procs_pending
        indices = indices_pending

        -- produce tasks
        while #tasks < comax and index <= total do

            -- new task
            local job_task = coroutine.create(jobfunc)

            -- resume it first
            local ok, job_proc_or_errors = coroutine.resume(job_task, index)
            if not ok then
                return false, job_proc_or_errors
            end

            -- add pending tasks
            if coroutine.status(job_task) ~= "dead" then

                -- check
                assert(job_proc_or_errors)

                -- put task and proc to the pendings tasks
                table.insert(tasks, job_task)
                table.insert(procs, job_proc_or_errors)
                table.insert(indices, index)
            end

            -- next index
            index = index + 1
        end

    until #tasks == 0

    -- ok
    return true
end

-- return module: process
return process
