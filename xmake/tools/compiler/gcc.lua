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

    -- init cxflags for the kind: shared
    _g.shared         = {}
    _g.shared.cxflags = {"-fPIC"}

    -- init flags map
    _g.mapflags = 
    {
        -- warnings
        ["-W1"]                     = "-Wall"
    ,   ["-W2"]                     = "-Wall"
    ,   ["-W3"]                     = "-Wall"
 
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

-- make the command
function command(srcfile, objfile, flags, logfile)

    -- redirect
    local redirect = ""
    if logfile then redirect = format(" > %s 2>&1", logfile) end

    -- make it
    return format("%s -c %s -o %s %s%s", _g.shellname, flags, objfile, srcfile, redirect)
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
