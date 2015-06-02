--!The Automatic Cross-_clang Build Tool
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
-- @file        _clang.lua
--

-- define module: _clang
local _clang = _clang or {}

-- load modules
local utils     = require("base/utils")
local string    = require("base/string")
local config    = require("base/config")

-- init the linker
function _clang._init(configs)

    -- the architecture
    local arch = config.get("arch")
    assert(arch)

    -- init flags for architecture
    local flags_arch = ""
    if arch == "x86" then flags_arch = "-m32"
    elseif arch == "x64" then flags_arch = "-m64"
    else flags_arch = "-arch " .. arch
    end

    -- init ldflags
    configs.ldflags = flags_arch

    -- init shflags
    configs.shflags = flags_arch .. " -dynamiclib"

end

-- make the command
function _clang._make(configs, objfiles, targetfile, flags)

    -- make it
    return string.format("%s %s -o%s %s", configs.name, flags, objfiles, targetfile)
end

-- map gcc flag to the current linker flag
function _clang._mapflag(configs, flag)

    -- ok
    return flag
end

-- return module: _clang
return _clang
