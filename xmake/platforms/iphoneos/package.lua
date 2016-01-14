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
-- @file        package.lua
--

-- define module: package
local package = package or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local rule      = require("base/rule")
local utils     = require("base/utils")
local string    = require("base/string")
local platform  = require("base/platform")

-- package target 
function package.main(target)

    -- check
    assert(target and target.name)

    -- the count of architectures
    local count = 0
    for _, _ in pairs(target.archs) do count = count + 1 end
    if count < 2 then return 0 end

    -- get the lipo tool
    local lipo = platform.tool("lipo")
    if not lipo then return 0 end

    -- make universal info
    local universal = {}
    universal.targetdir = rule.backupdir(target.name, "universal")
    universal.targetfile = rule.targetfile(target.name, target)
    if not universal.targetdir or not universal.targetfile then return 0 end

    -- make the universal directory
    os.mkdir(path.directory(string.format("%s/%s", universal.targetdir, universal.targetfile)))

    -- make the lipo command
    local cmd = lipo .. " -create"
    for arch, info in pairs(target.archs) do
        cmd = string.format("%s -arch %s %s/%s", cmd, arch, info.targetdir, info.targetfile)
    end
    cmd = string.format("%s -output %s/%s", cmd, universal.targetdir, universal.targetfile)

    -- make the universal target
    if 0 ~= os.execute(cmd) then return 0 end

    -- ok
    target.archs.universal = universal

    -- continue
    return 0
end

-- return module: package
return package
