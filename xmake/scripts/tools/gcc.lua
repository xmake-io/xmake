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
-- @file        gcc.lua
--

-- load modules
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local config    = require("base/config")

-- define module: gcc
local gcc = gcc or {}

-- check the given flag 
function gcc._check(flag)

    -- this flag has been checked?
    gcc._CHECK = gcc._CHECK or {}
    if gcc._CHECK[flag] then
        return gcc._CHECK[flag]
    end

    -- check it
    if 0 ~= os.execute(string.format("%s %s -S -o %s -xc %s > %s 2>&1", gcc.name, flag, xmake._NULDEV, xmake._NULDEV, xmake._NULDEV)) then
        flag = ""
    end

    -- save it
    gcc._CHECK[flag] = flag

    -- ok?
    return flag
end

-- the init function
function gcc.init(name)

    -- save name
    gcc.name = name or "gcc"

    -- the architecture
    local arch = config.get("arch")
    assert(arch)

    -- init flags for architecture
    local flags_arch = ""
    if arch == "x86" then flags_arch = "-m32"
    elseif arch == "x64" then flags_arch = "-m64"
    else flags_arch = "-arch " .. arch
    end

    -- init cxflags
    gcc.cxflags = { flags_arch }

    -- init mxflags
    gcc.mxflags = { flags_arch
                ,   "-fmessage-length=0"
                ,   "-pipe"
                ,   "-fpascal-strings"
                ,   "\"-DIBOutlet=__attribute__((iboutlet))\""
                ,   "\"-DIBOutletCollection(ClassName)=__attribute__((iboutletcollection(ClassName)))\""
                ,   "\"-DIBAction=void)__attribute__((ibaction)\""}

    -- init asflags
    gcc.asflags = { flags_arch } 

    -- init ldflags
    gcc.ldflags = { flags_arch }

    -- init shflags
    gcc.shflags = { flags_arch, "-shared -Wl,-soname" }

    -- init flags map
    gcc.mapflags = 
    {
        -- others
        ["-ftrapv"]                     = gcc._check
    ,   ["-fsanitize=address"]          = gcc._check
    }

end

-- make the compile command
function gcc.command_compile(srcfile, objfile, flags)

    -- make it
    return string.format("%s -c %s -o%s %s", gcc.name, flags, objfile, srcfile)
end

-- make the link command
function gcc.command_link(objfiles, targetfile, flags)

    -- make it
    return string.format("%s %s -o%s %s", gcc.name, flags, targetfile, objfiles)
end

-- make the define flag
function gcc.flag_define(define)

    -- make it
    return "-D" .. define
end

-- make the includedir flag
function gcc.flag_includedir(includedir)

    -- make it
    return "-I" .. includedir
end

-- make the link flag
function gcc.flag_link(link)

    -- make it
    return "-l" .. link
end

-- make the linkdir flag
function gcc.flag_linkdir(linkdir)

    -- make it
    return "-L" .. linkdir
end

-- the main function
function gcc.main(...)

    -- ok
    return true
end

-- return module: gcc
return gcc
