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
-- @file        uninstall.lua
--

-- define module: uninstall
local uninstall = uninstall or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local rule      = require("base/rule")
local utils     = require("base/utils")
local string    = require("base/string")
local platform  = require("base/platform")

-- uninstall target for the library file
function uninstall._done_library(target)

    -- check
    assert(target and target.name and target.archs)

    -- get target info
    local info = target.archs[xmake._ARCH] or target.archs["x86_64"] or target.archs["i386"]
    if not info then return -1 end

    -- check
    assert(info.targetdir and info.targetfile)

    -- remove the target file
    local targetfile = info.targetdir .. "/" .. info.targetfile
    if os.isfile(targetfile) then 
        local ok, errors = os.rm(targetfile) 
        if not ok then
            utils.error(errors)
            return -1
        end
    end

    -- remove config.h
    if info.config_h and os.isfile(info.config_h) then
        local ok, errors = os.rm(info.config_h) 
        if not ok then
            utils.error(errors)
            return -1
        end
    end

    -- remove headers
    if target.headers then
        for _, header in ipairs(target.headers) do
            if os.isfile(header) then
                local ok, errors = os.rm(header) 
                if not ok then
                    utils.error(errors)
                    return -1
                end
            end
        end
    end

    -- ok
    return 1
end

-- uninstall target for the binary file
function uninstall._done_binary(target)

    -- check
    assert(target and target.archs)

    -- get target info
    local info = target.archs[xmake._ARCH] or target.archs["x86_64"] or target.archs["i386"]
    if not info then return -1 end

    -- check
    assert(info.targetdir and info.targetfile)

    -- the target file
    local targetfile = info.targetdir .. "/" .. info.targetfile
    if not os.isfile(targetfile) then return 1 end
    
    -- remove the target file
    local ok, errors = os.rm(targetfile) 
    if not ok then
        utils.error(errors)
        return -1
    end

    -- ok
    return 1
end

-- uninstall target 
function uninstall.main(target)

    -- check
    assert(target and target.kind)

    -- the uninstall scripts
    local uninstallscripts = 
    {
        static = uninstall._done_library
    ,   shared = uninstall._done_library
    ,   binary = uninstall._done_binary
    }

    -- uninstall it
    local uninstallscript = uninstallscripts[target.kind]
    if uninstallscript then return uninstallscript(target) end

    -- continue
    return 0
end

-- return module: uninstall
return uninstall
