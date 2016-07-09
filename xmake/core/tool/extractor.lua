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
-- @file        extractor.lua
--

-- define module
local extractor = extractor or {}

-- load modules
local io        = require("base/io")
local path      = require("base/path")
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local config    = require("project/config")
local sandbox   = require("sandbox/sandbox")
local platform  = require("platform/platform")
local tool      = require("tool/tool")

-- get the current tool
function extractor:_tool()

    -- get it
    return self._TOOL
end

-- load the extractor 
function extractor.load()

    -- get it directly from cache dirst
    if extractor._INSTANCE then
        return extractor._INSTANCE
    end

    -- new instance
    local instance = table.inherit(extractor)

    -- load the extractor tool 
    local result, errors = tool.load("ex")
    if not result then 
        return nil, errors
    end
        
    -- save tool
    instance._TOOL = result

    -- save this instance
    extractor._INSTANCE = instance

    -- ok
    return instance
end

-- get properties of the tool
function extractor:get(name)

    -- get it
    return self:_tool().get(name)
end

-- extract the library file
function extractor:extract(libraryfile, objectdir)

    -- extract it
    return sandbox.load(self:_tool().extract, libraryfile, objectdir)
end

-- return module
return extractor
