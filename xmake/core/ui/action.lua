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
-- @file        action.lua
--

-- load modules
local log    = require("ui/log")
local object = require("ui/object")

-- define module
local action = action or object { }

-- register action types
function action:register(tag, ...)
    local base = self[tag] or 0
    local enums = {...}
    local n = #enums
    for i = 1, n do
        self[enums[i]] = i + base
    end
    self[tag] = base + n
end

-- register action enums
action:register("ac_max",
                "ac_on_text_changed",
                "ac_on_selected",
                "ac_on_clicked",
                "ac_on_resized",
                "ac_on_scrolled",
                "ac_on_enter",
                "ac_on_load",
                "ac_on_save",
                "ac_on_exit")

-- return module
return action
