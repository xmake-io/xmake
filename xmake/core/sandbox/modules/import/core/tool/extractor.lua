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
-- @file        extractor.lua
--

-- define module
local sandbox_core_tool_extractor = sandbox_core_tool_extractor or {}

-- load modules
local platform  = require("platform/platform")
local extractor = require("tool/extractor")
local raise     = require("sandbox/modules/raise")

-- extract library file
function sandbox_core_tool_extractor.extract(libraryfile, objectdir)
 
    -- get the extractor instance
    local instance, errors = extractor.load()
    if not instance then
        raise(errors)
    end

    -- extract it
    local ok, errors = instance:extract(libraryfile, objectdir)
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_core_tool_extractor
