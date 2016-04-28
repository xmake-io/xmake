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
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        nmake.lua
--

-- imports
import("utils.vsenv")
import("core.base.option")

-- init it
function init(shellname)

    -- save name
    _g.shellname = shellname or "nmake.exe"

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- run it
function run(makefile, target, jobs)

    -- is verbose?
    local verbose = ifelse(option.get("verbose"), "-v", "")

    -- enter vs envirnoment
    vsenv.enter()

    -- run command
    local ok = -1
    if makefile and os.isfile(makefile) then
        ok = os.execute("%s /nologo /f %s %s VERBOSE=%s", _g.shellname, makefile, target or "", verbose)
    else  
        ok = os.execute("%s /nologo %s VERBOSE=%s", _g.shellname, target or "", verbose)
    end

    -- leave vs envirnoment
    vsenv.leave()

    -- always failed?
    if ok ~= 0 then
        raise(ok)
    end
end

-- check the given flags 
function check(flags)

    -- make an empty makefile
    local makefile = path.join(os.tmpdir(), "xmake.checker.nmake")
    io.write(makefile, "all:\n")

    -- enter vs envirnoment
    vsenv.enter()

    -- check it
    os.run("%s /nologo %s /f %s", _g.shellname, ifelse(flags, flags, ""), makefile)

    -- leave vs envirnoment
    vsenv.leave()
    
    -- remove this makefile
    os.rm(makefile)
end

