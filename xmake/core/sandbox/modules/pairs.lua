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
-- @file        pairs.lua
--

-- load modules
local table = require("base/table")

-- improve pairs, wrap nil/single value
function sandbox_pairs(t)

    -- exists the custom ipairs?
    local is_table = type(t) == "table"
    if is_table and t.pairs then
        return t:pairs()
    end

    -- wrap table and return iterator
    if not is_table then
        t = t ~= nil and {t} or {}
    end
    return function (t, i)
        return next(t, i)
    end, t, nil
end

-- load module
return sandbox_pairs

