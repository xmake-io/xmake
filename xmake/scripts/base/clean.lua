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
-- @file        clean.lua
--

-- define module: clean
local clean = clean or {}

-- load modules
local os        = require("base/os")
local rule      = require("base/rule")
local utils     = require("base/utils")
local config    = require("base/config")
local project   = require("base/project")

-- remove the given files or directories
function clean._remove(filedirs)

    -- check
    assert(filedirs)

    -- wrap it first
    filedirs = utils.wrap(filedirs)
    for _, filedir in ipairs(filedirs) do
 
        -- exists? remove it
        if os.exists(filedir) then
            -- remove it
            local ok, errors = os.rm(filedir)
            if not ok then
                -- error
                utils.error(errors)
                return false
            end  
        end
    end

    -- ok
    return true
end

-- remove the given target_name
function clean._remove_target(target_name, target, target_only, buildir)

    -- check
    assert(target_name and target)
 
    -- remove the target file 
    if not clean._remove(rule.targetfile(target_name, target, buildir)) then
        return false
    end
 
    -- not only remove target file?
    if not target_only then
        -- remove the object files 
        if not clean._remove(rule.objectfiles(target_name, target, rule.sourcefiles(target), buildir)) then
            return false
        end
    end

    -- ok
    return true
end

-- remove the given target and all dependent targets
function clean._remove_target_and_deps(target_name, target_only, buildir)

    -- the targets
    local targets = project.targets()
    assert(targets)

    -- the target
    local target = targets[target_name]
    assert(target)

    -- remove the target
    if not clean._remove_target(target_name, target, target_only, buildir) then
        return false 
    end
     
    -- exists the dependent targets?
    if target.deps then
        local deps = utils.wrap(target.deps)
        for _, dep in ipairs(deps) do
            if not clean._remove_target_and_deps(dep, target_only, buildir) then return false end
        end
    end

    -- ok
    return true
end

-- remove the target and object files for the given target
function clean.remove(target_name, target_only)

    -- the build directory
    local buildir = config.get("buildir")
    assert(buildir)

    -- the target name
    if target_name and target_name ~= "all" then
        -- remove target
        if not clean._remove_target_and_deps(target_name, target_only, buildir) then return false end
    else

        -- the targets
        local targets = project.targets()
        assert(targets)

        -- remove targets
        for target_name, target in pairs(targets) do
            if not clean._remove_target(target_name, target, target_only, buildir) then return false end
        end
    end
 
    -- ok
    return true
end

-- return module: clean
return clean
