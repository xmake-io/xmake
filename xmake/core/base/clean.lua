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

    -- empty?
    if not filedirs then return true end

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
        -- remove "*.o/obj" files?
        elseif filedir:find("%*") then
            -- match all files
            local files = os.match(filedir)
            if files then
                for _, file in ipairs(files) do
                    -- remove it
                    local ok, errors = os.rm(file)
                    if not ok then
                        -- error
                        utils.error(errors)
                        return false
                    end  
                end
            end
        end
    end

    -- ok
    return true
end

-- remove the given target name
function clean._remove_target(target_name, target, mode, buildir)

    -- check
    assert(target_name and target)
 
    -- remove the target file 
    if not clean._remove(rule.targetfile(target_name, target, buildir)) then
        return false
    end
 
    -- not only remove target file?
    if mode ~= "targets" then

        -- remove the object files 
        if not clean._remove(rule.objectfiles(target_name, target, rule.sourcefiles(target), buildir)) then
            return false
        end

        -- remove the header files 
        local _, dstheaders = rule.headerfiles(target)
        if not clean._remove(dstheaders) then
            return false
        end

        -- remove the config.h file
        if mode == "all" and target.config_h then 

            -- translate file path
            local config_h = nil
            if not path.is_absolute(target.config_h) then
                config_h = path.absolute(target.config_h, xmake._PROJECT_DIR)
            else
                config_h = path.translate(target.config_h)
            end
            if not clean._remove(config_h) then
                return false
            end
        end
    end

    -- ok
    return true
end

-- remove the given target and all dependent targets
function clean._remove_target_and_deps(target_name, mode, buildir)

    -- the targets
    local targets = project.targets()
    assert(targets)

    -- the target
    local target = targets[target_name]
    assert(target)

    -- remove the target
    if not clean._remove_target(target_name, target, mode, buildir) then
        return false 
    end
     
    -- exists the dependent targets?
    if target.deps then
        local deps = utils.wrap(target.deps)
        for _, dep in ipairs(deps) do
            if not clean._remove_target_and_deps(dep, mode, buildir) then return false end
        end
    end

    -- ok
    return true
end

-- remove the target and object files for the given target
--
-- mode: 
--  all
--  build
--  targets
--
function clean.remove(target_name, mode)

    -- the build directory
    local buildir = config.get("buildir")
    assert(buildir and mode)

    -- the target name
    if target_name and target_name ~= "all" then
        -- remove target
        if not clean._remove_target_and_deps(target_name, mode, buildir) then return false end
    else

        -- the targets
        local targets = project.targets()
        assert(targets)

        -- remove targets
        for target_name, target in pairs(targets) do
            if not clean._remove_target(target_name, target, mode, buildir) then return false end
        end
    end

    -- remove all
    if mode == "all" then 

        -- remove makefile
        if not clean._remove(rule.makefile()) then
            return false
        end

        -- remove the configure directory
        if not clean._remove(config.directory()) then
            return false
        end

        -- remove the log file
        if not clean._remove(rule.logfile()) then
            return false
        end

        -- remove build directory if be empty
        local buildir = config.get("buildir")
        if os.isdir(buildir) then
            os.rm(buildir, true)
        end

    end
 
    -- ok
    return true
end

-- return module: clean
return clean
