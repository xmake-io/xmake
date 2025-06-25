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
-- @file        ping.lua
--

-- imports
import("core.cache.detectcache")
import("lib.detect.find_tool")
import("async.runjobs")

-- using ping to ping host
function _ping_via_ping(ping, host)
    local data = nil
    if is_host("windows") then
        data = try { function () return os.iorun("%s -n 1 -w 1000 %s", ping.program, host) end }
    elseif is_host("macosx") then
        data = try { function () return os.iorun("%s -c 1 -t 1 %s", ping.program, host) end }
    else
        -- @see https://github.com/xmake-io/xmake/issues/4470#issuecomment-1840338777
        data = try { function () return os.iorun("%s -c 1 -W 1 -n %s", ping.program, host) end }
        if not data then
            data = try { function () return os.iorun("%s -c 1 -W 1 %s", ping.program, host) end }
        end
    end
    local timeval = "65535"
    if data then
        timeval = data:match("= [^/]+/([^/]+)/", 1, true) or data:match("[=<]([%d%s%.]-)ms TTL", 1, true) or "65535"
    end
    if timeval then
        timeval = tonumber(timeval:trim())
    end
    return timeval
end

-- using curl to ping host
function _ping_via_curl(curl, host)
    local data, dt = try { function ()
        local t = os.mclock()
        local tmpfile = os.tmpfile()
        local outdata = os.iorunv(curl.program, {"-o", tmpfile, "-s", "-w", "%{time_total}", "--max-time", "1", host})
        t = os.mclock() - t
        os.tryrm(tmpfile)
        return outdata, t
    end }
    local timeval = 65535
    if data then
        local t = tonumber(data:trim())
        if t then
            timeval = t * 1000
        else
            timeval = dt
        end
    end
    return timeval
end

-- using wget to ping host
function _ping_via_wget(wget, host)
    local data = try { function ()
        local t = os.mclock()
        os.runv(wget.program, {"-O", os.nuldev(), "--timeout=1", host})
        t = os.mclock() - t
        return t
    end }
    local timeval = 65535
    if data then
        timeval = data
    end
    return timeval
end

-- ping host
-- @see https://github.com/xmake-io/xmake/issues/6579
function _ping(ping, host)
    local routers = {
        ping = _ping_via_ping,
        curl = _ping_via_curl,
        wget = _ping_via_wget
    }
    local router = routers[ping.name] or _ping_via_ping
    if router then
        return router(ping, host)
    end
end

-- send ping to hosts
--
-- @param hosts     the hosts
-- @param opt       the options
--
-- @return          the time or -1
--
function main(hosts, opt)
    opt = opt or {}

    local ping = find_tool("curl", opt) or find_tool("wget") or find_tool("ping", opt)
    if not ping then
        return {}
    end

    local cacheinfo = nil
    if not opt.force then
        cacheinfo = detectcache:get("net.ping")
    end

    local results = {}
    hosts = table.wrap(hosts)
    runjobs("ping", function (index)
        local host = hosts[index]
        if host then
            local timeval = nil
            if cacheinfo then
                timeval = cacheinfo[host]
            end
            if timeval then
                results[host] = timeval
            else
                timeval = _ping(ping, host)
                results[host] = timeval
                if cacheinfo then
                    cacheinfo[host] = timeval
                end
                vprint("pinging the host(%s) ... %d ms", host, math.floor(timeval))
            end
        end
    end, {total = #hosts})

    if cacheinfo then
        detectcache:set("net.ping", cacheinfo)
        detectcache:save()
    end
    return results
end

