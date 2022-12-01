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
-- @file        fasturl.lua
--

-- imports
import("ping")

-- http[s]://xxx.com/.. or git@git.xxx.com:xxx/xxx.git
function _parse_host(url)
    _g._URLHOSTS = _g._URLHOSTS or {}
    local host = _g._URLHOSTS[url] or url:match("://(.-)/") or url:match("@(.-):")
    _g._URLHOSTS[url] = host
    return host
end

function add(urls)
    local pinginfo = _g._PINGINFO or {}
    _g._PINGHOSTS = _g._PINGHOSTS or {}
    for _, url in ipairs(urls) do
        local host = _parse_host(url)
        if host and not pinginfo[host] then
            table.insert(_g._PINGHOSTS, host)
        end
    end
end

function sort(urls)

    -- ping hosts
    local pinghosts = table.unique(_g._PINGHOSTS or {})
    if pinghosts and #pinghosts > 0 then
        local pinginfo = ping(pinghosts)
        _g._PINGINFO = table.join(_g._PINGINFO or {}, pinginfo)
    end

    -- sort urls by the ping info
    local pinginfo = _g._PINGINFO or {}
    table.sort(urls, function(a, b)
        a = pinginfo[_parse_host(a) or ""] or 65536
        b = pinginfo[_parse_host(b) or ""] or 65536
        return a < b
    end)

    _g._PINGHOSTS = {}
    return urls
end

