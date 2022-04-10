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
message.CODE_CONN       = 1 -- connect
message.CODE_DISCONN    = 2 -- disconnect

-- init message
function message:init(body)
    self._BODY = body
end

-- get message code
function message:code()
    return self:body().code
end

-- get session id
function message:session_id()
    return self:body().session_id
end

-- is connect message?
function message:is_connect()
    return self:code() == message.CODE_CONN
end

-- is disconnect message?
function message:is_disconnect()
    return self:code() == message.CODE_DISCONN
end

-- get message body
function message:body()
    return self._BODY
end

-- clone a message
function message:clone()
    local body = table.copy(self:body())
    return _new(body)
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

-- new connect message
function new_connect(session_id)
    return _new({
        code = message.CODE_CONN,
        session_id = session_id,
        xmakever = xmake.version():shortstr()
    })
end

-- new disconnect message
function new_disconnect(session_id)
    return _new({
        code = message.CODE_DISCONN,
        session_id = session_id
    })
end

function main(body)
    return _new(body)
end
