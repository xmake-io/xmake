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
-- @file        apply.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- apply remote commits
--
-- @param opt   the argument options
--
-- @code
--
-- import("devel.git")
--
-- git.apply("xxx.patch")
-- git.apply("xxx.diff")
--
-- @endcode
--
function main(patchfile, opt)
    opt = opt or {}
    local git = assert(find_tool("git"), "git not found!")
    local argv = {"apply", "--reject", "--ignore-whitespace", patchfile}
    os.vrunv(git.program, argv, {curdir = opt.repodir})
end
