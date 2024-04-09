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
-- @file        update.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- update submodule
--
-- @param opt       the argument options, e.g. repodir, init, remote, force, checkout, merge, rebase, recursive, reference, paths
--
-- @code
--
-- import("devel.git.submodule")
--
-- submodule.update({repodir = "/tmp/xmake", init = true, remote = true})
-- submodule.update({repodir = "/tmp/xmake", recursive = true, longpaths = true, reference = "xxx", paths = "xxx"})
--
-- @endcode
--
function main(opt)
    opt = opt or {}
    local git = assert(find_tool("git"), "git not found!")

    -- init argv
    local argv = {}
    if opt.fsmonitor then
        table.insert(argv, "-c")
        table.insert(argv, "core.fsmonitor=true")
    else
        table.insert(argv, "-c")
        table.insert(argv, "core.fsmonitor=false")
    end

    -- use longpaths, we need it on windows
    if opt.longpaths then
        table.insert(argv, "-c")
        table.insert(argv, "core.longpaths=true")
    end

    table.insert(argv, "submodule")
    table.insert(argv, "update")
    for _, name in ipairs({"init", "remote", "force", "checkout", "merge", "rebase", "recursive"}) do
        if opt[name] then
            table.insert(argv, "--" .. name)
        end
    end
    if opt.reference then
        table.insert(argv, "--reference")
        table.insert(argv, opt.reference)
    end
    if opt.paths then
        table.join2(argv, opt.paths)
    end

    -- update it
    os.vrunv(git.program, argv, {curdir = opt.repodir})
end
