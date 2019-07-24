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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        pairs.lua
--

-- load modules
local table = require("base/table")

-- pairs
--
-- e.g.
--
-- @code
-- 
-- local t = {a = "a", b = "b", c = "c", d = "d", e = "e", f = "f"}
--
-- for key, val in pairs(t) do
--      print("%s: %s", key, val)
-- end
--
-- for key, val in pairs(t, function (v) return v:upper() end) do
--      print("%s: %s", key, val)
-- end
--  
-- for key, val in pairs(t, function (v, a, b) return v:upper() .. a .. b end, "a", "b") do
--      print("%s: %s", key, val)
-- end
--
-- @endcode
--
function sandbox_pairs(t, filter, ...)

    -- has filter?
    local has_filter = type(filter) == "function"

    -- init iterator
    local args = {...}
    local iter = function (t, i)
        local k, v = next(t, i)
        if v and has_filter then
            v = filter(v, unpack(args))
        end
        return k, v
    end

    -- return iterator and initialized state
    return iter, table.wrap(t), nil
end

-- load module
return sandbox_pairs

