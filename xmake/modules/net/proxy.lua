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
-- @file        proxy.lua
--

-- imports
import("core.base.global")

-- get proxy hosts
function _proxy_hosts()
    local proxy_hosts = _g._PROXY_HOSTS
    if proxy_hosts == nil then
        proxy_hosts = global.get("proxy_hosts")
        if proxy_hosts then
            proxy_hosts = proxy_hosts:split(',', {plain = true})
        end
        _g._PROXY_HOSTS = proxy_hosts or false
    end
    return proxy_hosts or nil
end

-- convert host pattern to a lua pattern
function _host_pattern(pattern)
    pattern = pattern:gsub("([%+%.%-%^%$%(%)%%])", "%%%1")
    pattern = pattern:gsub("%*", "\001")
    pattern = pattern:gsub("\001", ".*")
    return pattern
end

-- get proxy configuration from the given url, [protocol://]host[:port]
function get(url)
    if url then
        local host = url:match("://(.-)/") or url:match("@(.-):")
        local proxy_hosts = _proxy_hosts()
        if host and proxy_hosts then
            host = host:lower()
            for _, proxy_host in ipairs(proxy_hosts) do
                proxy_host = proxy_host:lower()
                if host == proxy_hosts or host:match(_host_pattern(proxy_host)) then
                    return global.get("proxy")
                end
            end
        end
        return
    end
    return global.get("proxy")
end
