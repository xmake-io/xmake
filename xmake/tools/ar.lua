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
-- @file        ar.lua
--

-- init it
function init(shellname)
    
    -- save the shell name
    _g.shellname = shellname or "ar"

    -- init arflags
    _g.arflags = { "-cr" }

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- make the link flag
function link(lib)
end

-- make the linkdir flag
function linkdir(dir)
end

-- make the link command
function linkcmd(objfiles, targetfile, flags, logfile)

    -- redirect
    local redirect = ""
    if logfile then redirect = format(" > %s 2>&1", logfile) end

    -- make it
    return format("%s %s %s %s%s", _g.shellname, flags, targetfile, objfiles, redirect)
end

-- run command
function run(...)

    -- run it
    os.run(...)
end

-- check the given flags 
function check(flags)

    -- check it
    local ok = os.execute("%s %s > %s 2>&1", _g.shellname, ifelse(flags, flags, ""), os.nuldev())
    if ok ~= 0 and ok ~= 256 then
        raise("not found!")
    end
end
