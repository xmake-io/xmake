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
-- @file        push.lua
--

-- imports
import("core.base.option")
import("devel.git.remote")
import("lib.detect.find_tool")
import("net.proxy")
import("branch", {alias = "git_branch"})

-- push to given remote url and branch
--
-- @param url the remote url
-- @param opt the argument options
--
-- @code
--
-- import("devel.git")
--
-- git.push(url, {branch = "master, remote_branch = "xxx", force = true, "repodir = "/tmp/xmake"})
--
-- @endcode
--
function main(url, opt)
    opt = opt or {}
    local git = assert(find_tool("git"), "git not found!")
    local argv = {}
    if opt.fsmonitor then
        table.insert(argv, "-c")
        table.insert(argv, "core.fsmonitor=true")
    else
        table.insert(argv, "-c")
        table.insert(argv, "core.fsmonitor=false")
    end
    table.insert(argv, "push")
    table.insert(argv, url)
    if opt.force then
        table.insert(argv, "--force")
    end
    local branch = opt.branch or git_branch(opt)
    assert(branch, "git branch not found!")
    if opt.remote_branch then
        branch = branch .. ":" .. opt.remote_branch
    end
    table.insert(argv, branch)

    -- use proxy?
    local envs
    local proxy_conf = proxy.config()
    if proxy_conf then
        -- get proxy configuration from the remote url
        -- if url is a remote name, get its URL; otherwise use url directly
        local remote_url = url
        if not url:find("://") and not url:find("@") then
            -- looks like a remote name, get its URL
            remote_url = remote.get_url({remote = url, repodir = opt.repodir})
        end
        if remote_url then
            proxy_conf = proxy.config(remote_url)
        end
        envs = {ALL_PROXY = proxy_conf}
    end

    if opt.verbose then
        os.execv(git.program, argv, {envs = envs, curdir = opt.repodir})
    else
        os.vrunv(git.program, argv, {envs = envs, curdir = opt.repodir})
    end
end
