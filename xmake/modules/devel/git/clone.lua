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
-- @file        clone.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")
import("net.proxy")

-- clone url
--
-- @param url   the git url
-- @param opt   the argument options
--
-- @code
--
-- import("devel.git")
--
-- git.clone("git@github.com:xmake-io/xmake.git")
-- git.clone("git@github.com:xmake-io/xmake.git", {depth = 1, branch = "master", outputdir = "/tmp/xmake", longpaths = true})
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
        table.insert(argv, type(opt.depth) == "number" and tostring(opt.depth) or opt.depth)
    end

    -- recursive?
    if opt.recursive then
        table.insert(argv, "--recursive")
    end

    -- clone for submodules
    if opt.recurse_submodules then
        table.insert(argv, "--recurse-submodules")
    end
    if opt.shallow_submodules then
        table.insert(argv, "--shallow-submodules")
    end

    -- use longpaths, we need it on windows
    if opt.longpaths then
        table.insert(argv, "-c")
        table.insert(argv, "core.longpaths=true")
    end

    -- set fsmonitor
    if opt.fsmonitor then
        table.insert(argv, "-c")
        table.insert(argv, "core.fsmonitor=true")
    else
        table.insert(argv, "-c")
        table.insert(argv, "core.fsmonitor=false")
    end

    -- set outputdir
    if opt.outputdir then
        table.insert(argv, path.translate(opt.outputdir))
    end

    -- use proxy?
    local envs
    local proxy_conf = proxy.config(url)
    if proxy_conf then
        envs = {ALL_PROXY = proxy_conf}
    end

    -- clone it
    os.vrunv(git.program, argv, {envs = envs})
end
