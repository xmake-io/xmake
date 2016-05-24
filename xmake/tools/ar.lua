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
function init(shellname, kind)
    
    -- save the shell name
    _g.shellname = shellname or "ar"

    -- save the tool kind
    _g.kind = kind or "ar"

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
function linkcmd(objectfiles, targetfile, flags)

    -- make it
    return format("%s %s %s %s", _g.shellname, flags, targetfile, objectfiles)
end

-- extract the static library to object directory
function extract(libraryfile, objectdir)

    -- make the object directory first
    os.mkdir(objectdir)

    -- get the absolute path of this library
    libraryfile = path.absolute(libraryfile)

    -- enter the object directory
    os.cd(objectdir)

    -- extract it
    os.run("%s -x %s", _g.shellname, libraryfile)

    -- TODO 
    -- check repeat object name

    -- leave the object directory
    os.cd("-")
end

-- run command
function run(...)

    -- extract it
    if _g.kind == "ex" then
        return extract(...)
    end

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
