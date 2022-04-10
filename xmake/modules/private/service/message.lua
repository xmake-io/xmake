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
-- @file        message.lua
--

-- imports
import("core.base.object")

-- define module
local message = message or object()

-- the message code
message.CODE_PING = 1

-- init message
function message:init(body)
    self._BODY = body
end

-- get message code
function message:code()
    return self:body().code
end

-- is ping message?
function message:is_ping()
    return self:code() == message.CODE_PING
end

-- get message body
function message:body()
    return self._BODY
end

-- dump message
function message:dump()
    print(self:body())
end

-- new message
function _new(body)
    local instance = message()
    instance:init(body)
    return instance
end

-- new ping message
function new_ping()
    return _new({
        code = message.CODE_PING,
        xmakever = xmake.version():shortstr()
    })
end

function main(body)
    return _new(body)
end
