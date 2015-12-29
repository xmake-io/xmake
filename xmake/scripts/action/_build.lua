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
-- @file        _build.lua
--

-- define module: _build
local _build = _build or {}

-- load modules
local rule      = require("base/rule")
local utils     = require("base/utils")
local clean     = require("base/clean")
local config    = require("base/config")
local project   = require("base/project")
local makefile  = require("base/makefile")

-- need access to the given file?
function _build.need(name)

    -- check
    assert(name)

    -- the accessors
    local accessors = { config = true, global = true, project = true, platform = true }

    -- need it?
    return accessors[name]
end

-- done 
function _build.done()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- the target name
    local target_name = options.target

    -- check target
    if not project.checktarget(target_name) then
        return false
    end

    -- rebuild it?
    if options.rebuild or config.get("__rebuild") then
        clean.remove(target_name, "build")
    -- update it?
    elseif options.update then
        clean.remove(target_name, "targets")
    end

    -- clear rebuild mark and save configure to file
    if config.get("__rebuild") then

        -- clear it
        config.set("__rebuild", nil)

        -- save the configure
        if not config.save() then
            -- error
            utils.error("update configure failed!")
        end
    end

    -- check makefile
    if not os.isfile(rule.makefile()) then

        -- make the configure file for the given target
        if not project.makeconf(options.target) then
            -- error
            utils.error("make configure failed!")
            return false
        end

        -- make makefile
        if not makefile.make() then
            -- error
            utils.error("make makefile failed!")
            return false
        end
    end

    -- build target for makefile
    if not makefile.build(target_name) then
        -- error
        print("")
        if options.verbose then
            io.cat(rule.logfile())
        else
            io.tail(rule.logfile(), 32)
        end
        utils.error("build target: %s failed!\n", target_name)
        return false
    end

    -- ok
    print("build ok!")
    return true
end

-- return module: _build
return _build
