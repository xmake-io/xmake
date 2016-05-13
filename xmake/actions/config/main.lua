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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.global")
import("core.project.project")
import("core.platform.platform")
import("core.project.cache")
import("config_h")

-- filter option 
function _option_filter(name)
    return name and name ~= "target" and name ~= "file" and name ~= "project" and name ~= "verbose" and name ~= "clean"
end

-- need check
function _need_check()

    -- the configure has been changed? reconfig it
    if config.changed() then
        return true
    end

    -- get the current mtimes 
    local mtimes = project.mtimes()

    -- get the previous mtimes 
    local changed = false
    local mtimes_prev = cache.get("mtimes")
    if mtimes_prev then 

        -- check for all project files
        for file, mtime in pairs(mtimes) do

            -- modified? reconfig and rebuild it
            local mtime_prev = mtimes_prev[file]
            if not mtime_prev or mtime > mtime_prev then
                changed = true
                break
            end
        end
    end

    -- update mtimes
    cache.set("mtimes", mtimes)

    -- changed?
    return changed
end

-- main
function main()

    -- avoid to run this task repeatly
    if _g.finished then
        return 
    end

    -- check xmake.lua
    if not os.isfile(project.file()) then
        raise("xmake.lua not found!")
    end

    -- the target name
    local targetname = option.get("target")

    -- load global configure
    global.load()

    -- init the project configure
    --
    -- priority: option > global > option_default > config_check > project_check > config_cache
    --
    config.init()

    -- override the option configure
    for name, value in pairs(option.options()) do
        if _option_filter(name) then
            config.set(name, value)
        end
    end

    -- merge the global configure 
    for name, value in pairs(global.options()) do 
        if config.get(name) == nil then
            config.set(name, value)
        end
    end

    -- merge the default options 
    for name, value in pairs(option.defaults()) do
        if _option_filter(name) and config.get(name) == nil then
            config.set(name, value)
        end
    end

    -- enter cache scope
    cache.enter("local.config")

    -- merge the checked configure 
    if _need_check() then
        config.check()
        project.check()
    end

    -- merge the cached configure
    if not option.get("clean") then
        config.load(targetname)
    end

    -- load platform
    platform.load(config.plat())

    -- translate the build directory
    local buildir = option.get("buildir")
    if buildir and path.is_absolute(buildir) then
        config.set("buildir", path.relative(buildir, project.directory()))
    end

    -- load project
    project.load()

    -- check xmake.lua
    if not os.isfile(project.file()) then
        raise("xmake.lua not found!")
    end

    -- check target
    if targetname and targetname ~= "all" and nil == project.target(targetname) then
        raise("unknown target: %s", targetname)
    end

    -- need rebuild it
    cache.set("rebuild", true)
    cache.flush()

    -- save the project configure
    config.save(targetname)

    -- make the config.h
    config_h.make()

    -- dump it
    config.dump()

    -- finished 
    _g.finished = true

    -- trace
    print("configure ok!")
    
end
