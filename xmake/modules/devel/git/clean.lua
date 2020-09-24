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
-- @file        clean.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- clean files
--
-- @param opt   the argument options
--
-- @code
--
-- import("devel.git")
--
-- git.clean()
-- git.clean({repodir = "/tmp/xmake", force = true})
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}

    -- find git
    local git = assert(find_tool("git"), "git not found!")

    -- init argv
    local argv = {"clean", "-d"}

    -- verbose?
    if not option.get("verbose") then
        table.insert(argv, "-q")
    end

    -- force?
    if opt.force then
        table.insert(argv, "-f")
    end

    -- enter repository directory
    local oldir = nil
    if opt.repodir then
        oldir = os.cd(opt.repodir)
    end

    -- clean it
    os.vrunv(git.program, argv)

    -- leave repository directory
    if oldir then
        os.cd(oldir)
    end
end
