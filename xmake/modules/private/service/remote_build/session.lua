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
-- @file        session.lua
--

-- imports
import("core.base.object")
import("core.base.global")
import("private.service.config")

-- define module
local session = session or object()

-- init session
function session:init(session_id)
    self._ID = session_id
end

-- get session id
function session:id()
    return self._ID
end

-- open session
function session:open()
end

-- close session
function session:close()

    -- remove the session caches
    local workdir = self:workdir()
    if workdir then
        os.tryrm(workdir)
    end
end

-- syncfiles
function session:syncfiles()
end

-- get work directory
function session:workdir()
    local workdir = config.get("remote_build.server.workdir")
    if not workdir then
        workdir = path.join(global.directory(), "service", "remote_build")
    end
    return path.join(workdir, "sessons", self:id())
end

-- get project directory
function session:projectdir()
    return path.join(self:workdir(), "source")
end

function main(session_id)
    local instance = session()
    instance:init(session_id)
    return instance
end
