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
-- @file        pairs.lua
--

-- load modules
local table = require("base/table")

-- pairs
--
-- .e.g
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

    -- init iterator
    local args = {...}
    local iter = function (t, i)
        local k, v = next(t, i)
        if v and filter ~= nil then
            v = filter(v, unpack(args))
        end
        return k, v
    end

    -- return iterator and initialized state
    return iter, table.wrap(t), nil
end

-- load module
return sandbox_pairs

