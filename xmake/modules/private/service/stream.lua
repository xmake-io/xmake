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
function stream:init()
end

-- is empty?
function stream:empty()
end

-- write bytes
function stream:write_bytes(data)
end

-- write table
function stream:write_table(tbl)
end

-- write string
function stream:write_string(str)
end

-- read bytes
function stream:read_bytes(size)
end

-- read table
function stream:read_table()
end

-- read string
function stream:read_string()
end

function main()
    local instance = stream()
    instance:init()
    return instance
end
