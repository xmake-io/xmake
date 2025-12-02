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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        remote.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- get remote url
--
-- @param opt   the argument options
--              - remote: the remote name, default is "origin"
--              - repodir: the repository directory
--
-- @code
--
-- import("devel.git")
--
-- local url = git.remote.get_url()
-- local url = git.remote.get_url({remote = "origin", repodir = "/tmp/xmake"})
--
-- @endcode
--
function get_url(opt)
    opt = opt or {}

    -- find git
    local git = assert(find_tool("git"), "git not found!")

    -- init arguments
    local argv = {"remote", "get-url", opt.remote or "origin"}

    -- trace
    if option.get("verbose") then
        print("%s %s", git.program, os.args(argv))
    end

    -- get remote url
    local url = try { function() return os.iorunv(git.program, argv, {curdir = opt.repodir}) end }
    if url then
        url = url:trim()
    end
    return url
end

-- set remote url
--
-- @param url   the remote url
-- @param opt   the argument options
--              - remote: the remote name, default is "origin"
--              - repodir: the repository directory
--
-- @code
--
-- import("devel.git")
--
-- git.remote.set_url("https://github.com/xmake-io/xmake-repo.git")
-- git.remote.set_url("https://github.com/xmake-io/xmake-repo.git", {remote = "origin", repodir = "/tmp/xmake"})
--
-- @endcode
--
function set_url(url, opt)
    opt = opt or {}

    -- find git
    local git = assert(find_tool("git"), "git not found!")

    -- init arguments
    local argv = {"remote", "set-url", opt.remote or "origin", url}

    -- trace
    if option.get("verbose") then
        print("%s %s", git.program, os.args(argv))
    end

    -- set remote url
    os.vrunv(git.program, argv, {curdir = opt.repodir})
end

