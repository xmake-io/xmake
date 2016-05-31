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
-- @file        history.lua
--

-- define module: history
local history = history or {}

-- load modules
local os                = require("base/os")
local io                = require("base/io")
local table             = require("base/table")
local utils             = require("base/utils")
local string            = require("base/string")
local cache             = require("project/cache")("local.history")

-- save history
function history.save(key, value)

    -- check
    assert(key and value ~= nil)

    -- load history values first
    local values = history.load(key) or {}

    -- remove the oldest value if be full
    if #values > 64 then
        table.remove(values, 1)
    end

    -- append this value
    table.insert(values, value)

    -- save history
    cache:set(key, values)
    cache:flush()
end

-- load history 
function history.load(key)

    -- load it
    return cache:get(key)
end

-- return module: history
return history
