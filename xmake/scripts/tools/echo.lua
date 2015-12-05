--!The Automatic Cross-platform Build Tool
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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        echo.lua
--

-- define module: echo
local echo = echo or {}

-- load modules
local io        = require("base/io")
local string    = require("base/string")

-- the main function
function echo.main(self, ...)

    -- echo all
    for _, v in ipairs(...) do
        io.write(string.format("%s ", v:decode()))
    end
    io.write("\n")

    -- ok
    return true
end

-- return module: echo
return echo
