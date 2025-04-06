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
import("core.base.semver")
import("lib.detect.find_tool")
import("net.proxy")

-- can clone tag?
-- @see https://github.com/xmake-io/xmake/issues/4151
function can_clone_tag()
    local can = _g.can_clone_tag
    if can == nil then
        local git = assert(find_tool("git", {version = true}), "git not found!")
        if git.version and semver.compare(git.version, "1.7.10") >= 0 then
            can = true
        end
        _g.can_clone_tag = can or false
    end
    return can or false
end

-- can clone with --shallow-submodules?
-- @see https://github.com/xmake-io/xmake/issues/4151
function can_shallow_submodules()
    local can = _g.can_shallow_submodules
    if can == nil then
        local git = assert(find_tool("git", {version = true}), "git not found!")
        if git.version and semver.compare(git.version, "2.9.0") >= 0 then
            can = true
        end
        _g.can_shallow_submodules = can or false
    end
    return can or false
end

-- can clone with --filter=tree:0?
-- @see https://github.com/xmake-io/xmake/issues/6246
function can_treeless()
    local can = _g.can_treeless
    if can == nil then
        local git = assert(find_tool("git", {version = true}), "git not found!")
        if git.version and semver.compare(git.version, "2.16.0") >= 0 then
            can = true
        end
        _g.can_treeless = can or false
    end
    return can or false
end

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
-- git.clone("git@github.com:xmake-io/xmake.git", {depth = 1, treeless = true, branch = "master", outputdir = "/tmp/xmake", longpaths = true})
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

    -- treeless?
    -- @see https://github.com/xmake-io/xmake/issues/5507
    if opt.treeless and can_treeless() then
        table.insert(argv, "--filter=tree:0")
    end

    -- no checkout
    if opt.checkout == false then
        table.insert(argv, "--no-checkout")
    end

    -- recursive?
    if opt.recursive then
        table.insert(argv, "--recursive")
    end

    -- clone for submodules
    if opt.recurse_submodules then
        table.insert(argv, "--recurse-submodules")
    end
    if opt.shallow_submodules and can_shallow_submodules() then
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

    -- set core.autocrlf
    if opt.autocrlf then
        table.insert(argv, "-c")
        table.insert(argv, "core.autocrlf=true")
    elseif opt.autocrlf == false then
        table.insert(argv, "-c")
        table.insert(argv, "core.autocrlf=false")
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
    if opt.verbose then
        os.execv(git.program, argv, {envs = envs})
    else
        os.vrunv(git.program, argv, {envs = envs})
    end
end
