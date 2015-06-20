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
-- @file        _template.lua
--

-- define module: _template
local _template = _template or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
    
-- init the template description
_template.description = "The Console Program"

-- create project using this template
function _template.done(targetname, projectdir)

    -- check
    assert(targetname and projectdir)

    -- check the template project
    if not os.isdir("project") then
        -- errors
        utils.error("the template project not exists!")
        return false
    end

    -- ensure the project directory 
    if not os.isdir(projectdir) then 
        os.mkdir(projectdir)
    end

    -- copy the project files
    if not os.cp("project/*", projectdir) then
        -- errors
        utils.error("install project failed!")
        return false
    end

    -- ok
    return true
end

-- return module: _template
return _template
