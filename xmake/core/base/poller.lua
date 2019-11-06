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
-- @file        poller.lua
--

-- define module
local poller = poller or {}

-- load modules
local io     = require("base/io")
local string = require("base/string")

-- get socket events from poller
function poller:events(sock)
    return self._CACHE and self._CACHE[sock] or nil
end

-- set socket events to poller
function poller:events_set(sock, events)
    local cache = self._CACHE 
    if not cache then
        cache = {}
        self._CACHE = cache
    end
    cache[sock] = events
end

-- insert socket events to poller
function poller:insert(sock, events)

    -- ensure opened
    local ok, errors = sock:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- insert it
    if not io.poller_insert(sock._SOCK, events) then
        return false, string.format("insert %s events(%d) to poller failed!", sock, events)
    end

    -- save this socket events and save sock/ref for gc
    self:events_set(sock, events)
    return true
end

-- modify socket events in poller
function poller:modify(sock, events)

    -- ensure opened
    local ok, errors = sock:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- modify it
    if not io.poller_modify(sock._SOCK, events) then
        return false, string.format("modify %s events(%d) to poller failed!", sock, events)
    end

    -- update this socket events 
    self:events_set(sock, events)
    return true
end

-- remove socket from poller
function poller:remove(sock)

    -- ensure opened
    local ok, errors = sock:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- remove it
    if not io.poller_remove(sock._SOCK) then
        return false, string.format("remove %s from poller failed!", sock)
    end

    -- remove this socket events
    self:events_set(sock, nil)
    return true
end

-- wait socket events in poller
function poller:wait(timeout)

    -- wait it
    local sockevents, count = io.poller_wait(timeout or -1) 
    if count < 0 then
        return -1, "wait events in poller failed!"
    end

    -- TODO, wrap socket
    if sockevents then
        for i, v in ipairs(sockevents) do
        end
    end
    return count, sockevents
end

-- return module
return poller
