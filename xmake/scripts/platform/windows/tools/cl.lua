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

-- enter the given environment
function cl._enter(name)

    -- check
    assert(name)

    -- get the pathes for the vs environment
    local old = nil
    local new = config.get("__vsenv_" .. name)
    if new then

        -- get the current pathes
        old = os.getenv(name) or ""

        -- append the current pathes
        new = new .. ";" .. old

        -- update the pathes for the environment
        os.setenv(name, new)
    end

    -- return the previous environment
    return old;
end

-- leave the given environment
function cl._leave(name, old)

    -- check
    assert(name)

    -- restore the previous environment
    if old then 
        os.setenv(name, old)
    end
end

-- init the compiler
function cl.init(self, name)

    -- save name
    self._NAME = name or "cl.exe"

    -- init cflags
    self.cflags = { "-nologo" }

    -- init cxxflags
    self.cxxflags = { "-nologo" }

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
    ,   ["-Werror"]                 = "-WX"
    ,   ["%-Wno%-error=.*"]         = ""

        -- vectorexts
    ,   ["-mmmx"]                   = "-arch:mmx"
    ,   ["-msse"]                   = "-arch:sse"
    ,   ["-msse2"]                  = "-arch:sse2"
    ,   ["-msse3"]                  = "-arch:sse3"
    ,   ["-mssse3"]                 = "-arch:ssse3"
    ,   ["-mavx"]                   = "-arch:avx"
    ,   ["-mavx2"]                  = "-arch:avx2"
    ,   ["-mfpu=.*"]                = ""

        -- language
    ,   ["-ansi"]                   = ""
    ,   ["-std=.*"]                 = ""

        -- others
    ,   ["-ftrapv"]                 = ""
    ,   ["-fsanitize=address"]      = ""
    }

end

-- make the compiler command
function cl.command_compile(self, srcfile, objfile, flags)

    -- make it
    return string.format("%s -c %s -Fo%s %s", self._NAME, flags, objfile, srcfile)
end

-- make the define flag
function cl.flag_define(self, define)

    -- make it
    return "-D" .. define
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

    -- enter the vs environment
    local pathes    = cl._enter("path")
    local libs      = cl._enter("lib")
    local includes  = cl._enter("include")
    local libpathes = cl._enter("libpath")

    -- execute it
    local ok = os.execute(cmd)

    -- leave the vs environment
    cl._leave("path",       pathes)
    cl._leave("lib",        libs)
    cl._leave("include",    includes)
    cl._leave("libpath",    libpathes)

    -- ok?
    return utils.ifelse(ok == 0, true, false)
end

-- return module: cl
return cl
