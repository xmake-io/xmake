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
local io        = require("base/io")
local rule      = require("base/rule")
local path      = require("base/path")
local utils     = require("base/utils")
local config    = require("base/config")
local platform  = require("base/platform")

-- uninstall target from the platform script
function uninstall._done_from_platform(target)

    -- check
    assert(target)

    -- the platform uninstall script file
    local uninstallscript = nil
    local scriptfile = platform.directory() .. "/uninstall.lua"
    if os.isfile(scriptfile) then 

        -- load the uninstall script
        local script, errors = loadfile(scriptfile)
        if script then 
            uninstallscript = script()
            if type(uninstallscript) == "table" and uninstallscript.main then 
                uninstallscript = uninstallscript.main
            end
        else
            utils.error(errors)
        end
    end

    -- uninstall it
    if type(uninstallscript) == "function" then
        return uninstallscript(target)
    end

    -- continue
    return 0
end

-- uninstall target from the given target configure
function uninstall._done(target)

    -- check
    assert(target)

    -- uninstall it from the platform script
    local ok = uninstall._done_from_platform(target)
    if ok ~= 0 then return utils.ifelse(ok == 1, true, false) end

    -- ok
    return true
end

-- done uninstall from the configure
function uninstall.done(configs)

    -- check
    assert(configs)

    -- uninstall targets
    for _, target in pairs(configs) do

        -- uninstall it
        if not uninstall._done(target) then
            -- errors
            utils.error("uninstall %s failed!", target.name)
            return false
        end

    end

    -- ok
    return true
end

-- return module: uninstall
return uninstall
