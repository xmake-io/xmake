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
-- @file        archiver.lua
--

-- define module
local sandbox_core_tool_archiver = sandbox_core_tool_archiver or {}

-- load modules
local platform  = require("platform/platform")
local archiver  = require("tool/archiver")
local raise     = require("sandbox/modules/raise")

-- make command for archiving library file
function sandbox_core_tool_archiver.archivecmd(objectfiles, targetfile, target)
 
    -- get the archiver instance
    local instance, errors = archiver.load()
    if not instance then
        raise(errors)
    end

    -- make command
    return instance:archivecmd(objectfiles, targetfile, target)
end

-- archive library file
function sandbox_core_tool_archiver.archive(objectfiles, targetfile, target)
 
    -- get the archiver instance
    local instance, errors = archiver.load()
    if not instance then
        raise(errors)
    end

    -- archive it
    local ok, errors = instance:archive(objectfiles, targetfile, target)
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_core_tool_archiver
