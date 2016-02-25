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
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        utils.lua
--

-- load modules
local utils     = require("base/utils")
local vformat   = require("sandbox/vformat")

-- define module
local sandbox_builtin_utils = sandbox_builtin_utils or {}

-- inherit the public interfaces of utils
for k, v in pairs(utils) do
    if not k:startswith("_") and type(v) == "function" then
        sandbox_builtin_utils[k] = v
    end
end

-- printf with the builtin variables
function sandbox_builtin_utils.printf(format, ...)

    -- done
    return print(vformat(format, ...))
end

-- return module
return sandbox_builtin_utils

