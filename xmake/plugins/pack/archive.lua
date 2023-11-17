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
-- @file        archive.lua
--

-- imports
import("core.base.option")
import("utils.archive")
import("batchcmds")

-- get archive directory
function _get_archivedir(package)
    return path.join(package:buildir(), "archive", package:format())
end

-- run command
function _run_command(package, cmd)
    local opt = cmd.opt or {}
    local kind = cmd.kind
    local archivedir = _get_archivedir(package)
    if kind == "cp" then
        local srcpath = cmd.srcpath
        local dstpath = path.join(archivedir, cmd.dstpath)
        os.vcp(srcpath, dstpath, opt)
    elseif kind == "rm" then
        local filepath = path.join(archivedir, cmd.filepath)
        os.tryrm(filepath, opt)
    elseif kind == "rmdir" then
        local dir = path.join(archivedir, cmd.dir)
        if os.isdir(dir) then
            os.tryrm(dir, opt)
        end
    elseif kind == "mv" then
        local srcpath = cmd.srcpath
        local dstpath = path.join(archivedir, cmd.dstpath)
        os.vmv(srcpath, dstpath, opt)
    elseif kind == "cd" then
        local dir = path.join(archivedir, cmd.dir)
        os.cd(dir)
    elseif kind == "mkdir" then
        local dir = path.join(archivedir, cmd.dir)
        os.mkdir(dir)
    end
end

-- run commands
function _run_commands(package, cmds)
    for _, cmd in ipairs(cmds) do
        _run_command(package, cmd)
    end
end

-- pack archive package
function _pack_archive(package)

    -- do install
    _run_commands(package, batchcmds.get_installcmds(package):cmds())

    -- archive install files
    local archivedir = _get_archivedir(package)
    local archivefiles = os.files(path.join(archivedir, "**"))
    archive.archive(package:outputfile(), archivefiles)
end

function main(package)
    cprint("packing %s", package:outputfile())
    _pack_archive(package)
end

