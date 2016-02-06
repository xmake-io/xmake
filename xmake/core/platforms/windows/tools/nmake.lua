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
-- @file        nmake.lua
--

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")
local config    = require("base/config")
local platform  = require("base/platform")

-- define module: nmake
local nmake = nmake or {}

-- the init function
function nmake.init(self, name)

    -- save name
    self.name = name or "nmake.exe"

    -- is verbose?
    self._VERBOSE = utils.ifelse(xmake._OPTIONS.verbose, "-v", "")

end

-- the main function
function nmake.main(self, mkfile, target)

    -- the windows module
    local windows = platform.module()
    assert(windows)

    -- enter envirnoment
    windows.enter()

    -- make command
    local cmd = nil
    if mkfile and os.isfile(mkfile) then
        cmd = string.format("%s /nologo /f %s %s VERBOSE=%s", self.name, mkfile, target or "", self._VERBOSE)
    else  
        cmd = string.format("%s /nologo %s VERBOSE=%s", self.name, target or "", self._VERBOSE)
    end

    -- done 
    local ok = os.execute(cmd)

    -- leave envirnoment
    windows.leave()

    -- ok?
    return utils.ifelse(ok == 0, true, false)
end

-- return module: nmake
return nmake
