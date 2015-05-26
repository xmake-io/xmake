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
-- @file        _global.lua
--

-- define module: _global
local _global = _global or {}

-- load modules
local utils     = require("base/utils")
local global    = require("base/global")
local platform  = require("platform/platform")

-- done the given config
function _global.done()

    -- wrap the global configure for more convenient to get and set values
    local global_wrapped = {}
    setmetatable(global_wrapped, 
    {
        __index = function(tbl, key)
            return global.get(key)
        end,
        __newindex = function(tbl, key, val)
            global.set(key, val)
        end
    })

    -- probe the global configure 
    platform.probe(global_wrapped, true)

    -- dump global
    global.dump()

    -- save the global configure
    if not global.savexconf() then
        -- error
        utils.error("save configure failed!")
        return false
    end

    -- ok
    print("configure ok!")
    return true
end

-- return module: _global
return _global
