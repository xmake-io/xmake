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
message.CODE_CONNECT    = 1
message.CODE_DISCONNECT = 2
message.CODE_SYNC       = 3
message.CODE_CLEAN      = 4

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
    return self:code() == message.CODE_CONNECT
end

-- is disconnect message?
function message:is_disconnect()
    return self:code() == message.CODE_DISCONNECT
end

-- is sync message?
function message:is_sync()
    return self:code() == message.CODE_SYNC
end

-- is clean message?
function message:is_clean()
    return self:code() == message.CODE_CLEAN
end

-- is success?
function message:success()
    return self:body().status == true
end

-- set status, ok or failed
function message:status_set(ok)
    self:body().status = ok
end

-- get message body
function message:body()
    return self._BODY
end

-- get message errors
function message:errors()
    return self:body().errors
end

-- set message errors
function message:errors_set(errors)
    self:body().errors = errors
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
        code = message.CODE_CONNECT,
        session_id = session_id,
        xmakever = xmake.version():shortstr()
    })
end

-- new disconnect message
function new_disconnect(session_id)
    return _new({
        code = message.CODE_DISCONNECT,
        session_id = session_id
    })
end

-- new sync message
function new_sync(session_id)
    return _new({
        code = message.CODE_SYNC,
        session_id = session_id
    })
end

-- new clean message
function new_clean(session_id)
    return _new({
        code = message.CODE_CLEAN,
        session_id = session_id
    })
end

function main(body)
    return _new(body)
end
