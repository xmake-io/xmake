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
-- @file        swiftc.lua
--

-- load modules
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local config    = require("base/config")
local platform  = require("base/platform")

-- define module: swiftc
local swiftc = swiftc or {}

-- the init function
function swiftc.init(self, name)

    -- save name
    self.name = name or "swiftc"

    -- init flags map
    self.mapflags = 
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
        self.ldflags = { "-L" .. swift_linkdirs }
    end

end

-- make the compile command
function swiftc.command_compile(self, srcfile, objfile, flags, logfile)

    -- redirect
    local redirect = ""
    if logfile then redirect = string.format(" > %s 2>&1", logfile) end

    -- make it
    return string.format("%s -c %s -o %s %s%s", self.name, flags, objfile, srcfile, redirect)
end

-- make the includedir flag
function swiftc.flag_includedir(self, includedir)

    -- make it
    return "-Xcc -I" .. includedir
end

-- make the define flag
function swiftc.flag_define(self, define)

    -- make it
    return "-Xcc -D" .. define:gsub("\"", "\\\"")
end

-- make the undefine flag
function swiftc.flag_undefine(self, undefine)

    -- make it
    return "-Xcc -U" .. undefine
end

-- the main function
function swiftc.main(self, cmd)

    -- execute it
    local ok = os.execute(cmd)

    -- ok?
    return utils.ifelse(ok == 0, true, false)
end

-- return module: swiftc
return swiftc
