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
-- @file        process.lua
--

-- load modules
local process   = require("base/process")
local sandbox   = require("sandbox/sandbox")
local raise     = require("sandbox/modules/raise")
local vformat   = require("sandbox/modules/vformat")

-- define module
local sandbox_core_base_process            = sandbox_core_base_process or {}
local sandbox_core_base_instance = sandbox_core_base_instance or {}
sandbox_core_base_process._subprocess = sandbox_core_base_process._subprocess or process._subprocess

-- wait subprocess
function sandbox_core_base_instance.wait(proc, timeout)
    local ok, status_or_errors = proc:_wait(timeout)
    if ok < 0 and status_or_errors then
        raise(status_or_errors)
    end
    return ok, status_or_errors
end

-- kill subprocess
function sandbox_core_base_instance.kill(proc)
    local ok, errors = proc:_kill()
    if not ok then
        raise(errors)
    end
end

-- close subprocess
function sandbox_core_base_instance.close(proc)
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
function sandbox_core_base_process.open(command, opt)

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
    for name, func in pairs(sandbox_core_base_instance) do
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
function sandbox_core_base_process.openv(filename, argv, opt)

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
    for name, func in pairs(sandbox_core_base_instance) do
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

-- return module
return sandbox_core_base_process
