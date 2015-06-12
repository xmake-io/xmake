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
local platform  = require("platform/platform")

-- init the compiler
function link.init(self, name)

    -- save name
    self._NAME = name or "link.exe"

    -- the architecture
    local arch = config.get("arch")
    assert(arch)

    -- init flags for architecture
    local flags_arch = ""
    if arch == "x86" then flags_arch = "-machine:x86"
    elseif arch == "x64" then flags_arch = "-machine:x86_64"
    end

    -- init ldflags
    self.ldflags =  { "-nologo"
                    , "-dynamicbase"
                    , "-nxcompat"
                    , "-manifest"
                    , "-manifestuac:\"level='asInvoker' uiAccess='false'\""
                    , flags_arch}

    -- init arflags
    self.arflags = {"-lib", "-nologo", flags_arch}

    -- init shflags
    self.shflags = {"-dll", "-nologo", flags_arch}

    -- init flags map
    self.mapflags = 
    {
        -- strip
        ["-s"]                     = ""
    ,   ["-S"]                     = ""
    ,   ["--strip-all"]            = ""
    ,   ["--strip-debug"]          = ""
 
        -- others
    ,   ["-ftrapv"]                = ""
    }

end

-- make the linker command
function link.command_link(self, objfiles, targetfile, flags)

    -- make it
    return string.format("%s %s -out:%s %s", self._NAME, flags, targetfile, objfiles)
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
