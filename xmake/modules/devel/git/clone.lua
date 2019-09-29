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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        clone.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- clone url
--
-- @param url   the git url
-- @param opt   the argument options
--
-- @code
--
-- import("devel.git")
-- 
-- git.clone("git@github.com:tboox/xmake.git")
-- git.clone("git@github.com:tboox/xmake.git", {depth = 1, branch = "master", outputdir = "/tmp/xmake"})
--
-- @endcode
--
function main(url, opt)

    -- find git
    local git = assert(find_tool("git"), "git not found!")

    -- init argv
    local argv = {"clone", url}

    -- set branch
    opt = opt or {}
    if opt.branch then
        table.insert(argv, "-b")
        table.insert(argv, opt.branch)
    end

    -- set depth
    if opt.depth then
        table.insert(argv, "--depth")
        table.insert(argv, ifelse(type(opt.depth) == "number", tostring(opt.depth), opt.depth))
    end

    -- recursive?
    if opt.recursive then
        table.insert(argv, "--recursive")
    end

    -- set outputdir
    if opt.outputdir then
        table.insert(argv, path.translate(opt.outputdir))
    end

    -- clone it
    os.vrunv(git.program, argv)
end
