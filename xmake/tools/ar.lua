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
-- @file        ar.lua
--

-- imports
import("core.tool.compiler")

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

-- make the strip flag
function strip(level)

    -- the maps
    local maps = 
    {   
        debug       = "-S"
    ,   all         = "-s"
    }

    -- make it
    return maps[level] or ""
end

-- make the archive command
function archivecmd(objectfiles, targetfile, flags)

    -- make it
    return format("%s %s %s %s", _g.shellname, flags, targetfile, objectfiles)
end

-- archive the library file
function archive(objectfiles, targetfile, flags)

    -- ensure the target directory
    os.mkdir(path.directory(targetfile))

    -- link it
    os.run(archivecmd(objectfiles, targetfile, flags))
end

-- extract the static library to object directory
function extract(libraryfile, objectdir)

    -- make the object directory first
    os.mkdir(objectdir)

    -- get the absolute path of this library
    libraryfile = path.absolute(libraryfile)

    -- enter the object directory
    local olddir = os.cd(objectdir)

    -- extract it
    os.run("%s -x %s", _g.shellname, libraryfile)

    -- check repeat object name
    local repeats = {}
    local objectfiles = os.iorun("%s -t %s", _g.shellname, libraryfile)
    for _, objectfile in ipairs(objectfiles:split('\n')) do
        if repeats[objectfile] then
            raise("object name(%s) conflicts in library: %s", objectfile, libraryfile)
        end
        repeats[objectfile] = true
    end                                                          

    -- leave the object directory
    os.cd(olddir)
end

-- check the given flags 
function check(flags)

    -- make an stub source file
    local libraryfile   = path.join(os.tmpdir(), "xmake.ar.a")
    local objectfile    = path.join(os.tmpdir(), "xmake.ar.o")
    local sourcefile    = path.join(os.tmpdir(), "xmake.ar.c")
    io.write(sourcefile, "int test(void)\n{return 0;}")

    -- make flags
    local arflags = table.concat(_g.arflags, " ")
    if flags then
        arflags = arflags .. " " .. flags
    end

    -- compile it
    compiler.compile(sourcefile, objectfile)

    -- check it
    archive(objectfile, libraryfile, arflags)

    -- remove files
    os.rm(objectfile)
    os.rm(sourcefile)
    os.rm(libraryfile)
end
