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
-- @file        scheduler.lua
--

-- define module
local sandbox_core_base_scheduler = sandbox_core_base_scheduler or {}

-- load modules
local poller    = require("base/poller")
local scheduler = require("base/scheduler")
local raise     = require("sandbox/modules/raise")

-- the poller object type
sandbox_core_base_scheduler.OT_SOCK = poller.OT_SOCK
sandbox_core_base_scheduler.OT_PIPE = poller.OT_PIPE
sandbox_core_base_scheduler.OT_PROC = poller.OT_PROC

-- start a new coroutine task
function sandbox_core_base_scheduler.co_start(cotask, ...)
    local co, errors = scheduler:co_start(cotask, ...)
    if not co then
        raise(errors)
    end
    return co
end

-- start a new named coroutine task
function sandbox_core_base_scheduler.co_start_named(coname, cotask, ...)
    local co, errors = scheduler:co_start_named(coname, cotask, ...)
    if not co then
        raise(errors)
    end
    return co
end

-- start a new coroutine task with options
function sandbox_core_base_scheduler.co_start_withopt(opt, cotask, ...)
    local co, errors = scheduler:co_start_withopt(opt, cotask, ...)
    if not co then
        raise(errors)
    end
    return co
end

-- resume the given coroutine
function sandbox_core_base_scheduler.co_resume(co, ...)
    return scheduler:resume(co:thread(), ...)
end

-- suspend the current coroutine
function sandbox_core_base_scheduler.co_suspend(...)
    return scheduler:co_suspend(...)
end

-- yield the current coroutine
function sandbox_core_base_scheduler.co_yield()
    local ok, errors = scheduler:co_yield()
    if not ok then
        raise(errors)
    end
end

-- sleep some times (ms)
function sandbox_core_base_scheduler.co_sleep(ms)
    local ok, errors = scheduler:co_sleep(ms)
    if not ok then
        raise(errors)
    end
end

-- get coroutine group with the given name
function sandbox_core_base_scheduler.co_group(name)
    return scheduler:co_group(name)
end

-- begin coroutine group with the given name
function sandbox_core_base_scheduler.co_group_begin(name, scopefunc)
    local ok, errors = scheduler:co_group_begin(name, scopefunc)
    if not ok then
        raise(errors)
    end
end

-- wait for finishing the given coroutine group
function sandbox_core_base_scheduler.co_group_wait(name, opt)
    local ok, errors = scheduler:co_group_wait(name, opt)
    if not ok then
        raise(errors)
    end
end

-- get the waiting poller objects of the given coroutine group
function sandbox_core_base_scheduler.co_group_waitobjs(name)
    return scheduler:co_group_waitobjs(name)
end

-- get the current running coroutine
function sandbox_core_base_scheduler.co_running()
    return scheduler:co_running()
end

-- get the all coroutine task count
function sandbox_core_base_scheduler.co_count()
    return scheduler:co_count()
end

-- return module
return sandbox_core_base_scheduler
