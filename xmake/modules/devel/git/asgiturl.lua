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
-- @author      OpportunityLiu
-- @file        asgiturl.lua
--

-- imports
import("checkurl")

local custom_protocol =
{
    ["github:"]     = "https://github.com"
,   ["gitlab:"]     = "https://gitlab.com"
,   ["gitee:"]      = "https://gitee.com"
,   ["bitbucket:"]  = "https://bitbucket.org"
}

-- try to parse given url as a git url
--
-- @param url   url can be transformed to a git url
--
-- @return      a git url or nil, if failed
--

function main(url)

    -- check
    url = url:trim()
    assert(#url > 0)

    -- safe because all custom_protocol supports https
    local lower = url:lower()
    local n_url = url
    if lower:startswith("http://") then
        n_url = "https" .. url:sub(#"http" + 1)
        lower = n_url:lower()
    end

    for k, v in pairs(custom_protocol) do
        if lower:startswith(k) then
            local data = n_url:sub(#k + 1):split("/")
            if #data ~= 2 then return nil end
            return v .. "/" .. data[1] .. "/" .. data[2] .. ".git"
        elseif lower:startswith(v) then
            local data = n_url:sub(#v + 1):split("/")
            if #data ~= 2 then return nil end
            return v .. "/" .. data[1] .. "/" .. (data[2]:endswith(".git") and data[2] or (data[2] .. ".git"))
        end
    end

    if checkurl(url) then
        return url
    end
end

