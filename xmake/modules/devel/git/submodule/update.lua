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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
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
-- submodule.update("master", {repodir = "/tmp/xmake", init = true, remote = true})
-- submodule.update("v1.0.1", {repodir = "/tmp/xmake", recursive = true, reference = "xxx", paths = "xxx"})
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}

    -- find git
    local git = assert(find_tool("git"), "git not found!")

    -- init argv
    local argv = {"submodule", "update"}
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

    -- enter repository directory
    local oldir = nil
    if opt.repodir then
        oldir = os.cd(opt.repodir)
    end

    -- submodule it
    os.vrunv(git.program, argv)

    -- leave repository directory
    if oldir then
        os.cd(oldir)
    end
end
