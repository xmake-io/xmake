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
-- @file        swiftc.lua
--

-- imports
import("core.project.config")

-- init it
function init(shellname)
    
    -- save the shell name
    _g.shellname = shellname or "swiftc"

    -- init flags map
    _g.mapflags = 
    {
        -- symbols
        ["-fvisibility=hidden"]     = ""

        -- warnings
    ,   ["-w"]                      = ""
    ,   ["-W.*"]                    = ""

        -- optimize
    ,   ["-O0"]                     = "-Onone"
    ,   ["-Ofast"]                  = "-Ounchecked"
    ,   ["-O.*"]                    = "-O"

        -- vectorexts
    ,   ["-m.*"]                    = ""

        -- strip
    ,   ["-s"]                      = ""
    ,   ["-S"]                      = ""

        -- others
    ,   ["-ftrapv"]                 = ""
    ,   ["-fsanitize=address"]      = ""
    }

    -- init ldflags
    local swift_linkdirs = config.get("__swift_linkdirs")
    if swift_linkdirs then
        _g.ldflags = { "-L" .. swift_linkdirs }
    end

end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- make the compile command
function command(srcfile, objfile, flags, logfile)

    -- redirect
    local redirect = ""
    if logfile then redirect = format(" > %s 2>&1", logfile) end

    -- make it
    return format("%s -c %s -o %s %s%s", _g.shellname, flags, objfile, srcfile, redirect)
end

-- make the includedir flag
function includedir(dir)

    -- make it
    return "-Xcc -I" .. dir
end

-- make the define flag
function define(macro)

    -- make it
    return "-Xcc -D" .. macro:gsub("\"", "\\\"")
end

-- make the undefine flag
function undefine(macro)

    -- make it
    return "-Xcc -U" .. macro
end

