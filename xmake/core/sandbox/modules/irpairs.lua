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
-- @file        irpairs.lua
--

-- load modules
local table = require("base/table")

-- irpairs
--
-- e.g.
--
-- @code
--
-- for idx, val in irpairs({"a", "b", "c", "d", "e", "f"}) do
--      print("%d %s", idx, val)
-- end
--
-- for idx, val in irpairs({"a", "b", "c", "d", "e", "f"}, function (v) return v:upper() end) do
--      print("%d %s", idx, val)
-- end
--
-- for idx, val in irpairs({"a", "b", "c", "d", "e", "f"}, function (v, a, b) return v:upper() .. a .. b end, "a", "b") do
--      print("%d %s", idx, val)
-- end
--
-- @endcode
function sandbox_irpairs(t, filter, ...)

    -- has filter?
    local has_filter = type(filter) == "function"

    -- init iterator
    local args = table.pack(...)
    local iter = function (t, i)
        i = i - 1
        local v = t[i]
        if v ~= nil then
            if has_filter then
                v = filter(v, table.unpack(args, 1, args.n))
            end
            return i, v
        end
    end

    -- return iterator and initialized state
    t = table.wrap(t)
    return iter, t, table.getn(t) + 1
end

-- load module
return sandbox_irpairs

