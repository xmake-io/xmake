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
-- @file        client.lua
--

-- imports
import("core.base.object")
import("core.base.socket")
import("core.base.scheduler")
import("private.service.client_config", {alias = "config"})

-- define module
local client = client or object()

-- init client
function client:init()

    -- init timeout
    self._SEND_TIMEOUT = config.get("send_timeout") or -1
    self._RECV_TIMEOUT = config.get("recv_timeout") or -1
    self._CONNECT_TIMEOUT = config.get("connect_timeout") or -1
end

-- get send timeout
function client:send_timeout()
    return self._SEND_TIMEOUT
end

-- get recv timeout
function client:recv_timeout()
    return self._RECV_TIMEOUT
end

-- get connect timeout
function client:connect_timeout()
    return self._CONNECT_TIMEOUT
end

-- parse host address
function client:address_parse(address)
    local addr, port, user
    local splitinfo = address:split(':', {plain = true})
    if #splitinfo == 2 then
        addr = splitinfo[1]
        port = splitinfo[2]
    else
        addr = "127.0.0.1"
        port = splitinfo[1]
    end
    if addr and addr:find("@", 1, true) then
        splitinfo = addr:split('@', {plain = true})
        if #splitinfo == 2 then
            user = splitinfo[1]
            addr = splitinfo[2]
        end
    end
    assert(addr and port, "invalid client address!")
    return addr, port, user
end

-- get class
function client:class()
    return client
end

-- get working directory
function client:workdir()
    return os.tmpfile(tostring(self)) .. ".dir"
end

function client:__tostring()
    return "<client>"
end

function main()
    local instance = client()
    instance:init()
    return instance
end
