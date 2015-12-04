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
-- @file        lib.lua
--

-- define module: lib
local lib = lib or {}

-- load modules
local utils     = require("base/utils")
local string    = require("base/string")
local config    = require("base/config")
local platform  = require("platform/platform")

-- init the compiler
function lib.init(self, name)

    -- save name
    self.name = name or "lib.exe"

end

-- extract the static library to object files
function lib.extract(self, ...)
 
    -- check
    local args = ...
    assert(#args == 2 and self.name)

    -- get library and object file path
    local libfile = args[1]
    local objfile = args[2]
    assert(libfile and objfile)

    -- get object directory
    local objdir = path.directory(objfile)
    if not os.isdir(objdir) then os.mkdir(objdir) end
    if not os.isdir(objdir) then
        utils.error("%s not found!", objdir)
        return false
    end

    print(libfile, objfile)
    assert(false)

    -- ok
    return true
end

-- the main function
function lib.main(self, cmd)

    -- the windows module
    local windows = platform.module()
    assert(windows)

    -- enter envirnoment
    windows.enter()

    -- execute it
    local ok = os.execute(cmd)

    -- leave envirnoment
    windows.leave()

    -- ok?
    return utils.ifelse(ok == 0, true, false)
end

-- return module: lib
return lib
