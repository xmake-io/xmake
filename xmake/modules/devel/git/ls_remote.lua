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
-- @file        ls_remote.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")
import("net.proxy")

-- ls_remote to given branch, tag or commit
--
-- @param reftype   the reference type, "tags", "heads" and "refs"
-- @param url       the remote url, optional
--
-- @return          the tags, heads or refs
--
-- @code
--
-- import("devel.git")
--
-- local tags   = git.ls_remote("tags", url)
-- local heads  = git.ls_remote("heads", url)
-- local refs   = git.ls_remote("refs")
--
-- @endcode
--
function main(reftype, url)

    -- find git
    local git = assert(find_tool("git"), "git not found!")

    -- init reference type
    reftype = reftype or "refs"

    -- init arguments
    local argv = {"ls-remote", "--" .. reftype, url or "."}

    -- trace
    if option.get("verbose") then
        print("%s %s", git.program, os.args(argv))
    end

    -- use proxy?
    local envs
    local proxy_conf = proxy.config(url)
    if proxy_conf then
        envs = {ALL_PROXY = proxy_conf}
    end

    -- get refs
    local data = os.iorunv(git.program, argv, {envs = envs})

    -- get commmits and tags
    local refs = {}
    for _, line in ipairs(data:split('\n')) do

        -- parse commit and ref
        local refinfo = line:split('%s')

        -- get commit
        local commit = refinfo[1]

        -- get ref
        local ref = refinfo[2]

        -- save this ref
        local prefix = reftype == "refs" and "refs/" or ("refs/" .. reftype .. "/")
        if ref and ref:startswith(prefix) and commit and #commit == 40 then
            table.insert(refs, ref:sub(#prefix + 1))
        end
    end

    -- ok
    return refs
end
