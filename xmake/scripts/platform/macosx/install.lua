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
-- @file        install.lua
--

-- define module: install
local install = install or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local rule      = require("base/rule")
local utils     = require("base/utils")
local string    = require("base/string")
local platform  = require("platform/platform")

-- install target for the library file
function install._done_library(target)

    -- dump
    utils.dump(target)

    -- ok
    return 1
end

-- install target for the binary file
function install._done_binary(target)

    -- dump
    utils.dump(target)

    -- ok
    return 1
end

-- install target 
function install.main(target)

    -- check
    assert(target and target.kind)

    -- the install scripts
    local installscripts = 
    {
        static = install._done_library
    ,   shared = install._done_library
    ,   binary = install._done_binary
    }

    -- install it
    local installscript = installscripts[target.kind]
    if installscript then return installscript(target) end

    -- continue
    return 0
end

-- return module: install
return install
