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
-- @file        extract.lua
--

-- define module: extract
local extract = extract or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")

-- the main function
--
-- extract /home/[lib]xxx.[a|lib] /home/xxx/*.[o|obj]
-- only support: ar -x library
function extract.main(self, ...)

    -- check
    local args = ...
    assert(#args == 3)

    -- get toolname
    local toolname = args[1]
    assert(toolname)

    -- be not ar?
    if not toolname:find("ar", 1, true) then
        utils.error("%s is not ar!", toolname)
        return false
    end

    -- get library and object file path
    local libfile = args[2]
    local objfile = args[3]
    assert(libfile and objfile)

    -- get object directory
    local objdir = path.directory(objfile)
    if not os.isdir(objdir) then os.mkdir(objdir) end
    if not os.isdir(objdir) then
        utils.error("%s not found!", objdir)
        return false
    end

    -- absolute the library path
    libfile = path.absolute(libfile)
    assert(libfile)

    -- enter the object directory
    ok, errors = os.cd(objdir)
    if not ok then
        utils.error(errors)
        return false
    end

    -- extract it
    local ok = os.execute(string.format("%s -x %s", toolname, libfile))
    if ok ~= 0 then
        utils.error("extract %s to %s failed!", libfile, objdir)
        return false
    end

    -- leave the object directory
    ok, errors = os.cd("-")
    if not ok then
        utils.error(errors)
        return false
    end

    -- ok
    return true
end

-- return module: extract
return extract
