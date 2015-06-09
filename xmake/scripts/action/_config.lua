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
-- @file        _config.lua
--

-- define module: _config
local _config = _config or {}

-- load modules
local utils     = require("base/utils")
local config    = require("base/config")
local project   = require("base/project")
local makefile  = require("base/makefile")

-- done the given config
function _config.done()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- dump config
    config.dump()

    -- save the configure
    if not config.save() then
        -- error
        utils.error("save configure failed!")
        return false
    end

    -- make the configure file for the given target
    if not project.makeconf(options.target) then
        -- error
        utils.error("make configure failed!")
        return false
    end

    -- make makefile
    if not makefile.make() then
        -- error
        utils.error("make makefile failed!")
        return false
    end

    -- ok
    print("configure ok!")
    return true
end

-- return module: _config
return _config
