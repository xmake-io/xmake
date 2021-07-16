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
import("detect.tools.find_ping")
import("private.async.runjobs")

-- send ping to hosts
--
-- @param hosts     the hosts
-- @param opt       the options
--
-- @return          the time or -1
--
function main(hosts, opt)

    -- init options
    opt = opt or {}

    -- find ping
    local ping = find_ping(opt)
    if not ping then
        return {}
    end

    -- do not force ping? enable cache
    local cacheinfo = nil
    if not opt.force then
        cacheinfo = detectcache:get("net.ping")
    end

    -- run tasks
    local results = {}
    hosts = table.wrap(hosts)
    runjobs("ping", function (index)
        local host = hosts[index]
        if host then

            -- get time value from cache first
            local timeval = nil
            if cacheinfo then
                timeval = cacheinfo[host]
            end
            if timeval then
                results[host] = timeval
            else
                -- ping it, timeout: 1s
                local data = nil
                if is_host("windows") then
                    data = try { function () return os.iorun("%s -n 1 -w 1000 %s", ping, host) end }
                elseif is_host("macosx") then
                    data = try { function () return os.iorun("%s -c 1 -t 1 %s", ping, host) end }
                else
                    data = try { function () return os.iorun("%s -c 1 -W 1 %s", ping, host) end }
                end

                -- find time
                local timeval = "65535"
                if data then
                    timeval = data:match("time=([%d%s%.]-)ms", 1, true) or data:match("=([%d%s%.]-)ms TTL", 1, true) or "65535"
                end

                -- save results
                if timeval then
                    timeval = tonumber(timeval:trim())
                end
                results[host] = timeval
                if cacheinfo then
                    cacheinfo[host] = timeval
                end

                -- trace
                vprint("pinging for the host(%s) ... %d ms", host, timeval)
            end
        end
    end, {total = #hosts})

    -- save cache
    if cacheinfo then
        detectcache:set("net.ping", cacheinfo)
        detectcache:save()
    end
    return results
end

