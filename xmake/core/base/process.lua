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
-- @file        process.lua
--

-- define module: process
local process   = process or {}
local _subprocess = _subprocess or {}

-- load modules
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")
local coroutine = require("base/coroutine")

-- save original interfaces
process._open       = process._open or process.open
process._openv      = process._openv or process.openv
process._wait       = process._wait or process.wait
process._waitlist   = process._waitlist or process.waitlist
process._close      = process._close or process.close
process.wait        = nil
process.close       = nil
process._subprocess = _subprocess

-- new an subprocess
function _subprocess.new(name, proc)
    local subprocess = table.inherit(_subprocess)
    subprocess._NAME = name
    subprocess._PROC = proc
    setmetatable(subprocess, _subprocess)
    return subprocess
end

-- get the process name 
function _subprocess:name()
    return self._NAME
end

-- wait subprocess
--
-- @param timeout   the timeout
--
-- @return          ok, status
--
function _subprocess:wait(timeout)
    if not self._PROC then
        return -1, 0, string.format("subprocess(%s) has been closed!", self:name())
    end
    return process._wait(self._PROC, timeout or -1)
end

-- close subprocess
function _subprocess:close(timeout)
    if not self._PROC then
        return false, string.format("subprocess(%s) has been closed!", self:name())
    end
    local ok = process._close(self._PROC)
    if ok then
        self._PROC = nil
    end
    return ok
end

-- tostring(subprocess)
function _subprocess:__tostring()
    return "subprocess: " .. self:name()
end

-- gc(subprocess)
function _subprocess:__gc()
    if self._PROC and process._close(self._PROC) then
        self._PROC = nil
    end
end

-- open a subprocess
--
-- @param command   the process command
-- @param opt       the option arguments, e.g. {outpath = "", errpath = "", envs = {"PATH=xxx", "XXX=yyy"}}) 
--
-- @return          the subprocess
--
function process.open(command, opt)
    local proc = process._open(command, opt)
    if proc then
        return _subprocess.new(path.filename(command:split(' ', {plain = true})[1]), proc)
    else
        return nil, string.format("open process(%s) failed!", command)
    end
end

-- open a subprocess with the arguments list
--
-- @param shellname the shell name 
-- @param argv      the arguments list
-- @param opt       the option arguments, e.g. {outpath = "", errpath = "", envs = {"PATH=xxx", "XXX=yyy"}}) 
--
-- @return          the subprocess
--
function process.openv(shellname, argv, opt)
    local proc = process._openv(shellname, argv, opt)
    if proc then
        return _subprocess.new(path.filename(shellname), proc)
    else
        return nil, string.format("openv process(%s, %s) failed!", shellname, table.concat(argv, " "))
    end
end

-- wait subprocess list
--
-- count, list = process.waitlist(proclist, timeout)
--
-- count:
--
-- the finished count: > 0
-- timeout: 0
-- failed: -1
-- 
-- for _, procinfo in ipairs(list) do
--    print("proc: ", procinfo[1])
--    print("index: ", procinfo[2])
--    print("status: ", procinfo[3])
-- end
--
function process.waitlist(proclist, timeout)
    local procs = {}
    for _, proc in ipairs(proclist) do
        table.insert(procs, proc._PROC)
    end
    local count, list = process._waitlist(procs, timeout)
    if count > 0 and list then
        for _, procinfo in ipairs(list) do
            local proc = procinfo[1]
            local index = procinfo[2]
            procinfo[1] = proclist[index]
            assert(proc == procinfo[1]._PROC)
        end
    end
    return count, list
end

