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
--
-- pac.lua
--
-- @code
-- function mirror(url)
--     return url:gsub("github.com", "hub.fastgit.org")
-- end
-- function main(url, host)
--    if host:find("bintray.com") then
--        return true
--    end
-- end
-- @endcode
--
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
                if not os.isfile(pacfile) and os.isfile(path.join(os.programdir(), "scripts", "pac", pac)) then
                    pacfile = path.join(os.programdir(), "scripts", "pac", pac)
                end
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

-- has main entry? it will be callable directly
function _is_callable(func)
    if type(func) == "function" then
        return true
    elseif type(func) == "table" then
        local meta = debug.getmetatable(func)
        if meta and meta.__call then
            return true
        end
    end
end

-- get proxy mirror url
function mirror(url)
    local proxy_pac = _proxy_pac()
    if proxy_pac and proxy_pac.mirror then
        return proxy_pac.mirror(url)
    end
    return url
end

-- get system proxy
function _system_proxy()
    local proxy = os.getenv("ALL_PROXY") or os.getenv("HTTP_PROXY") or os.getenv("HTTPS_PROXY")
    if proxy then
        return proxy
    end

    if os.host() == "windows" then
        -- Check whether system proxy is enabled
        local proxy_enable = winos.registry_query('HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings;ProxyEnable')
        --  Verify that the proxy is enabled (0x1 means enabled)
        if not proxy_enable or proxy_enable ~= "1" then
            return nil
        end

        -- Extract the proxy server address
        local proxy_server = winos.registry_query("HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings;ProxyServer")
        if not proxy_server then
            return nil
        end

        -- Prepend the protocol if not present
        if not proxy_server:match("://(.-)") then
            proxy_server = "http://" .. proxy_server
        end
        return proxy_server
    end

    return nil
end

-- translate global proxy
function _global_proxy()
    local proxy = global.get("proxy")
    if proxy and string.lower(proxy) == "system" then
        return _system_proxy()
    end
    return proxy
end

-- get proxy configuration from the given url, [protocol://]host[:port]
--
-- @see https://github.com/xmake-io/xmake/issues/854
--
function config(url)

    -- enable proxy for the given url and configuration pattern
    if url then

        -- filter proxy host from the given hosts pattern
        local host = url:match("://(.-)/") or url:match("@(.-):")
        local proxy_hosts = _proxy_hosts()
        if host and proxy_hosts then
            host = host:lower()
            for _, proxy_host in ipairs(proxy_hosts) do
                proxy_host = proxy_host:lower()
                if host == proxy_hosts or host:match(_host_pattern(proxy_host)) then
                    return _global_proxy()
                end
            end
        end

        -- filter proxy host from the pac file
        local proxy_pac = _proxy_pac()
        if proxy_pac and host and _is_callable(proxy_pac) and proxy_pac(url, host) then
            return _global_proxy()
        end

        -- use global proxy
        if not proxy_pac and not proxy_hosts then
            return _global_proxy()
        end
        return
    end

    -- enable global proxy
    return _global_proxy()
end
