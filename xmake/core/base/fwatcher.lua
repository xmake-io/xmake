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
fwatcher._wait       = fwatcher._wait or fwatcher.wait
fwatcher._close      = fwatcher._close or fwatcher.close

-- get cdata of fwatcher
function _instance:cdata()
    local cdata = self._CDATA
    if not cdata then
        cdata = fwatcher._open()
        self._CDATA = cdata
    end
    return cdata
end

-- get poller object type, poller.OT_FWATCHER
function _instance:otype()
    return 4
end

-- wait event
--
-- @param timeout   the timeout
--
-- @return          ok, status
--
function _instance:wait(timeout)

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
        result, status_or_errors = fwatcher._wait(self:cdata(), timeout or -1)
    end
    if result < 0 and status_or_errors then
        status_or_errors = string.format("%s: %s", self, status_or_errors)
    end
    return result, status_or_errors
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

setmetatable(_instance, {
        __tostring = function()
            return "<fwatcher>"
        end,
        __gc = function(self)
            if self._CDATA and fwatcher._close(self._CDATA) then
                self._CDATA = nil
            end
        end
    })
return _instance
