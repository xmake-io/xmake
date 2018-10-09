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
-- @file        winos.lua
--

-- define module: winos
local winos = winos or {}

-- load modules
local os     = require("base/os")
local semver = require("base/semver")

-- get system version
function winos.version()

    -- get it from cache first
    if winos._VERSION ~= nil then
        return winos._VERSION 
    end

    -- get winver
    local winver = nil
    local ok, verstr = os.iorun("cmd /c ver")
    if ok and verstr then
        winver = verstr:match("%[.-(%d+%.%d+%.%d+)]")
        if winver then
            winver = winver:trim()
        end
        winver = semver.new(winver)
    end

    -- save to cache
    winos._VERSION = winver or false

    -- done
    return winver
end

-- return module: winos
return winos
