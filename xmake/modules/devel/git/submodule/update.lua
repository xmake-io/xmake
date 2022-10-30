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

    -- init options
    opt = opt or {}

    -- find git
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

    -- enable long paths
    local longpaths_old
    local longpaths_changed = false
    if opt.longpaths then
        local longpaths_old = try {function () return os.iorunv(git.program, {"config", "--get", "--global", "core.longpaths"}, {curdir = opt.repodir}) end}
        if not longpaths_old or not longpaths_old:find("true") then
            os.vrunv(git.program, {"config", "--global", "core.longpaths", "true"}, {curdir = opt.repodir})
            longpaths_changed = true
        end
    end

    -- submodule it
    os.vrunv(git.program, argv, {curdir = opt.repodir})

    -- restore old long paths configuration
    if longpaths_changed then
        if longpaths_old and longpaths_old:find("false") then
            os.vrunv(git.program, {"config", "--global", "core.longpaths", "false"}, {curdir = opt.repodir})
        else
            os.vrunv(git.program, {"config", "--global", "--unset", "core.longpaths"}, {curdir = opt.repodir})
        end
    end
end
