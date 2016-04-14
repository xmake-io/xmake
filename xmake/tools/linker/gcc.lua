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
-- @file        gcc.lua
--

-- init it
function init(shellname)
    
    -- save the shell name
    _g.shellname = shellname or "gcc"

    -- init shflags
    _g.shflags = { "-shared", "-fPIC" }

    -- init flags map
    _g.mapflags = 
    {
        -- strip
        ["-s"]  = "-s"
    ,   ["-S"]  = "-S"
 
    }
end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- make the link flag
function link(lib)

    -- make it
    return "-l" .. lib
end

-- make the linkdir flag
function linkdir(dir)

    -- make it
    return "-L" .. dir
end

-- make the command
function command(objfiles, targetfile, flags, logfile)

    -- redirect
    local redirect = ""
    if logfile then redirect = format(" > %s 2>&1", logfile) end

    -- make it
    return format("%s -o %s %s %s%s", _g.shellname, targetfile, objfiles, flags, redirect)
end

-- check the given flags 
function check(flags)

    -- done
    local ok = false
    try
    {
        function ()
    
            -- check it
            os.run("%s %s -S -o $(nuldev) -xc $(nuldev) > $(nuldev) 2>&1", _g.shellname, flags)
            
            -- ok
            ok = true

        end
    }

    -- ok?
    return ok
end

-- run command
function run(...)

    -- run it
    os.run(...)
end
