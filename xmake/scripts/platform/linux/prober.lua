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
-- @file        _prober.lua
--

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")

-- define module: _prober
local _prober = _prober or {}

-- probe the architecture
function _prober._probe_arch(configs)

    -- get the architecture
    local arch = configs.arch

    -- ok? 
    if arch then return true end

    -- init the default architecture
    configs.arch = xmake._ARCH

    -- ok
    return true
end

-- probe the configure 
function _prober.done(configs, is_global)

    -- probe the architecture
    if not _prober._probe_arch(configs) then return end

end

-- return module: _prober
return _prober
