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
-- @file        macos.lua
--

-- load modules
local macos = require("base/macos")
local raise = require("sandbox/modules/raise")

-- define module
local sandbox_macos = sandbox_macos or {}

-- get system version
function sandbox_macos.version()
    local winver = macos.version()
    if not winver then
        raise("cannot get the version of the current macos!")
    end
    return winver
end

-- return module
return sandbox_macos

