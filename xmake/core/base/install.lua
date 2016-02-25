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
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        install.lua
--

-- define module: install
local install = install or {}

-- load modules
local os        = require("base/os")
local io        = require("base/io")
local rule      = require("base/rule")
local path      = require("base/path")
local utils     = require("base/utils")
local config    = require("base/config")
local sandbox   = require("base/sandbox")
local platform  = require("base/platform")

-- install target from the project script
function install._done_from_project(target)

    -- check
    assert(target)

    -- no script? continue
    if target.installscript == nil then
        return 0
    end

    -- get script
    local script = target.installscript
    target.installscript = nil

    -- install it using the project script first
    local ok, results = sandbox.load(script, target)
    if not ok then 
        utils.error(results)
        return -1
    end

    -- ok?
    return results
end

-- install target from the platform script
function install._done_from_platform(target)

    -- check
    assert(target)

    -- no script? continue
    local scriptfile = path.join(platform.directory(), "install.lua")
    if not os.isfile(scriptfile) then
        return 0
    end

    -- the platform install script file
    local ok, results = sandbox.load(scriptfile, target)
    if not ok then 
        utils.error(results)
        return -1
    end

    -- ok?
    return results
end

-- install target from the given target configure
function install._done(target)

    -- check
    assert(target)

    -- install it from the project script
    local ok = install._done_from_project(target)
    if ok ~= 0 then return utils.ifelse(ok == 1, true, false) end

    -- install it from the platform script
    local ok = install._done_from_platform(target)
    if ok ~= 0 then return utils.ifelse(ok == 1, true, false) end

    -- ok
    return true
end

-- get the configure file
function install._file()
 
    -- get it
    return config.directory() .. "/install.conf"
end

-- done install from the configure
function install.done(configs)

    -- check
    assert(configs)

    -- install targets
    for _, target in pairs(configs) do

        -- install it
        if not install._done(target) then
            -- errors
            utils.error("install %s failed!", target.name)
            return false
        end

    end

    -- save to the configure file
    return io.save(install._file(), configs) 
end

-- load the install configure
function install.load()

    -- load it
    return io.load(install._file()) 
end

-- return module: install
return install
