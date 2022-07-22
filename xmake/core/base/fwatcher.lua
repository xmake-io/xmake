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

-- define module: fwatcher
local fwatcher   = fwatcher or {}
local _instance = _instance or {}

-- load modules
local string    = require("base/string")
local coroutine = require("base/coroutine")
local scheduler = require("base/scheduler")

-- save original interfaces
fwatcher._open       = fwatcher._open or fwatcher.open
fwatcher._add        = fwatcher._add or fwatcher.add
fwatcher._remove     = fwatcher._remove or fwatcher.remove
fwatcher._wait       = fwatcher._wait or fwatcher.wait
fwatcher._close      = fwatcher._close or fwatcher.close

-- get cdata of fwatcher
function _instance:cdata()
    local cdata = self._CDATA
    if not cdata and not self._CLOSED then
        cdata = fwatcher._open()
        self._CDATA = cdata
    end
    return cdata
end

-- get poller object type, poller.OT_FWATCHER
function _instance:otype()
    return 4
end

-- add watch directory, e.g. {recursion = true}
function _instance:add(watchdir, opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- add watchdir
    opt = opt or {}
    local ok, errors = fwatcher._add(self:cdata(), watchdir, opt.recursion or false)
    if not ok then
        errors = string.format("<fwatcher>: add %s failed, %s", watchdir, errors or "unknown errors")
    end
    return ok, errors
end

-- remove watch directory
function _instance:remove(watchdir)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- remove watchdir
    opt = opt or {}
    local ok, errors = fwatcher._remove(self:cdata(), watchdir)
    if not ok then
        errors = string.format("<fwatcher>: remove %s failed, %s", watchdir, errors or "unknown errors")
    end
    return ok, errors
end

-- wait event
--
-- @param timeout   the timeout
--
-- @return          ok, event
--
function _instance:wait(timeout)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- wait events
    local result = -1
    local event_or_errors = nil
    if scheduler:co_running() then
        result, event_or_errors = scheduler:poller_waitfs(self, timeout or -1)
    else
        result, event_or_errors = fwatcher._wait(self:cdata(), timeout or -1)
    end
    if result < 0 and event_or_errors then
        event_or_errors = string.format("<fwatcher>: wait failed, %s", event_or_errors)
    end
    return result, event_or_errors
end

-- close instance
function _instance:close()

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

    -- close fwatcher
    ok = fwatcher._close(self:cdata())
    if ok then
        self._CDATA = nil
        self._CLOSED = true
    end
    return ok
end

-- ensure the fwatcher is opened
function _instance:_ensure_opened()
    if not self:cdata() then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

function fwatcher.add(watchdir, opt)
    return _instance:add(watchdir, opt)
end

function fwatcher.remove(watchdir)
    return _instance:remove(watchdir)
end

function fwatcher.wait(timeout)
    return _instance:wait(timeout)
end

return fwatcher
