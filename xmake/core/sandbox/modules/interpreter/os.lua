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
-- @file        os.lua
--

-- load modules
local os        = require("base/os")
local string    = require("base/string")

-- define module
local sandbox_os = sandbox_os or {}

-- export some readonly interfaces
sandbox_os.date     = os.date
sandbox_os.time     = os.time
sandbox_os.mtime    = os.mtime
sandbox_os.mclock   = os.mclock
sandbox_os.getenv   = os.getenv
sandbox_os.dirs     = os.dirs
sandbox_os.host     = os.host
sandbox_os.arch     = os.arch
sandbox_os.isfile   = os.isfile
sandbox_os.exists   = os.exists
sandbox_os.curdir   = os.curdir
sandbox_os.tmpdir   = os.tmpdir
sandbox_os.uuid     = os.uuid

-- match files
function sandbox_os.files(pattern, ...)
    return os.match(string.format(pattern, ...))
end

-- match directories
function sandbox_os.dirs(pattern, ...)
    return os.match(string.format(pattern, ...), true)
end

-- return module
return sandbox_os

