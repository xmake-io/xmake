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
-- @file        debug.lua
--

-- load modules
local table = require("base/table")

-- define module
local sandbox_debug = sandbox_debug or table.join(debug)

sandbox_debug.rawget   = rawget
sandbox_debug.rawset   = rawset
sandbox_debug.rawequal = rawequal
sandbox_debug.rawlen   = rawlen
sandbox_debug.require  = require
function sandbox_debug.global(key)
    if key == nil then
        return _G
    end
    return _G[key]
end


-- return module
return sandbox_debug
