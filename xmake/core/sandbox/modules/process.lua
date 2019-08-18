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

-- load modules
local process   = require("base/process")
local sandbox   = require("sandbox/sandbox")
local raise     = require("sandbox/modules/raise")
local vformat   = require("sandbox/modules/vformat")

-- define module
local sandbox_process            = sandbox_process or {}
local sandbox_process_subprocess = sandbox_process_subprocess or {}
sandbox_process._subprocess = sandbox_process._subprocess or process._subprocess

-- wait subprocess
function sandbox_process_subprocess.wait(proc, timeout)
    local ok, status, errors = proc:_wait(timeout)
    if errors then
        raise(errors)
    end
    return ok, status
end

-- close subprocess
function sandbox_process_subprocess.close(proc)
    local ok, errors = proc:_close()
    if not ok then
        raise(errors)
    end
end

-- open process
---
-- @param command   the command
-- @param opt       the arguments option, {outpath = "", errpath = "", envs = {"PATH=xxx", "XXX=yyy"}
-- 
function sandbox_process.open(command, opt) 

    -- check
    assert(command)

    -- format command first
    command = vformat(command)

    -- open process
    local proc, errors = process.open(command, opt)
    if not proc then
        raise(errors)
    end

    -- hook subprocess interfaces
    local hooked = {}
    for name, func in pairs(sandbox_process_subprocess) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = proc["_" .. name] or proc[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        proc[name] = func
    end
    return proc
end

-- open process with arguments
--
-- @param filename  the command/file name
-- @param argv      the command arguments
-- @param opt       the arguments option, {outpath = "", errpath = "", envs = {"PATH=xxx", "XXX=yyy"}
-- 
function sandbox_process.openv(filename, argv, opt) 

    -- check
    assert(argv)

    -- format filename first
    filename = vformat(filename)

    -- open process
    local proc, errors = process.openv(filename, argv, opt)
    if not proc then
        raise(errors)
    end

    -- hook subprocess interfaces
    local hooked = {}
    for name, func in pairs(sandbox_process_subprocess) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = proc["_" .. name] or proc[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        proc[name] = func
    end
    return proc
end

-- wait processes
function sandbox_process.waitlist(processes, timeout)

    -- check
    assert(processes)

    -- wait them
    local count, infos = process.waitlist(processes, timeout)
    if count < 0 then
        raise("wait processes(%d) failed(%d)", #processes, count)
    end

    -- timeout or finished
    return infos
end

-- async run task and echo waiting info
function sandbox_process.asyncrun(task, waitchars)

    -- async run it
    local ok, errors = process.asyncrun(task, waitchars)
    if not ok then
        raise(errors)
    end
end

-- run jobs with processes
function sandbox_process.runjobs(jobfunc, total, comax, timeout, timer)

    -- run them
    local ok, errors = process.runjobs(jobfunc, total, comax, timeout, timer)
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_process
