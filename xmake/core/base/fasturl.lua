--!The Make-like Build Utility based on Lua
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
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        fasturl.lua
--

-- define module
local fasturl = fasturl or {}

-- load modules
local table     = require("base/table")
local ping      = require("tool/ping")

-- parse host from url
function fasturl._parse_host(url)

    -- init host cache
    fasturl._URLHOSTS = fasturl._URLHOSTS or {}

    -- http[s]://xxx.com/.. or git@git.xxx.com:xxx/xxx.git
    local host = fasturl._URLHOSTS[url] or url:match("://(.-)/") or url:match("@(.-):")

    -- save to cache
    fasturl._URLHOSTS[url] = host

    -- ok
    return host
end

-- add urls
function fasturl.add(urls)

    -- get current ping info
    local pinginfo = fasturl._PINGINFO or {}

    -- add ping hosts
    fasturl._PINGHOSTS = fasturl._PINGHOSTS or {}
    for _, url in ipairs(urls) do

        -- parse host
        local host = fasturl._parse_host(url)

        -- this host has not been tested?
        if host and not pinginfo[host] then
            table.insert(fasturl._PINGHOSTS, host)
        end
    end
end

-- sort urls
function fasturl.sort(urls)

    -- ping hosts
    local pinghosts = table.unique(fasturl._PINGHOSTS or {})
    if pinghosts and #pinghosts > 0 then
 
        -- get the ping instance
        local instance, errors = ping.load()
        if not instance then
            return nil, errors
        end

        -- ping them and test speed
        local pinginfo, errors = instance:send(unpack(pinghosts))
        if not pinginfo then
            return nil, errors
        end
        
        -- merge to ping info
        fasturl._PINGINFO = table.join(fasturl._PINGINFO or {}, pinginfo) 
    end

    -- sort urls by the ping info
    local pinginfo = fasturl._PINGINFO or {}
    table.sort(urls, function(a, b) 
        a = pinginfo[fasturl._parse_host(a) or ""] or 65536
        b = pinginfo[fasturl._parse_host(b) or ""] or 65536
        return a < b 
    end)

    -- clear hosts
    fasturl._PINGHOSTS = {}

    -- ok
    return urls
end

-- return module
return fasturl
