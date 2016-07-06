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
import("configheader")

-- filter option 
function _option_filter(name)
    return name and name ~= "target" and name ~= "file" and name ~= "project" and name ~= "verbose"
end

-- host changed?
function _host_changed(targetname)
    return os.host() ~= config.read("host", targetname)
end

-- need check
function _need_check()

    -- clean?
    if option.get("clean") then
        return true
    end

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

-- check dependent target
function _check_target_deps(target)

    -- check 
    for _, depname in ipairs(target:get("deps")) do

        -- check dependent target name
        assert(depname ~= target:name(), "the target(%s) cannot depend self!", depname)

        -- get dependent target
        local deptarget = project.target(depname)

        -- check dependent target name
        assert(deptarget, "unknown target(%s) for %s.deps!", depname, target:name())

        -- check the dependent targets
        _check_target_deps(deptarget)
    end
end

-- check target
function _check_target(targetname)

    -- check
    assert(targetname)

    -- all?
    if targetname == "all" then

        -- check the dependent targets
        for _, target in pairs(project.targets()) do
            _check_target_deps(target)
        end
    else

        -- get target
        local target = project.target(targetname)

        -- check target name
        assert(target, "unknown target: %s", targetname)

        -- check the dependent targets
        _check_target_deps(target)
    end
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
    local targetname = option.get("target") or "all"

    -- load global configure
    global.load()

    -- init the project configure
    --
    -- priority: option > option_cache > global > option_default > config_check > project_check > config_cache
    --
    config.init()

    -- enter cache scope
    cache.enter("local.config")

    -- get the options
    local options = nil
    for name, value in pairs(option.options()) do
        if _option_filter(name) then
            options = options or {}
            options[name] = value
        end
    end

    -- override configure from the options or cache 
    if not option.get("clean") then
        options = options or cache.get("options_" .. targetname)
    end
    for name, value in pairs(options) do
        config.set(name, value)
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

    -- merge the checked configure 
    local recheck = _need_check()
    if recheck then

        -- check configure
        config.check()

        -- check project options
        project.check()

        -- rebuild it
        cache.set("rebuild", true)
    end

    -- merge the cached configure
    if not option.get("clean") and not _host_changed(targetname) then
        config.load(targetname)
    end

    -- load platform
    platform.load(config.plat())

    -- translate the build directory
    local buildir = config.get("buildir")
    if buildir and path.is_absolute(buildir) then
        config.set("buildir", path.relative(buildir, project.directory()))
    end

    -- load project
    project.load()

    -- check target
    _check_target(targetname)

    -- save options and configure for the given target
    config.save(targetname)
    cache.set("options_" .. targetname, options)

    -- save options and configure for each targets if be all
    if targetname == "all" then
        for _, target in pairs(project.targets()) do
            config.save(target:name())
            cache.set("options_" .. target:name(), options)
        end
    end

    -- flush cache
    cache.flush()

    -- make the config.h
    configheader.make()

    -- dump it
    config.dump()

    -- finished 
    _g.finished = true

    -- trace
    print("configure ok!")
end
