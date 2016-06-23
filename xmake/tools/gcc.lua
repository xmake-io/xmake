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

    -- init mxflags
    _g.mxflags = {  "-fmessage-length=0"
                ,   "-pipe"
                ,   "-fpascal-strings"
                ,   "\"-DIBOutlet=__attribute__((iboutlet))\""
                ,   "\"-DIBOutletCollection(ClassName)=__attribute__((iboutletcollection(ClassName)))\""
                ,   "\"-DIBAction=void)__attribute__((ibaction)\""}

    -- init shflags
    _g.shflags = { "-shared", "-fPIC" }

    -- init cxflags for the kind: shared
    _g.shared         = {}
    _g.shared.cxflags = {"-fPIC"}

    -- init flags map
    _g.mapflags = 
    {
        -- warnings
        ["-W1"] = "-Wall"
    ,   ["-W2"] = "-Wall"
    ,   ["-W3"] = "-Wall"

         -- strip
    ,   ["-s"]  = "-s"
    ,   ["-S"]  = "-S"

    }
end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- make the define flag
function define(macro)

    -- make it
    return "-D" .. macro:gsub("\"", "\\\"")
end

-- make the undefine flag
function undefine(macro)

    -- make it
    return "-U" .. macro
end

-- make the includedir flag
function includedir(dir)

    -- make it
    return "-I" .. dir
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

-- make the complie command
function compcmd(srcfile, objfile, flags)

    -- make it
    return format("%s -c %s -o %s %s", _g.shellname, flags, objfile, srcfile)
end

-- make the link command
function linkcmd(objfiles, targetfile, flags)

    -- make it
    return format("%s -o %s %s %s", _g.shellname, targetfile, objfiles, flags)
end

-- run command
function run(...)

    -- run it
    os.run(...)
end

-- check the given flags 
function check(flags)

    -- make an stub source file
    local objfile = path.join(os.tmpdir(), "xmake.gcc.o")
    local srcfile = path.join(os.tmpdir(), "xmake.gcc.c")
    io.write(srcfile, "int main(int argc, char** argv)\n{return 0;}")

    -- check it
    os.run("%s -c %s -o %s %s", _g.shellname, ifelse(flags, flags, ""), objfile, srcfile)

    -- remove files
    os.rm(objfile)
    os.rm(srcfile)
end

