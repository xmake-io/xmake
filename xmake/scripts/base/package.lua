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
-- @file        package.lua
--

-- define module: package
local package = package or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local config    = require("base/config")
local platform  = require("platform/platform")

-- package info from the given info configure
function package._done_target(name, info)

    -- check
    assert(name and info)

    -- dump
    utils.dump(info)
 
    -- ok
    return true
end

-- done package from the configure
function package.done(configs)

    -- check
    assert(configs)

    -- package targets
    for name, info in pairs(configs) do

        -- package it
        if not package._done_target(name, info) then
            -- errors
            utils.error("package %s failed!", name)
            return false
        end

    end

    -- ok
    return true
end

-- return module: package
return package
