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
-- @file        pipe.lua
--

-- load modules
local utils     = require("base/utils")
local pipe      = require("base/pipe")
local string    = require("base/string")
local raise     = require("sandbox/modules/raise")

-- define module
local sandbox_core_base_pipe            = sandbox_core_base_pipe or {}
local sandbox_core_base_pipe_instance   = sandbox_core_base_pipe_instance or {}

-- export the pipe events
sandbox_core_base_pipe.EV_READ  = pipe.EV_READ
sandbox_core_base_pipe.EV_WRITE = pipe.EV_WRITE
sandbox_core_base_pipe.EV_CONN  = pipe.EV_CONN

-- wrap pipe file
function _pipefile_wrap(pipefile)

    -- hook pipe interfaces
    local hooked = {}
    for name, func in pairs(sandbox_core_base_pipe_instance) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = pipefile["_" .. name] or pipefile[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        pipefile[name] = func
    end
    return pipefile
end

-- wait pipe events
function sandbox_core_base_pipe_instance.wait(pipefile, events, timeout)
    local events, errors = pipefile:_wait(events, timeout)
    if events < 0 and errors then
        raise(errors)
    end
    return events
end

-- connect pipe, only for named pipe (server-side)
function sandbox_core_base_pipe_instance.connect(pipefile, opt)
    local ok, errors = pipefile:_connect(opt)
    if ok < 0 and errors then
        raise(errors)
    end
    return ok
end

-- write data to pipe file
function sandbox_core_base_pipe_instance.write(pipefile, data, opt)
    local real, errors = pipefile:_write(data, opt)
    if real < 0 and errors then
        raise(errors)
    end
    return real
end

-- read data from pipe file
function sandbox_core_base_pipe_instance.read(pipefile, buff, size, opt)
    local real, data_or_errors = pipefile:_read(buff, size, opt)
    if real < 0 and data_or_errors then
        raise(data_or_errors)
    end
    return real, data_or_errors
end

-- close pipe file
function sandbox_core_base_pipe_instance.close(pipefile)
    local ok, errors = pipefile:_close()
    if not ok then
        raise(errors)
    end
end

-- open a named pipe file
function sandbox_core_base_pipe.open(name, mode, buffsize)
    local pipefile, errors = pipe.open(name, mode, buffsize)
    if not pipefile then
        raise(errors)
    end
    return _pipefile_wrap(pipefile)
end

-- open a anonymous pipe pair
function sandbox_core_base_pipe.openpair(mode, buffsize)
    local rpipefile, wpipefile, errors = pipe.openpair(mode, buffsize)
    if not rpipefile or not wpipefile then
        raise(errors)
    end
    return _pipefile_wrap(rpipefile), _pipefile_wrap(wpipefile)
end

-- return module
return sandbox_core_base_pipe

