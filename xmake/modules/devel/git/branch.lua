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
-- @file        branch.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- get current branch
--
-- @param opt   the argument options
--
-- @code
--
-- import("devel.git")
--
-- local branch = git.branch()
-- local branch = git.branch({repodir = "/tmp/xmake"})
--
-- @endcode
--
function main(opt)
    opt = opt or {}
    local git = assert(find_tool("git"), "git not found!")
    local argv = {"branch"}
    if not option.get("verbose") then
        table.insert(argv, "-q")
    end
    local branch = os.iorunv(git.program, argv, {curdir = opt.repodir})
    if branch then
        branch = branch:trim()
        if #branch > 0 then
            return branch
        end
    end
end
