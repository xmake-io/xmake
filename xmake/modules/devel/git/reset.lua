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
-- @file        reset.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- reset files
--
-- @param opt   the argument options
--
-- @code
--
-- import("devel.git")
--
-- git.reset()
-- git.reset({repodir = "/tmp/xmake", force = true})
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}

    -- find git
    local git = assert(find_tool("git"), "git not found!")

    -- init argv
    local argv = {"reset"}

    -- verbose?
    if not option.get("verbose") then
        table.insert(argv, "-q")
    end

    -- hard?
    if opt.hard then
        table.insert(argv, "--hard")
    end

    -- soft?
    if opt.soft then
        table.insert(argv, "--soft")
    end

    -- keep?
    if opt.keep then
        table.insert(argv, "--keep")
    end

    -- reset to the given commit
    if opt.commit then
        table.insert(argv, opt.commit)
    end

    -- enter repository directory
    local oldir = nil
    if opt.repodir then
        oldir = os.cd(opt.repodir)
    end

    -- reset it
    os.vrunv(git.program, argv)

    -- leave repository directory
    if oldir then
        os.cd(oldir)
    end
end
