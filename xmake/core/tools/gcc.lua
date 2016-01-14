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
local platform  = require("base/platform")

-- define module: gcc
local gcc = gcc or {}

-- check the given flag 
function gcc._check(self, flag)

    -- this flag has been checked?
    self._CHECK = self._CHECK or {}
    if self._CHECK[flag] then
        return self._CHECK[flag]
    end

    -- check it
    local result = flag
    if 0 ~= os.execute(string.format("%s %s -S -o %s -xc %s > %s 2>&1", self.name, flag, xmake._NULDEV, xmake._NULDEV, xmake._NULDEV)) then
        result = ""
    end

    -- trace
    utils.verbose("checking for the compiler flags %s ... %s", flag, utils.ifelse(#result ~= 0, "ok", "no"))

    -- save it
    self._CHECK[flag] = result

    -- ok?
    return result
end

-- the init function
function gcc.init(self, name)

    -- save name
    self.name = name or "gcc"

    -- init mxflags
    self.mxflags = {    "-fmessage-length=0"
                    ,   "-pipe"
                    ,   "-fpascal-strings"
                    ,   "\"-DIBOutlet=__attribute__((iboutlet))\""
                    ,   "\"-DIBOutletCollection(ClassName)=__attribute__((iboutletcollection(ClassName)))\""
                    ,   "\"-DIBAction=void)__attribute__((ibaction)\""}

    -- init shflags
    if name:find("clang") then
        self.shflags = { "-dynamiclib", "-fPIC" }
    else
        self.shflags = { "-shared", "-fPIC" }
    end

    -- init cxflags for the kind: shared
    self.shared         = {}
    self.shared.cxflags = {"-fPIC"}

    -- suppress warning for the clang
    local isclang = false
    if name:find("clang") then
        isclang = true
        self.cxflags = self.cxflags or {}
        self.mxflags = self.mxflags or {}
        self.asflags = self.asflags or {}
        table.join2(self.cxflags, "-Qunused-arguments")
        table.join2(self.mxflags, "-Qunused-arguments")
        table.join2(self.asflags, "-Qunused-arguments")
    end

    -- init flags map
    self.mapflags = 
    {
        -- vectorexts
        ["-mmmx"]                   = self._check
    ,   ["-msse$"]                  = self._check
    ,   ["-msse2"]                  = self._check
    ,   ["-msse3"]                  = self._check
    ,   ["-mssse3"]                 = self._check
    ,   ["-mavx$"]                  = self._check
    ,   ["-mavx2"]                  = self._check
    ,   ["-mfpu=.*"]                = self._check

        -- warnings
    ,   ["-W1"]                     = "-Wall"
    ,   ["-W2"]                     = "-Wall"
    ,   ["-W3"]                     = "-Wall"

        -- strip
    ,   ["-s"]                      = utils.ifelse(isclang, "-Wl,-S", "-s")
    ,   ["-S"]                      = utils.ifelse(isclang, "-Wl,-S", "-S")
 
        -- others
    ,   ["-ftrapv"]                 = self._check
    ,   ["-fsanitize=address"]      = self._check
    }

end

-- make the compile command
function gcc.command_compile(self, srcfile, objfile, flags, logfile)

    -- redirect
    local redirect = ""
    if logfile then redirect = string.format(" > %s 2>&1", logfile) end

    -- make it
    return string.format("%s -c %s -o %s %s%s", self.name, flags, objfile, srcfile, redirect)
end

-- make the link command
function gcc.command_link(self, objfiles, targetfile, flags, logfile)

    -- redirect
    local redirect = ""
    if logfile then redirect = string.format(" > %s 2>&1", logfile) end

    -- make it
    return string.format("%s -o %s %s %s%s", self.name, targetfile, objfiles, flags, redirect)
end

-- make the define flag
function gcc.flag_define(self, define)

    -- make it
    return "-D" .. define:gsub("\"", "\\\"")
end

-- make the undefine flag
function gcc.flag_undefine(self, undefine)

    -- make it
    return "-U" .. undefine
end

-- make the includedir flag
function gcc.flag_includedir(self, includedir)

    -- make it
    return "-I" .. includedir
end

-- make the link flag
function gcc.flag_link(self, link)

    -- make it
    return "-l" .. link
end

-- make the linkdir flag
function gcc.flag_linkdir(self, linkdir)

    -- make it
    return "-L" .. linkdir
end

-- the main function
function gcc.main(self, cmd)

    -- execute it
    local ok = os.execute(cmd)

    -- ok?
    return utils.ifelse(ok == 0, true, false)
end

-- return module: gcc
return gcc
