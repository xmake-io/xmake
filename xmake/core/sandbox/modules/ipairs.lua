--!The Make-like Build Utility based on Lua
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        ipairs.lua
--

-- load modules
local table = require("base/table")

-- ipairs
--
-- .e.g
--
-- @code
-- 
-- for idx, val in ipairs({"a", "b", "c", "d", "e", "f"}) do
--      print("%d %s", idx, val)
-- end
--
-- for idx, val in ipairs({"a", "b", "c", "d", "e", "f"}, function (v) return v:upper() end) do
--      print("%d %s", idx, val)
-- end
--
-- for idx, val in ipairs({"a", "b", "c", "d", "e", "f"}, function (v, a, b) return v:upper() .. a .. b end, "a", "b") do
--      print("%d %s", idx, val)
-- end
--
-- @endcode
function sandbox_ipairs(t, filter, ...)

    -- init iterator
    local args = {...}
    local iter = function (t, i)
        i = i + 1
        local v = t[i]
        if v then
            if filter ~= nil then
                v = filter(v, unpack(args))
            end
            return i, v
        end
    end

    -- return iterator and initialized state
    return iter, table.wrap(t), 0
end

-- load module
return sandbox_ipairs

