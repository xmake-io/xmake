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

-- init it
function init(shellname)

    -- save name
    _g.shellname = shellname or "ping"
end

-- send ping to host
function send(host)

    -- ping it
    local data = nil
    if os.host() == "windows" then
        data = os.iorun("%s -n 1 %s", _g.shellname, host)
    else
        data = os.iorun("%s -c 1 %s", _g.shellname, host)
    end

    -- find time
    local time = data:match("time=(.-)ms", 1, true)
    if time then
        return tonumber(time:trim())
    end

    -- failed
    return -1
end

-- check the given flags 
function check(flags)

    -- check it
    if os.host() == "windows" then
        os.run("%s -n 1 127.0.0.1", _g.shellname)
    else
        os.run("%s -c 1 127.0.0.1", _g.shellname)
    end
end
