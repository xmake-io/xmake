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
-- @file        pull.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")
import("net.proxy")

-- pull remote commits
--
-- @param opt   the argument options
--
-- @code
--
-- import("devel.git")
--
-- git.pull()
-- git.pull({remote = "origin", tags = true, branch = "master", repodir = "/tmp/xmake"})
--
-- @endcode
--
function main(opt)

    -- init options
    opt = opt or {}

    -- find git
    local git = assert(find_tool("git"), "git not found!")

    -- init argv
    local argv = {"pull"}

    -- set remote
    table.insert(argv, opt.remote or "origin")

    -- set branch
    table.insert(argv, opt.branch or "master")

    -- set tags
    if opt.tags then
        table.insert(argv, "--tags")
    end

    -- enter repository directory
    local oldir = nil
    if opt.repodir then
        oldir = os.cd(opt.repodir)
    end

    -- use proxy?
    local envs
    local proxy_conf = proxy.get()
    if proxy_conf then
        -- get proxy configuration from the current remote url
        local remoteinfo = try { function() return os.iorunv(git.program, {"remote", "-v"}) end }
        if remoteinfo then
            for _, line in ipairs(remoteinfo:split('\n', {plain = true})) do
                local splitinfo = line:split("%s+")
                if #splitinfo > 1 and splitinfo[1] == (opt.remote or "origin") then
                    local url = splitinfo[2]
                    if url then
                        proxy_conf = proxy.get(url)
                    end
                    break
                end
            end
        end
        envs = {ALL_PROXY = proxy_conf}
    end

    -- pull it
    os.vrunv(git.program, argv, {envs = envs})

    -- leave repository directory
    if oldir then
        os.cd(oldir)
    end
end
