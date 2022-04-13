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
import("devel.git")
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
    self:_reset_sourcedir()
end

-- close session
function session:close()
    self:_reset_sourcedir()
end

-- sync files
function session:sync(respmsg)
    local body = respmsg:body()
    vprint("%s: %s sync files in %s ..", self, self:sourcedir(), body.start and "start" or "finish")
    local sourcedir = self:sourcedir()
    local source_branch = self:_source_branch()
    if body.start then
        self:_reset_sourcedir()
        body.path = sourcedir
        body.branch = source_branch
    else
        local branch = git.branch({repodir = sourcedir})
        if not branch or branch ~= source_branch then
            git.checkout(source_branch, {repodir = sourcedir})
        end
    end
    vprint("%s: %s sync files ok", self, body.start and "start" or "finish")
end

-- clean files
function session:clean()
    vprint("%s: clean files in %s ..", self, self:workdir())
    os.tryrm(self:workdir())
    vprint("%s: clean files ok", self)
end

-- run command
function session:runcmd(respmsg)
    local body = respmsg:body()
    local program = body.program
    local argv = body.argv
    vprint("%s: run command(%s) ..", self, os.args(table.join(program, argv)))
    vprint("%s: run command ok", self)
end

-- get work directory
function session:workdir()
    local workdir = config.get("remote_build.server.workdir")
    if not workdir then
        workdir = path.join(global.directory(), "service", "remote_build")
    end
    return path.join(workdir, "sessons", self:id())
end

-- get sourcedir directory
function session:sourcedir()
    return path.join(self:workdir(), "source")
end

-- reset sourcedir
function session:_reset_sourcedir()
    vprint("%s: reset %s", self, self:sourcedir())

    -- init sourcedir first if .git not exists
    local sourcedir = self:sourcedir()
    if not os.isdir(sourcedir) then
        os.mkdir(sourcedir)
    end
    if not os.isdir(path.join(sourcedir, ".git")) then
        git.init({repodir = sourcedir})
    end

    -- reset the current branch
    local branch = git.branch({repodir = sourcedir})
    if branch then
        git.clean({repodir = sourcedir, force = true, all = true})
        git.reset({repodir = sourcedir, hard = true})
    end
end

-- get working branch of the source directory
function session:_source_branch()
    return "remote_build"
end

function session:__tostring()
    return string.format("<session %s>", self:id())
end

function main(session_id)
    local instance = session()
    instance:init(session_id)
    return instance
end
