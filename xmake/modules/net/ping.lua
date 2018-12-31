--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        ping.lua
--

-- imports
import("lib.detect.cache")
import("detect.tools.find_ping")

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
        cacheinfo = cache.load("net.ping") 
    end

    -- run tasks
    local results = {}
    process.runjobs(function (index)
        local host = hosts[index]
        if host then
            try
            {
                function ()

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
                            data = os.iorun("%s -n 1 -w 1000 %s", ping, host)
                        elseif is_host("macosx") then
                            data = os.iorun("%s -c 1 -t 1 %s", ping, host)
                        else
                            data = os.iorun("%s -c 1 -W 1 %s", ping, host)
                        end

                        -- find time
                        local timeval = data:match("time=([%d%s%.]-)ms", 1, true) or data:match("=([%d%s%.]-)ms TTL", 1, true) or "65535"
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
                end, 
                catch 
                {
                    function (errors)

                        -- no network
                        local timeval = 65535
                        results[host] = timeval
                        if cacheinfo then
                            cacheinfo[host] = timeval
                        end

                        -- trace
                        vprint("pinging for the host(%s) ... %d ms", host, timeval)
                    end
                }
            }
        end
    end, #hosts)

    -- save cache
    if cacheinfo then
        cache.save("net.ping", cacheinfo)
    end

    -- ok?
    return results
end

