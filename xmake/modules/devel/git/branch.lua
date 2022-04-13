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
import("branches", {alias = "git_branches"})

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
    local branches = git_branches(opt.repodir)
    if branches and #branches > 0 then
        return branches[1]
    end
end
