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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        winver.lua
--

-- get windows system version
--
-- $ xmake l utils.os.winver
--
--   - win10: 10.0.14393
--   - xp:    5.1.2600
--
function main()

    -- get it from cache first
    if _g.winver ~= nil then
        return _g.winver 
    end

    -- get winver
    local winver = nil
    local verstr = try { function () return os.iorun("cmd /c ver") end }
    if verstr then
        winver = verstr:match("%[.-(%d+%.%d+%.%d+)]")
        if winver then
            winver = winver:trim()
        end
    end

    -- save to cache
    _g.winver = winver or false

    -- done
    return winver
end
