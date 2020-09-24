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
-- @file        macos.lua
--

-- define module: macos
local macos = macos or {}

-- load modules
local os     = require("base/os")
local semver = require("base/semver")

-- get system version
function macos.version()

    -- get it from cache first
    if macos._VERSION ~= nil then
        return macos._VERSION
    end

    -- get macver
    local macver = nil
    local ok, verstr = os.iorun("sw_vers -productVersion")
    if ok and verstr then
        macver = verstr:match("%d+%.%d+%.%d+")
        if macver then
            macver = macver:trim()
        end
        macver = semver.new(macver)
    end

    -- save to cache
    macos._VERSION = macver or false

    -- done
    return macver
end

-- return module: macos
return macos