-- async run task and echo waiting info
function process.asyncrun(task, waitchars)

    -- create a coroutine task
    task = coroutine.create(task)

    -- trace
    local waitindex = 0
    local waitchars = waitchars or {'\\', '|', '/', '-'}
    utils.printf(waitchars[waitindex + 1])
    io.flush()

    -- start and wait this task
    local ok, errors = coroutine.resume(task)
    if not ok then

        -- remove wait charactor
        utils.printf("\b")
        io.flush()

        -- failed
        return false, errors
    end

    -- wait and poll task
    while coroutine.status(task) ~= "dead" do

        -- trace
        waitindex = ((waitindex + 1) % #waitchars)
        utils.printf("\b" .. waitchars[waitindex + 1])
        io.flush()

        -- wait some time
        os.sleep(300)
        
        -- continue to poll this task
        local ok, errors = coroutine.resume(task, 0)
        if not ok then

            -- remove wait charactor
            utils.printf("\b")
            io.flush()

            -- failed
            return false, errors
        end
    end

    -- remove wait charactor
    utils.printf("\b")
    io.flush()

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
        local procs_infos = nil
        if procs_count > 0 then
            local count = -1
            count, procs_infos = process.waitlist(procs, utils.ifelse(#tasks < comax and index <= total, 0, timeout))
            if count < 0 then
                return false, string.format("wait processes(%d) failed(%d)", #procs, count)
            end
        end

        -- timer is triggered? call timer
        if timer and os.mclock() - time > timeout then
            timer(indices)
            time = os.mclock()
        end

        -- append fake procs_infos for coroutine.yield()
        procs_infos = procs_infos or {}
        for taskid = #procs + 1, #tasks do
            table.insert(procs_infos, {nil, taskid, 0})
        end

        -- wait ok
        for _, procinfo in ipairs(procs_infos) do
            
            -- the process info
            local proc      = procinfo[1]
            local taskid    = procinfo[2]
            local status    = procinfo[3]

            -- check
            assert(procs[taskid] == proc)

            -- resume this task
            local job_task = tasks[taskid]
            local ok, job_proc_or_errors = coroutine.resume(job_task, 1, status)
            if not ok then
                return false, job_proc_or_errors
            end

            -- the other process is pending for this task?
            if coroutine.status(job_task) ~= "dead" then
                procs[taskid] = job_proc_or_errors 
            else
                -- mark this task as finished?
                tasks_finished[taskid] = true
            end
        end

        -- update the pending tasks and procs
        local tasks_pending1     = {}
        local procs_pending1     = {}
        local indices_pending1   = {}
        local tasks_pending2     = {}
        local indices_pending2   = {}
        for taskid, job_task in ipairs(tasks) do
            if not tasks_finished[taskid] and procs[taskid] ~= nil then -- for coroutine.yield(proc) in os.execv
                table.insert(tasks_pending1,     job_task)
                table.insert(procs_pending1,     procs[taskid])
                table.insert(indices_pending1,   indices[taskid])
            end
        end
        for taskid, job_task in ipairs(tasks) do
            if not tasks_finished[taskid] and procs[taskid] == nil then -- for coroutine.yield()
                table.insert(tasks_pending2,     job_task)
                table.insert(indices_pending2,   indices[taskid])
            end
        end

        -- produce tasks
        while (#tasks_pending1 + #tasks_pending2) < comax and index <= total do

            -- new task
            local job_task = coroutine.create(jobfunc)

            -- resume it first
            local ok, job_proc_or_errors = coroutine.resume(job_task, index)
            if not ok then
                return false, job_proc_or_errors
            end

            -- add pending tasks
            if coroutine.status(job_task) ~= "dead" then
                if job_proc_or_errors ~= nil then -- for coroutine.yield(proc) in os.execv
                    table.insert(tasks_pending1, job_task)
                    table.insert(procs_pending1, job_proc_or_errors)
                    table.insert(indices_pending1, index)
                else
                    table.insert(tasks_pending2, job_task)
                    table.insert(indices_pending2, index)
                end
            end

            -- next index
            index = index + 1
        end

        -- merge pending tasks
        procs   = procs_pending1
        tasks   = table.join(tasks_pending1, tasks_pending2)
        indices = table.join(indices_pending1, indices_pending2)

    until #tasks == 0

    -- ok
    return true
end

-- return module: process
return process
