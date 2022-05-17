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
-- @file        ipairs.lua
--

-- load modules
local table = require("base/table")

-- improve ipairs, wrap nil and single value
function sandbox_ipairs(t)

    -- exists the custom ipairs?
    local is_table = type(t) == "table"
    if is_table and t.ipairs then
        return t:ipairs()
    end

    -- wrap table and return iterator
    if not is_table then
        t = t ~= nil and {t} or {}
    end
    return function (t, i)
        i = i + 1
        local v = t[i]
        if v ~= nil then
            return i, v
        end
    end, t, 0
end

-- load module
return sandbox_ipairs

