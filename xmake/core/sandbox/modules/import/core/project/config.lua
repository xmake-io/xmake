--!The Make-like Build Utility based on Lua
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
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        config.lua
--

-- define module
local sandbox_core_project_config = sandbox_core_project_config or {}

-- load modules
local config    = require("project/config")
local checker   = require("platform/checker")
local platform  = require("platform/platform")
local raise     = require("sandbox/modules/raise")

-- get the build directory
function sandbox_core_project_config.buildir()

    -- get it 
    return config.get("buildir")
end

-- get the current platform
function sandbox_core_project_config.plat()

    -- get it 
    return config.get("plat")
end

-- get the current architecture
function sandbox_core_project_config.arch()

    -- get it 
    return config.get("arch")
end

-- get the current mode
function sandbox_core_project_config.mode()

    -- get it 
    return config.get("mode")
end

-- get the current host
function sandbox_core_project_config.host()

    -- get it 
    return config.get("host")
end

-- get the configure directory
function sandbox_core_project_config.directory()

    -- get it
    local dir = config.directory()
    assert(dir)

    -- ok?
    return dir
end

-- get the given configure from the current 
function sandbox_core_project_config.get(name)

    -- get it
    return config.get(name)
end

-- set the given configure to the current 
function sandbox_core_project_config.set(name, value)

    -- set it
    return config.set(name, value)
end

-- load the configure
function sandbox_core_project_config.load(targetname)

    -- load it
    local ok, errors = config.load(targetname)
    if not ok then
        raise(errors)
    end
end

-- save the configure
function sandbox_core_project_config.save(targetname)

    -- save it
    local ok, errors = config.save(targetname)
    if not ok then
        raise(errors)
    end
end

-- read the value from the configure file directly
function sandbox_core_project_config.read(name, targetname)

    -- read it
    return config.read(name, targetname)
end

-- the configure has been changed for the given target?
function sandbox_core_project_config.changed(targetname)

    -- changed?
    return config.changed(targetname)
end

-- init the configure
function sandbox_core_project_config.init()

    -- init it
    config.init()
end

-- check the configure
function sandbox_core_project_config.check()

    -- check it
    local ok, errors = checker.check("config")
    if not ok then
        raise(errors)
    end

end

-- dump the configure
function sandbox_core_project_config.dump()

    -- dump it
    config.dump()
end


-- return module
return sandbox_core_project_config
