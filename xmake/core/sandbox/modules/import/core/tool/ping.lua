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
-- @file        ping.lua
--

-- define module
local sandbox_core_tool_ping = sandbox_core_tool_ping or {}

-- load modules
local platform      = require("platform/platform")
local ping          = require("tool/ping")
local raise         = require("sandbox/modules/raise")

-- send ping to hosts
--
-- .e.g
-- 
-- local results = ping.send("www.tboox.org", "www.xmake.io")
--
function sandbox_core_tool_ping.send(...)
 
    -- get the ping instance
    local instance, errors = ping.load()
    if not instance then
        raise(errors)
    end

    -- send ping to hosts
    local results, errors = instance:send(...)
    if not results then
        raise(errors)
    end

    -- ok
    return results
end

-- return module
return sandbox_core_tool_ping
