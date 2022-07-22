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
-- @file        fwatcher.lua
--

-- define module
local sandbox_core_base_fwatcher = sandbox_core_base_fwatcher or {}

-- load modules
local fwatcher = require("base/fwatcher")
local raise    = require("sandbox/modules/raise")

-- the fwatcher event type
sandbox_core_base_fwatcher.ET_MODIFY = fwatcher.ET_MODIFY
sandbox_core_base_fwatcher.ET_CREATE = fwatcher.ET_CREATE
sandbox_core_base_fwatcher.ET_DELETE = fwatcher.ET_DELETE

-- add watch directory
function sandbox_core_base_fwatcher.add(watchdir, opt)
    local ok, errors = fwatcher.add(watchdir, opt)
    if not ok then
        raise(errors)
    end
end

-- remove watch directory
function sandbox_core_base_fwatcher.remove(watchdir)
    local ok, errors = fwatcher.remove(watchdir)
    if not ok then
        raise(errors)
    end
end

-- wait event
function sandbox_core_base_fwatcher.wait(timeout)
    local ok, event_or_errors = fwatcher.wait(timeout)
    if ok < 0 and event_or_errors then
        raise(event_or_errors)
    end
    return ok, event_or_errors
end

-- watch watchdirs
function sandbox_core_base_fwatcher.watchdirs(watchdirs, callback, opt)
    local ok, errors = fwatcher.watchdirs(watchdirs, callback, opt)
    if not ok then
        raise(errors)
    end
end

-- watch created file path
function sandbox_core_base_fwatcher.on_created(watchdirs, callback, opt)
    local ok, errors = fwatcher.on_created(watchdirs, callback, opt)
    if not ok then
        raise(errors)
    end
end

-- watch modified file path
function sandbox_core_base_fwatcher.on_modified(watchdirs, callback, opt)
    local ok, errors = fwatcher.on_modified(watchdirs, callback, opt)
    if not ok then
        raise(errors)
    end
end

-- watch deleted file path
function sandbox_core_base_fwatcher.on_deleted(watchdirs, callback, opt)
    local ok, errors = fwatcher.on_deleted(watchdirs, callback, opt)
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_core_base_fwatcher

