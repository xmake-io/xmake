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
local platform  = require("base/platform")

-- init the compiler
function cl.init(self, name)

    -- save name
    self.name = name or "cl.exe"

    -- init cxflags
    self.cxflags = { "-nologo", "-Gd", "-MP4", "-D_MBCS", "-D_CRT_SECURE_NO_WARNINGS"}

    -- init flags map
    self.mapflags = 
    {
        -- optimize
        ["-O0"]                     = "-Od"
    ,   ["-O3"]                     = "-Ot"
    ,   ["-Ofast"]                  = "-Ox"
    ,   ["-fomit-frame-pointer"]    = "-Oy"

        -- symbols
    ,   ["-g"]                      = "-Z7"
    ,   ["-fvisibility=.*"]         = ""

        -- warnings
    ,   ["-Wall"]                   = "-W3" -- = "-Wall" will enable too more warnings
    ,   ["-W1"]                     = "-W1"
    ,   ["-W2"]                     = "-W2"
    ,   ["-W3"]                     = "-W3"
    ,   ["-Werror"]                 = "-WX"
    ,   ["%-Wno%-error=.*"]         = ""
    ,   ["%-fno%-.*"]               = ""

        -- vectorexts
    ,   ["-mmmx"]                   = "-arch:MMX"
    ,   ["-msse"]                   = "-arch:SSE"
    ,   ["-msse2"]                  = "-arch:SSE2"
    ,   ["-msse3"]                  = "-arch:SSE3"
    ,   ["-mssse3"]                 = "-arch:SSSE3"
    ,   ["-mavx"]                   = "-arch:AVX"
    ,   ["-mavx2"]                  = "-arch:AVX2"
    ,   ["-mfpu=.*"]                = ""

        -- language
    ,   ["-ansi"]                   = ""
    ,   ["-std=c99"]                = "-TP" -- compile as c++ files because msvc only support c89
    ,   ["-std=c11"]                = "-TP" -- compile as c++ files because msvc only support c89
    ,   ["-std=gnu99"]              = "-TP" -- compile as c++ files because msvc only support c89
    ,   ["-std=gnu11"]              = "-TP" -- compile as c++ files because msvc only support c89
    ,   ["-std=.*"]                 = ""

        -- others
    ,   ["-ftrapv"]                 = ""
    ,   ["-fsanitize=address"]      = ""
    }

end

-- make the compiler command
function cl.command_compile(self, srcfile, objfile, flags, logfile)

    -- redirect
    local redirect = ""
    if logfile then redirect = string.format(" > %s 2>&1", logfile) end

    -- make it
    return string.format("%s -c %s -Fo%s %s%s", self.name, flags, objfile, srcfile, redirect)
end

-- make the define flag
function cl.flag_define(self, define)

    -- make it
    return "-D" .. define:gsub("\"", "\\\"")
end

-- make the undefine flag
function cl.flag_undefine(self, undefine)

    -- make it
    return "-U" .. undefine
end

-- make the includedir flag
function cl.flag_includedir(self, includedir)

    -- make it
    return "-I" .. includedir
end

-- the main function
function cl.main(self, cmd)

    -- the windows module
    local windows = platform.module()
    assert(windows)

    -- enter envirnoment
    windows.enter()

    -- execute it
    local ok = os.execute(cmd)

    -- leave envirnoment
    windows.leave()

    -- ok?
    return utils.ifelse(ok == 0, true, false)
end

-- return module: cl
return cl
