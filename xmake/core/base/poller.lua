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
-- @file        poller.lua
--

-- define module
local poller = poller or {}

-- load modules
local io     = require("base/io")
local string = require("base/string")

-- the poller object type, @see tbox/platform/poller.h
poller.OT_SOCK     = 1
poller.OT_PIPE     = 2
poller.OT_PROC     = 3
poller.OT_FWATCHER = 4

-- the poller events, @see tbox/platform/poller.h
poller.EV_POLLER_RECV    = 1
poller.EV_POLLER_SEND    = 2
poller.EV_POLLER_CONN    = poller.EV_POLLER_SEND
poller.EV_POLLER_ACPT    = poller.EV_POLLER_RECV
poller.EV_POLLER_CLEAR   = 0x0010 -- edge trigger. after the event is retrieved by the user, its state is reset
poller.EV_POLLER_ONESHOT = 0x0010 -- causes the event to return only the first occurrence of the filter being triggered
poller.EV_POLLER_EOF     = 0x0100 -- the event flag will be marked if the connection be closed in the edge trigger
poller.EV_POLLER_ERROR   = 0x0200 -- socket error after waiting

-- get poller object data
function poller:_pollerdata(cdata)
    return self._POLLERDATA and self._POLLERDATA[cdata] or nil
end

-- set poller object data
function poller:_pollerdata_set(cdata, data)
    local pollerdata = self._POLLERDATA
    if not pollerdata then
        pollerdata = {}
        self._POLLERDATA = pollerdata
    end
    pollerdata[cdata] = data
end

-- support events?
function poller:support(events)
    return io.poller_support(events)
end

-- spank poller to break the wait() and return all triggered events
function poller:spank()
    io.poller_spank()
end

-- insert object events to poller
function poller:insert(obj, events, udata)

    -- insert it
    local ok, errors = io.poller_insert(obj:otype(), obj:cdata(), events)
    if not ok then
        return false, string.format("%s: insert events(%d) to poller failed, %s", obj, events, errors or "unknown reason")
    end

    -- save poller object data and save obj/ref for gc
    self:_pollerdata_set(obj:cdata(), {obj, udata})
    return true
end

-- modify object events in poller
function poller:modify(obj, events, udata)

    -- modify it
    local ok, errors = io.poller_modify(obj:otype(), obj:cdata(), events)
    if not ok then
        return false, string.format("%s: modify events(%d) to poller failed, %s", obj, events, errors or "unknown reason")
    end

    -- update poller object data
    self:_pollerdata_set(obj:cdata(), {obj, udata})
    return true
end

-- remove object from poller
function poller:remove(obj)

    -- remove it
    local ok, errors = io.poller_remove(obj:otype(), obj:cdata())
    if not ok then
        return false, string.format("%s: remove events from poller failed, %s", obj, errors or "unknown reason")
    end

    -- remove poller object data
    self:_pollerdata_set(obj, nil)
    return true
end

-- wait object events in poller
function poller:wait(timeout)

    -- wait it
    local events, count = io.poller_wait(timeout or -1)
    if count < 0 then
        return -1, "wait events in poller failed!"
    end

    -- check count
    if count > 0 and count ~= #events then
        return -1, string.format("events(%d) != %d in poller!", #events, count)
    end

    -- wrap objects with cdata
    local results = {}
    if events then
        for _, v in ipairs(events) do
            local otype  = v[1]
            local cdata  = v[2]
            local events = v[3]
            local pollerdata   = self:_pollerdata(cdata)
            if not pollerdata then
                return -1, string.format("no object data for cdata(%s)!", cdata)
            end
            local obj = pollerdata[1]
            assert(obj and obj:otype() == otype and obj:cdata() == cdata)
            table.insert(results, {obj, events, pollerdata[2]})
        end
    end
    return count, results
end

-- return module
return poller
