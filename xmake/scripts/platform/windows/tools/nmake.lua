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

-- define module: nmake
local nmake = nmake or {}

-- enter the given environment
function nmake._enter(name)

    -- check
    assert(name)

    -- get the pathes for the vs environment
    local old = nil
    local new = config.get("__vsenv_" .. name)
    if new then

        -- get the current pathes
        old = os.getenv(name) or ""

        -- append the current pathes
        new = new .. ";" .. old

        -- update the pathes for the environment
        os.setenv(name, new)
    end

    -- return the previous environment
    return old;
end

-- leave the given environment
function nmake._leave(name, old)

    -- check
    assert(name)

    -- restore the previous environment
    if old then 
        os.setenv(name, old)
    end
end

-- the init function
function nmake.init()

    -- is verbose?
    nmake._VERBOSE = utils.ifelse(xmake._OPTIONS.verbose, "-v", "")

end

-- the main function
function nmake.main(mkfile, target)

    -- enter the vs environment
    local pathes    = nmake._enter("path")
    local libs      = nmake._enter("lib")
    local includes  = nmake._enter("include")
    local libpathes = nmake._enter("libpath")

    -- make command
    local cmd = nil
    if mkfile and os.isfile(mkfile) then
        cmd = string.format("nmake /f %s %s VERBOSE=%s 2> nul", mkfile, target or "", nmake._VERBOSE)
    else  
        cmd = string.format("nmake %s VERBOSE=%s 2> nul", target or "", nmake._VERBOSE)
    end

    -- done 
    local ok = os.execute(cmd)

    -- leave the vs environment
    nmake._leave("path",       pathes)
    nmake._leave("lib",        libs)
    nmake._leave("include",    includes)
    nmake._leave("libpath",    libpathes)

    -- ok?
    return utils.ifelse(ok == 0, true, false)
end

-- return module: nmake
return nmake
