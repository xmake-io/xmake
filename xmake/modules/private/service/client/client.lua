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

-- define module
local client = client or object()

-- init client
function client:init()
end

-- get class
function client:class()
    return client
end

-- get working directory
function client:workdir()
    return os.tmpfile(tostring(self)) .. ".dir"
end

-- is connected?
function client:is_connected()
    return os.isfile(self:statusfile())
end

-- get the status
function client:status()
    local status = self._STATUS
    local statusfile = self:statusfile()
    if not status and os.isfile(statusfile) then
        status = io.load(statusfile)
        self._STATUS = status
    end
    return status
end

-- get the status file
function client:statusfile()
    return path.join(self:workdir(), "status.txt")
end

function client:__tostring()
    return "<client>"
end

function main()
    local instance = client()
    instance:init()
    return instance
end
