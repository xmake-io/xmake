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
-- @file        _clean.lua
--

-- define module: _clean
local _clean = _clean or {}

-- load modules
local os        = require("base/os")
local utils     = require("base/utils")
local config    = require("base/config")
local project   = require("base/project")

-- remove the given target
function _clean._rm_target(buildir, target)

    -- check
    assert(buildir and target)
 
    -- the file 
    local file = string.format("%s/%s", buildir, target)
    if not os.exists(file) then
        return true
    end

    -- clean target
    local ok, errors = os.rm(file)
    if not ok then
        -- error
        utils.error(errors)
        return false
    end   

    -- ok
    return true
end

-- remove the given target and all dependent targets
function _clean._rm_target_and_deps(buildir, target)

    -- remove the target 
    if not _clean._rm_target(buildir, target) then
        return false 
    end
     
    -- the targets
    local targets = project.targets()
    assert(targets)

    -- exists the dependent targets?
    if targets[target] and targets[target].deps then
        local deps = utils.wrap(targets[target].deps)
        for _, dep in ipairs(deps) do
            if not _clean._rm_target_and_deps(buildir, dep) then return false end
        end
    end
end

-- done the given config
function _clean.done()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- the build directory
    local buildir = config.get("buildir")
    assert(buildir)

    -- the target
    local target = options.target
    if target and target ~= "all" then
        if not _clean._rm_target_and_deps(buildir, target) then return false end
    else
        -- the targets
        local targets = project.targets()
        assert(targets)

        -- clean targets
        for target, _ in pairs(targets) do
            if not _clean._rm_target(buildir, target) then return false end
        end
    end

    -- trace
    print("clean ok!")
 
    -- ok
    return true
end

-- return module: _clean
return _clean
