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
-- @file        cl.lua
--

-- define module: cl
local cl = cl or {}

-- load modules
local utils     = require("base/utils")
local string    = require("base/string")
local config    = require("base/config")

-- init the compiler
function cl.init(name)

    -- init cflags
    cl.cflags = { "-nologo" }

    -- init cxxflags
    cl.cxxflags = { "-nologo" }

    -- init flags map
    cl.mapflags = 
    {
        -- optimize
        ["-O0"]                     = "-Od"
    ,   ["-O3"]                     = "-Ot"
    ,   ["-Ofast"]                  = "-Ox"
    ,   ["-fomit-frame-pointer"]    = "-Oy"

        -- warning
    ,   ["-Werror"]                 = "-WX"
    ,   ["%-Wno%-error=(.*)"]       = ""
    }

end

-- make the compiler command
function cl.command_compile(srcfile, objfile, flags)

    -- make it
    return string.format("cl.exe -c %s -Fo%s %s", flags, objfile, srcfile)
end

-- make the define flag
function cl.flag_define(define)

    -- make it
    return "-D" .. define
end

-- make the includedir flag
function cl.flag_includedir(includedir)

    -- make it
    return "-I" .. includedir
end

-- the main function
function cl.main(...)

    -- ok
    return true
end

-- return module: cl
return cl
