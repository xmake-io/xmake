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
-- @file        option.lua
--

-- define module
local sandbox_core_base_option = sandbox_core_base_option or {}

-- load modules
local option = require("base/option")

-- get the option value
function sandbox_core_base_option.get(name)

    -- get it
    return option.get(name)
end

-- get the default option value
function sandbox_core_base_option.default(name)

    -- get it
    return option.default(name)
end

-- get the options
function sandbox_core_base_option.options()

    -- get it
    return assert(option.options())
end

-- get the defaults
function sandbox_core_base_option.defaults()

    -- get it
    return option.defaults() or {}
end

-- return module
return sandbox_core_base_option
