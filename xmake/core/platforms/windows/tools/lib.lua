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
-- @file        lib.lua
--

-- define module: lib
local lib = lib or {}

-- load modules
local io        = require("base/io")
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")
local config    = require("base/config")
local platform  = require("base/platform")

-- init the compiler
function lib.init(self, name)

    -- save name
    self.name = name or "lib.exe"

end

-- extract the static library to object files
function lib.extract(self, ...)
 
    -- check
    local args = ...
    assert(#args == 2 and self.name)

    -- get library and object file path
    local libfile = args[1]
    local objfile = args[2]
    assert(libfile and objfile)

    -- get object directory
    local objdir = path.directory(objfile)
    if not os.isdir(objdir) then os.mkdir(objdir) end
    if not os.isdir(objdir) then
        utils.error("%s not found!", objdir)
        return false
    end

    -- the windows module
    local windows = platform.module()
    assert(windows)

    -- enter envirnoment
    windows.enter()

    -- list object files 
    local file = io.popen(string.format("%s -nologo -list %s", self.name, libfile))
    if not file then
        utils.error("extract %s to %s failed!", libfile, objdir)
        windows.leave()
        return false
    end

    -- extrace all object files
    for line in file:lines() do

        -- is object file?
        if line:find("%.obj") then

            -- init command
            local out = path.translate(string.format("%s\\%s", objdir, path.filename(line)))

            -- repeat? rename it
            if os.isfile(out) then
                for i = 0, 10 do
                    out = path.translate(string.format("%s\\%d_%s", objdir, i, path.filename(line)))
                    if not os.isfile(out) then break end
                end
            end

            -- init command
            local cmd = string.format("%s -nologo -extract:%s -out:%s %s", self.name, line, out, libfile)

            -- extract it
            if 0 ~= os.execute(cmd) then
                utils.error("extract %s to %s failed!", libfile, objdir)
                windows.leave()
                return false
            end
        end
    end

    -- exit file
    file:close()

    -- leave envirnoment
    windows.leave()

    -- ok
    return true
end

-- the main function
function lib.main(self, cmd)

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

-- return module: lib
return lib
