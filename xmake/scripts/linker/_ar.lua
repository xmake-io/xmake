--!The Automatic Cross-_ar Build Tool
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
-- @file        _ar.lua
--

-- define module: _ar
local _ar = _ar or {}

-- load modules
local utils     = require("base/utils")
local string    = require("base/string")
local config    = require("base/config")

-- init the linker
function _ar._init(configs)

    -- init arflags
    configs.arflags = "-crs"

end

-- make the command
function _ar._make(configs, objfiles, targetfile, flags)

    -- make it
    return string.format("%s %s %s %s", configs.name, flags, targetfile, objfiles)
end

-- map gcc flag to the current linker flag
function _ar._mapflag(configs, flag)

    -- ok
    return flag
end

-- return module: _ar
return _ar
