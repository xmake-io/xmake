--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.base.global")
import("core.project.project")
import("core.platform.platform")
import("core.project.cache", {nocache = true})
import("lib.detect.cache", {alias = "detectcache"})
import("scanner")
import("configheader")

-- filter option 
function _option_filter(name)
    local options = 
    {
        target      = true
    ,   file        = true
    ,   root        = true
    ,   quiet       = true
    ,   profile     = true
    ,   project     = true
    ,   verbose     = true
    ,   backtrace   = true
    }
    return not options[name]
end

-- host changed?
function _host_changed(targetname)
    return os.host() ~= config.read("host", targetname)
end

-- need check
function _need_check()

    -- clean?
    local changed = option.get("clean")

    -- the configure has been changed? reconfig it
    if not changed and config.changed() then
        changed = true
    end

    -- get the current mtimes 
    local mtimes = project.mtimes()

    -- get the previous mtimes 
    if not changed then
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

    -- scan project and generate it if xmake.lua not exists
    if not os.isfile(project.file()) then

        -- need some tips?
        local autogen = true
        if not option.get("quiet") then

            -- show tips
            cprint("${bright yellow}note: ${default yellow}xmake.lua not found, try generating it?")
            cprint("please input: n (y/n)")

            -- get answer
            io.flush()
            if io.read() ~= 'y' then
                autogen = false
            end
        end

        -- do not generate it
        if not autogen then
            os.exit() 
        end

        -- scan and generate it automatically
        scanner.make()
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

        -- clear detect cache
        detectcache.clear()
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
    if recheck then
        configheader.make()
    end

    -- dump config
    if option.get("verbose") then
        config.dump()
    end

    -- finished 
    _g.finished = true
end
