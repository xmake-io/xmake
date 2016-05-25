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
-- @file        deprecated.lua
--

-- define module
local deprecated = deprecated or {}

-- load modules
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local option    = require("base/option")

-- add deprecated entry
function deprecated.add(newformat, oldformat, ...)

    -- the entries
    deprecated._ENTRIES = deprecated._ENTRIES or {}

    -- the old and new entries
    local old = string.format(oldformat, ...)
    local new = string.format(newformat, ...)

    -- add it
    deprecated._ENTRIES[old] = new
end

-- dump all deprecated entries
function deprecated.dump()

    -- the entries
    deprecated._ENTRIES = deprecated._ENTRIES or {}

    -- dump all
    print("")
    local index = 0
    for old, new in pairs(deprecated._ENTRIES) do

        -- trace
        utils.printf("deprecated: please uses %s instead of %s", new, old)

        -- too much?
        if index > 6 and not option.get("verbose") then
            utils.printf("deprecated: add -v for getting more ..")
            break
        end

        -- update index
        index = index + 1
    end
end

-- return module
return deprecated
