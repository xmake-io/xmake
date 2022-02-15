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
-- @author      OpportunityLiu, ruki
-- @file        fetch_version.lua
--

-- imports
import("core.base.semver")
import("core.base.option")
import("core.base.task")
import("net.http")
import("devel.git")
import("net.fasturl")

-- the official git sources for xmake
local official_sources =
{
    "https://github.com/xmake-io/xmake.git",
    "git@github.com:xmake-io/xmake.git",
    "https://gitlab.com/tboox/xmake.git",
    "https://gitee.com/tboox/xmake.git"
}

-- get version and url of provided xmakever
function main(xmakever)

    -- init xmakever
    xmakever = xmakever or "latest"

    -- parse url and commit
    local commitish = nil
    local custom_url = nil
    local seg = xmakever:split('#', { plain = true, limit = 2, strict = true })
    if #seg == 2 then
        if #seg[1] ~= 0 then
            custom_url = seg[1]
        end
        commitish = seg[2]
    else
        if xmakever:find(':', 1, true) then
            custom_url = xmakever
        else
            commitish = xmakever
        end
    end

    local urls = nil
    if custom_url then
        urls = { git.asgiturl(custom_url) or custom_url }
        vprint("using custom source: %s ..", urls[1] )
    else
        urls = official_sources
    end
    commitish = (commitish and #commitish > 0) and commitish or "latest"

    -- sort urls
    if #urls > 1 then
        fasturl.add(urls)
        urls = fasturl.sort(urls)
    end

    -- get version
    local version = nil
    local tags, branches
    for _, url in ipairs(urls) do
        tags, branches = git.refs(url)
        if tags or branches then
            version = semver.select(commitish, tags or {}, tags or {}, branches or {})
            break
        end
    end
    return {is_official = (urls == official_sources), urls = urls, version = (version or "master"), tags = tags, branches = branches}
end

