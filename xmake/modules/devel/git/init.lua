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
-- @file        init.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- init project
--
-- @param opt   the argument options
--
-- @code
--
-- import("devel.git")
--
-- git.init()
-- git.init({repodir = "/tmp/xmake"})
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}

    -- find git
    local git = assert(find_tool("git"), "git not found!")

    -- init argv
    local argv = {"init"}

    -- verbose?
    if not option.get("verbose") then
        table.insert(argv, "-q")
    end

    -- init it
    os.vrunv(git.program, argv, {curdir = opt.repodir})
end
