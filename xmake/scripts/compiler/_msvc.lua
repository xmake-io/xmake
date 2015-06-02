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
-- @file        _msvc.lua
--

-- define module: _msvc
local _msvc = _msvc or {}

-- load modules
local utils     = require("base/utils")
local string    = require("base/string")
local config    = require("base/config")

-- init the compiler
function _msvc._init(configs)

    -- the architecture
    local arch = config.get("arch")
    assert(arch)

    -- init cflags
    configs.cflags = "-nologo"

    -- init cxxflags
    configs.cxxflags = "-nologo"

end

-- make the compiler command
function _msvc._make(configs, srcfile, objfile, flags)

    -- make it
    return string.format("%s -c %s -Fo%s %s", configs.name, flags, objfile, srcfile)
end

-- make the define flag
function _msvc._make_define(configs, define)

    -- make it
    return "-D" .. define
end

-- make the includedir flag
function _msvc._make_includedir(configs, includedir)

    -- make it
    return "-I" .. includedir
end

-- map gcc flag to the current compiler flag
function _msvc._mapflag(configs, flag)

    -- ok
    return flag
end

-- return module: _msvc
return _msvc
