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
local makefile  = require("base/makefile")

-- done the given config
function _build.done()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- the target name
    local target_name = options.target

    -- rebuild it?
    if options.rebuild or config.get("__rebuild") then
        clean.remove(target_name)
    -- update it?
    elseif options.update then
        clean.remove(target_name, true)
    end

    -- build target for makefile
    if not makefile.build(target_name) then
        -- error
        print("")
        io.cat(rule.logfile())
        utils.error("build target: %s failed!\n", target_name)
        return false
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

    -- ok
    print("build ok!")
    return true
end

-- return module: _build
return _build
