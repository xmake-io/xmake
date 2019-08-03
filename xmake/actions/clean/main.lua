--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("core.project.rule")
import("core.project.config")
import("core.base.global")
import("core.project.project")
import("core.platform.platform")
import("private.action.clean.remove_files")

-- do clean target 
function _do_clean_target(target)

    -- is phony?
    if target:isphony() then
        return 
    end

    -- remove the target file 
    remove_files(target:targetfile()) 

    -- remove the symbol file 
    remove_files(target:symbolfile()) 

    -- remove the c/c++ precompiled header file 
    remove_files(target:pcoutputfile("c")) 
    remove_files(target:pcoutputfile("cxx")) 

    -- TODO remove the header files (deprecated)
    local _, dstheaders = target:headers()
    remove_files(dstheaders) 

    -- remove the clean files
    remove_files(target:get("cleanfiles"))

    -- remove all?
    if option.get("all") then 

        -- TODO remove the config.h file (deprecated)
        remove_files(target:configheader()) 

        -- remove all dependent files for each platform
        remove_files(target:dependir({root = true}))

        -- remove all object files for each platform
        remove_files(target:objectdir({root = true}))

        -- remove all autogen files for each platform
        remove_files(target:autogendir({root = true}))
    else

        -- remove dependent files for the current platform
        remove_files(target:dependir())

        -- remove object files for the current platform
        remove_files(target:objectdir())

        -- remove autogen files for the current platform
        remove_files(target:autogendir())
    end
end

-- on clean target 
function _on_clean_target(target)

    -- has been disabled?
    if target:get("enabled") == false then
        return 
    end

    -- build target with rules
    local done = false
    for _, r in ipairs(target:orderules()) do
        local on_clean = r:script("clean")
        if on_clean then
            on_clean(target, {origin = _do_clean_target})
            done = true
        end
    end
    if done then return end

    -- do clean
    _do_clean_target(target)
end

-- clean the given target files
function _clean_target(target)

    -- enter the environments of the target packages
    local oldenvs = {}
    for name, values in pairs(target:pkgenvs()) do
        oldenvs[name] = os.getenv(name)
        os.addenv(name, unpack(values))
    end

    -- the target scripts
    local scripts =
    {
        target:script("clean_before")
    ,   function (target)

            -- has been disabled?
            if target:get("enabled") == false then
                return 
            end

            -- clean rules
            for _, r in ipairs(target:orderules()) do
                local before_clean = r:script("clean_before")
                if before_clean then
                    before_clean(target)
                end
            end
        end
    ,   target:script("clean", _on_clean_target)
    ,   function (target)

            -- has been disabled?
            if target:get("enabled") == false then
                return 
            end

            -- clean rules
            for _, r in ipairs(target:orderules()) do
                local after_clean = r:script("clean_after")
                if after_clean then
                    after_clean(target)
                end
            end
        end
    ,   target:script("clean_after")
    }

    -- run the target scripts
    for i = 1, 5 do
        local script = scripts[i]
        if script ~= nil then
            script(target, {origin = (i == 3 and _do_clean_target or nil)})
        end
    end

    -- leave the environments of the target packages
    for name, values in pairs(oldenvs) do
        os.setenv(name, values)
    end
end

-- clean the given target and all dependent targets
function _clean_target_and_deps(target)

    -- this target have been finished?
    if _g.finished[target:name()] then
        return 
    end

    -- remove the target
    _clean_target(target) 
     
    -- exists the dependent targets?
    for _, dep in ipairs(target:get("deps")) do
        _clean_target_and_deps(project.target(dep))
    end

    -- finished
    _g.finished[target:name()] = true
end

-- clean target 
function _clean(targetname)

    -- clean the given target
    if targetname then
        _clean_target_and_deps(project.target(targetname)) 
    else
        -- clean all targets
        for _, target in pairs(project.targets()) do
            _clean_target_and_deps(target) 
        end
    end

    -- remove all
    if option.get("all") then 

        -- remove the configure directory
        remove_files(config.directory())
    end
end

-- main
function main()

    -- lock the whole project
    project.lock()

    -- get the target name
    local targetname = option.get("target")

    -- config it first
    task.run("config", {target = targetname, require = false})

    -- init finished states
    _g.finished = {}

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- clean the current target
    _clean(targetname) 

    -- unlock the whole project
    project.unlock()

    -- leave project directory
    os.cd(oldir)
end
