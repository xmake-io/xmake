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
-- @file        thread.lua
--

-- load modules
local utils     = require("base/utils")
local string    = require("base/string")
local thread    = require("thread/thread")
local raise     = require("sandbox/modules/raise")

-- define module
local sandbox_core_thread            = sandbox_core_thread or {}
local sandbox_core_thread_instance   = sandbox_core_thread_instance or {}

-- export the thread status
sandbox_core_thread.STATUS_READY     = thread.STATUS_READY
sandbox_core_thread.STATUS_RUNNING   = thread.STATUS_RUNNING
sandbox_core_thread.STATUS_SUSPENDED = thread.STATUS_SUSPENDED
sandbox_core_thread.STATUS_DEAD      = thread.STATUS_DEAD

-- wrap thread
function _thread_wrap(instance)

    -- hook thread interfaces
    local hooked = {}
    for name, func in pairs(sandbox_core_thread_instance) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = instance["_" .. name] or instance[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        instance[name] = func
    end
    return instance
end

-- start thread
function sandbox_core_thread_instance.start(instance)
    local ok, errors = instance:_start()
    if not ok then
        raise(errors)
    end
    return instance
end

-- suspend thread
function sandbox_core_thread_instance.suspend(instance)
    local ok, errors = instance:_suspend()
    if not ok then
        raise(errors)
    end
end

-- resume thread
function sandbox_core_thread_instance.resume(instance)
    local ok, errors = instance:_resume()
    if not ok then
        raise(errors)
    end
end

-- wait thread
function sandbox_core_thread_instance.wait(instance, timeout)
    local ok, errors = instance:_wait(timeout)
    if ok < 0 then
        raise(errors)
    end
end

-- new thread
function sandbox_core_thread.new(callback, opt)
    local instance, errors = thread.new(callback, opt)
    if not instance then
        raise(errors)
    end
    return _thread_wrap(instance)
end

-- start a thread
function sandbox_core_thread.start(callback, ...)
    return sandbox_core_thread.start_withopt(callback, {argv = table.pack(...)})
end

-- start a named thread
function sandbox_core_thread.start_named(name, callback, ...)
    return sandbox_core_thread.start_withopt(callback, {name = name, argv = table.pack(...)})
end

-- start a thread with options
function sandbox_core_thread.start_withopt(callback, opt)
    return sandbox_core_thread.new(callback, opt):start()
end

-- get the running thread
function sandbox_core_thread.running()
    local instance, errors = thread.running()
    if not instance then
        raise(errors)
    end
    return instance
end

-- return module
return sandbox_core_thread

