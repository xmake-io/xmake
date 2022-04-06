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
-- @file        stream.lua
--

-- imports
import("core.base.object")
import("core.base.bytes")

-- define module
local stream = stream or object()

-- init stream
function stream:init(sock)
    self._SOCK = sock
end

-- is empty?
function stream:empty()
end

-- send bytes
function stream:send_bytes(data)
end

-- send table
function stream:send_table(tbl)
end

-- send string
function stream:send_string(str)
end

-- recv bytes
function stream:recv_bytes(size)
end

-- recv table
function stream:recv_table()
end

-- recv string
function stream:recv_string()
end

function main(sock)
    local instance = stream()
    instance:init(sock)
    return instance
end
