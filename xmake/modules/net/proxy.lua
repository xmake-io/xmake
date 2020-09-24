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

-- get proxy pac file
function _proxy_pac()
    local proxy_pac = _g._PROXY_PAC
    if proxy_pac == nil then
        local pac = global.get("proxy_pac")
        local pacfile
        if pac and pac:endswith(".lua") then
            if os.isfile(pac) then
                pacfile = pac
            end
            if not pacfile and not path.is_absolute(pac) then
                pacfile = path.join(global.directory(), pac)
            end
        end
        if pacfile and os.isfile(pacfile) then
            proxy_pac = import(path.basename(pacfile), {rootdir = path.directory(pacfile), try = true, anonymous = true})
        end
        _g._PROXY_PAC = proxy_pac or false
    end
    return proxy_pac or nil
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

    -- enable proxy for the given url and configuration pattern
    if url then

        -- get proxy from the given hosts pattern
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

        -- get proxy from the pac file
        local proxy_pac = _proxy_pac()
        if proxy_pac and proxy_pac(url, host) then
            return global.get("proxy")
        end
        return
    end

    -- enable global proxy
    return global.get("proxy")
end
