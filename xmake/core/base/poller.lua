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

-- the poller object type
poller.OT_SOCK = 1
poller.OT_PROC = 2
poller.OT_PIPE = 3

-- get socket wait data 
function poller:_sockdata(sock)
    return self._CACHE and self._CACHE[sock] or nil
end

-- set socket wait data
function poller:_sockdata_set(sock, data)
    local cache = self._CACHE 
    if not cache then
        cache = {}
        self._CACHE = cache
    end
    cache[sock] = data
end

-- insert socket events to poller
function poller:_insert_sock(sock, events, udata)

    -- ensure opened
    local ok, errors = sock:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- insert it
    if not io.poller_insert(sock:csock(), events) then
        return false, string.format("%s: insert events(%d) to poller failed!", sock, events)
    end

    -- save socket data and save sock/ref for gc
    self:_sockdata_set(sock:csock(), udata)
    return true
end

-- modify socket events in poller
function poller:_modify_sock(sock, events, udata)

    -- ensure opened
    local ok, errors = sock:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- modify it
    if not io.poller_modify(sock:csock(), events) then
        return false, string.format("%s: modify events(%d) to poller failed!", sock, events)
    end

    -- update socket data for this socket
    self:_sockdata_set(sock:csock(), udata)
    return true
end

-- remove socket from poller
function poller:_remove_sock(sock)

    -- ensure opened
    local ok, errors = sock:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- remove it
    if not io.poller_remove(sock:csock()) then
        return false, string.format("%s: remove events from poller failed!", sock)
    end

    -- remove socket data for this socket
    self:_sockdata_set(sock, nil)
    return true
end

-- insert object events to poller
function poller:insert(otype, obj, events, udata)
    if otype == poller.OT_SOCK then
        return self:_insert_sock(obj, events, udata)
    end
    return false, string.format("invalid poller object type(%d)!", otype)
end

-- modify object events in poller
function poller:modify(otype, obj, events, udata)
    if otype == poller.OT_SOCK then
        return self:_modify_sock(obj, events, udata)
    end
    return false, string.format("invalid poller object type(%d)!", otype)
end

-- remove socket from poller
function poller:remove(otype, obj)
    if otype == poller.OT_SOCK then
        return self:_remove_sock(obj)
    end
    return false, string.format("invalid poller object type(%d)!", otype)
end

-- wait socket events in poller
function poller:wait(timeout)

    -- wait it
    local events, count = io.poller_wait(timeout or -1) 
    if count < 0 then
        return -1, "wait events in poller failed!"
    end

    -- wrap socket 
    local results = {}
    if events then
        for _, v in ipairs(events) do
            -- TODO only socket events now. It will be proc/pipe events in the future
            local csock      = v[1]
            local sockevents = v[2]
            table.insert(results, {poller.OT_SOCK,  sockevents, self:_sockdata(csock)})
        end
    end
    return count, results
end

-- return module
return poller
