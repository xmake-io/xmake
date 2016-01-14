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
-- @file        link.lua
--

-- define module: link
local link = link or {}

-- load modules
local utils     = require("base/utils")
local string    = require("base/string")
local config    = require("base/config")
local platform  = require("base/platform")

-- init the compiler
function link.init(self, name)

    -- save name
    self.name = name or "link.exe"

    -- the architecture
    local arch = config.get("arch")
    assert(arch)

    -- init flags for architecture
    local flags_arch = ""
    if arch == "x86" then flags_arch = "-machine:x86"
    elseif arch == "x64" or arch == "amd64" or arch == "x86_amd64" then flags_arch = "-machine:x64"
    end

    -- init ldflags
    self.ldflags =  { "-nologo"
                    , "-dynamicbase"
                    , "-nxcompat"
                    , flags_arch}

    -- init arflags
    self.arflags = {"-nologo", flags_arch}

    -- init shflags
    self.shflags = {"-nologo", flags_arch}

    -- init flags map
    self.mapflags = 
    {
        -- strip
        ["-s"]                     = ""
    ,   ["-S"]                     = ""
 
        -- others
    ,   ["-ftrapv"]                = ""
    ,   ["-fsanitize=address"]     = ""
    }

end

-- make the linker command
function link.command_link(self, objfiles, targetfile, flags, logfile)

    -- redirect
    local redirect = ""
    if logfile then redirect = string.format(" > %s 2>&1", logfile) end

    -- make it
    local cmd = string.format("%s %s -out:%s %s%s", self.name, flags, targetfile, objfiles, redirect)

    -- too long?
    if #cmd > 256 then
        cmd = string.format("%s%s @<<\n%s -out:%s %s\n<<", self.name, redirect, flags, targetfile, objfiles)
    end

    -- ok?
    return cmd
end

-- make the link flag
function link.flag_link(self, link)

    -- make it
    return link .. ".lib"
end

-- make the linkdir flag
function link.flag_linkdir(self, linkdir)

    -- make it
    return "-libpath:" .. linkdir
end

-- the main function
function link.main(self, cmd)

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

-- return module: link
return link
