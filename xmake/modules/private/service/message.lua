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

-- the common message code
message.CODE_CONNECT        = 1 -- connect server
message.CODE_DISCONNECT     = 2 -- disconnect server
message.CODE_CLEAN          = 3 -- clean all cached files in server
message.CODE_DATA           = 4 -- send data
message.CODE_RUNCMD         = 5 -- run the given command in server
message.CODE_DIFF           = 6 -- diff files between server and client
message.CODE_SYNC           = 7 -- sync files between server and client
message.CODE_COMPILE        = 8 -- compile the given file from client in server

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

-- is diff message?
function message:is_diff()
    return self:code() == message.CODE_DIFF
end

-- is sync message?
function message:is_sync()
    return self:code() == message.CODE_SYNC
end

-- is compile message?
function message:is_compile()
    return self:code() == message.CODE_COMPILE
end

-- is clean message?
function message:is_clean()
    return self:code() == message.CODE_CLEAN
end

-- is run command message?
function message:is_runcmd()
    return self:code() == message.CODE_RUNCMD
end

-- is data message?
function message:is_data()
    return self:code() == message.CODE_DATA
end

-- get user authorization
function message:token()
    return self:body().token
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
function new_connect(session_id, opt)
    opt = opt or {}
    return _new({
        code = message.CODE_CONNECT,
        session_id = session_id,
        token = opt.token,
        xmakever = xmake.version():shortstr()
    })
end

-- new disconnect message
function new_disconnect(session_id, opt)
    opt = opt or {}
    return _new({
        code = message.CODE_DISCONNECT,
        session_id = session_id,
        token = opt.token
    })
end

-- new diff message, e.g manifest = {["src/main.c"] = {sha256 = "", mtime = ""}}
function new_diff(session_id, manifest, opt)
    opt = opt or {}
    return _new({
        code = message.CODE_DIFF,
        session_id = session_id,
        token = opt.token,
        manifest = manifest
    })
end

-- new sync message, e.g. manifest = {modified = {"src/main.c"}, inserted = {}, removed = {}}
function new_sync(session_id, manifest, opt)
    opt = opt or {}
    return _new({
        code = message.CODE_SYNC,
        session_id = session_id,
        token = opt.token,
        manifest = manifest
    })
end

-- new clean message
function new_clean(session_id, opt)
    opt = opt or {}
    return _new({
        code = message.CODE_CLEAN,
        session_id = session_id,
        token = opt.token
    })
end

-- new run command message
function new_runcmd(session_id, program, argv, opt)
    opt = opt or {}
    return _new({
        code = message.CODE_RUNCMD,
        session_id = session_id,
        token = opt.token,
        program = program,
        argv = argv
    })
end

-- new data message
function new_data(session_id, size, opt)
    opt = opt or {}
    return _new({
        code = message.CODE_DATA,
        size = size,
        session_id = session_id,
        token = opt.token
    })
end

-- new compile command message
function new_compile(session_id, toolname, toolkind, plat, arch, toolchain, flags, sourcename, opt)
    opt = opt or {}
    return _new({
        code = message.CODE_COMPILE,
        session_id = session_id,
        token = opt.token,
        toolname = toolname,
        toolkind = toolkind,
        plat = plat,
        arch = arch,
        toolchain = toolchain,
        flags = flags,
        sourcename = sourcename
    })
end

function main(body)
    return _new(body)
end
