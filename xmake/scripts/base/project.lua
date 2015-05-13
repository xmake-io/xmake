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
-- @file        project.lua
--

-- load modules
local utils = require("base/utils")

-- enter project 
local _PROJECT = {}
local _MAINENV = getfenv()
setmetatable(_PROJECT, {__index = _G})  
setfenv(1, _PROJECT)

-- init the parent and current scope
local parent    = nil
local current   = nil

-- configure target
function target(name)

    -- check
    assert(name and _ROOT)

    -- init targets
    _ROOT._TARGETS = _ROOT._TARGETS or {}

    -- init target scope
    _ROOT._TARGETS[name] = {}

    -- TODO
    -- enter target scope
    parent = current
    current = _ROOT._TARGETS[name]

end

-- configure project
function project(name)

    -- check
    assert(name)

    -- init the root scope, must be only one project
    if not _ROOT then
        _ROOT = {}
    else
        -- error
        utils.error("the project: %s is redundant!", name)
        return
    end

    -- init the project name
    _ROOT.name = name

    -- init the current scope
    current = _ROOT
end

-- leave project 
setfenv(1, _MAINENV)
return _PROJECT
