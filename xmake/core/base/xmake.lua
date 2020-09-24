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
-- @file        xmake.lua
--

-- define module: xmake
local xmake = xmake or {}

-- load modules
local semver = require("base/semver")

-- get name
function xmake.name()
    return xmake._NAME or "xmake"
end

-- get xmake version
function xmake.version()
    if xmake._VERSION_CACHE == nil then
        xmake._VERSION_CACHE = semver.new(xmake._VERSION) or false
    end
    return xmake._VERSION_CACHE or nil
end

-- get the program directory
function xmake.programdir()
    return xmake._PROGRAM_DIR
end

-- get the program file
function xmake.programfile()
    return xmake._PROGRAM_FILE
end

-- return module: xmake
return xmake
