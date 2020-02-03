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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        process.lua
--

-- define module: process
local process   = process or {}
local _subprocess = _subprocess or {}

-- load modules
local io        = require("base/io")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")
local coroutine = require("base/coroutine")
local scheduler = require("base/scheduler")

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

-- get cdata of process
function _subprocess:cdata()
    return self._PROC
end

-- get poller object type, poller.OT_PROC
function _subprocess:otype()
    return 3
end

-- wait subprocess
--
-- @param timeout   the timeout
--
-- @return          ok, status
--
function _subprocess:wait(timeout)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- wait events
    local result = -1
    local status_or_errors = nil
    if scheduler:co_running() then
        result, status_or_errors = scheduler:poller_waitproc(self, timeout or -1)
    else
        result, status_or_errors = process._wait(self:cdata(), timeout or -1)
    end
    if result < 0 and status_or_errors then
        status_or_errors = string.format("%s: %s", self, status_or_errors)
    end
    return result, status_or_errors
end

-- close subprocess
function _subprocess:close(timeout)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- cancel pipe events from the scheduler
    if scheduler:co_running() then
        ok, errors = scheduler:poller_cancel(self)
        if not ok then
            return false, errors
        end
    end

    -- close process
    ok = process._close(self:cdata())
    if ok then
        self._PROC = nil
    end
    return ok
end

-- ensure the process is opened
function _subprocess:_ensure_opened()
    if not self:cdata() then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

-- tostring(subprocess)
function _subprocess:__tostring()
    return "<subprocess: " .. self:name() .. ">"
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
-- @param opt       the option arguments, e.g. {stdout = filepath/file/pipe, stderr = filepath/file/pipe, envs = {"PATH=xxx", "XXX=yyy"}}) 
--
-- @return          the subprocess
--
function process.open(command, opt)
    
    -- get stdout and pass to subprocess
    opt = opt or {}
    local stdout = opt.stdout
    if type(stdout) == "string" then
        opt.outpath = stdout
    elseif type(stdout) == "table" then
        if stdout.otype and stdout:otype() == 2 then
            opt.outpipe = stdout:cdata()
        else
            opt.outfile = stdout:cdata()
        end
    end

    -- get stderr and pass to subprocess
    local stderr = opt.stderr
    if type(stderr) == "string" then
        opt.errpath = stderr
    elseif type(stderr) == "table" then
        if stderr.otype and stderr:otype() == 2 then
            opt.errpipe = stderr:cdata()
        else
            opt.errfile = stderr:cdata()
        end
    end

    -- open subprocess
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
-- @param opt       the option arguments, e.g. {stdout = filepath/file/pipe, stderr = filepath/file/pipe, envs = {"PATH=xxx", "XXX=yyy"}}) 
--
-- @return          the subprocess
--
function process.openv(shellname, argv, opt)

    -- get stdout and pass to subprocess
    opt = opt or {}
    local stdout = opt.stdout
    if type(stdout) == "string" then
        opt.outpath = stdout
    elseif type(stdout) == "table" then
        if stdout.otype and stdout:otype() == 2 then
            opt.outpipe = stdout:cdata()
        else
            opt.outfile = stdout:cdata()
        end
    end

    -- get stderr and pass to subprocess
    local stderr = opt.stderr
    if type(stderr) == "string" then
        opt.errpath = stderr
    elseif type(stderr) == "table" then
        if stderr.otype and stderr:otype() == 2 then
            opt.errpipe = stderr:cdata()
        else
            opt.errfile = stderr:cdata()
        end
    end

    -- open subprocess
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

    -- we need hide wait characters if is not a tty
    local show_wait = io.isatty() 

    -- trace
    local waitindex = 0
    local waitchars = waitchars or {'\\', '-', '/', '|'}
    if show_wait then
        utils.printf(waitchars[waitindex + 1])
    end
    io.flush()

    -- start and wait this task
    local ok, errors = coroutine.resume(task)
    if not ok then

        -- remove wait charactor
        if show_wait then
            utils.printf("\b")
            io.flush()
        end

        -- failed
        return false, errors
    end

    -- wait and poll task
    while coroutine.status(task) ~= "dead" do

        -- trace
        if show_wait then
            waitindex = ((waitindex + 1) % #waitchars)
            utils.printf("\b" .. waitchars[waitindex + 1])
        end
        io.flush()

        -- wait some time
        os.sleep(300)
        
        -- continue to poll this task
        local ok, errors = coroutine.resume(task, 0)
        if not ok then

            -- remove wait charactor
            if show_wait then
                utils.printf("\b")
                io.flush()
            end

            -- failed
            return false, errors
        end
    end

    -- remove wait charactor
    if show_wait then
        utils.printf("\b")
        io.flush()
    end

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
            local tips = nil
            if #procs > 0 then
                local names = {}
                for _, proc in ipairs(procs) do
                    table.insert(names, proc:name())
                end
                names = table.unique(names)
                if #names > 0 then
                    names = table.concat(names, ",")
                    if #names > 16 then
                        names = names:sub(1, 16) .. ".."
                    end
                    tips = string.format("(%d/%s)", #procs, names)
                end
            end
            timer(indices, tips)
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
