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
-- @file        build.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.platform.environment")

-- clean target for rebuilding
function _clean_target(target)
    if not target:isphony() then
        os.tryrm(target:symbolfile())
        os.tryrm(target:targetfile())
    end
end

-- do build the given target
function _do_build_target(target, opt)

    -- build target
    if not target:isphony() then
        import("kinds." .. target:targetkind()).build(target, opt)
    end
end

-- on build the given target
function _on_build_target(target, opt)

    -- build target with rules
    local done = false
    for _, r in ipairs(target:orderules()) do
        local on_build = r:script("build")
        if on_build then
            on_build(target, opt)
            done = true
        end
    end
    if done then return end

    -- do build
    _do_build_target(target, opt)
end

-- build the given target 
function _build_target(target)

    -- has been disabled?
    if target:get("enabled") == false then
        _g.targetindex = _g.targetindex + 1
        return 
    end

    -- enter the environments of the target packages
    local oldenvs = {}
    for name, values in pairs(target:pkgenvs()) do
        oldenvs[name] = os.getenv(name)
        os.addenv(name, unpack(values))
    end

    -- compute the progress range
    local progress = {}
    progress.start = (_g.targetindex * 100) / _g.targetcount
    progress.stop  = ((_g.targetindex + 1) * 100) / _g.targetcount

    -- the target scripts
    local scripts =
    {
        function (target)

            -- do before build for target
            local before_build = target:script("build_before")
            if before_build then
                before_build(target, {progress = progress})
            end

            -- do before build for rules
            for _, r in ipairs(target:orderules()) do
                local before_build = r:script("build_before")
                if before_build then
                    before_build(target, {progress = progress})
                end
            end
        end
    ,   function (target)

            -- do build
            local on_build = target:script("build", _on_build_target)
            if on_build then
                on_build(target, {origin = _do_build_target, progress = progress})
            end
        end
    ,   function (target)

            -- do after build for target
            local after_build = target:script("build_after")
            if after_build then
                after_build(target, {progress = progress})
            end

            -- do after build for rules
            for _, r in ipairs(target:orderules()) do
                local after_build = r:script("build_after")
                if after_build then
                    after_build(target, {progress = progress})
                end
            end
        end
    }

    -- clean target if rebuild
    if option.get("rebuild") then
        _clean_target(target)
    end
   
    -- run the target scripts
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end

    -- leave the environments of the target packages
    for name, values in pairs(oldenvs) do
        os.setenv(name, values)
    end

    -- update target index
    _g.targetindex = _g.targetindex + 1
end

-- build the given target and deps
function _build_target_and_deps(target)

    -- this target have been finished?
    if _g.finished[target:name()] then
        return 
    end

    -- make for all dependent targets
    for _, depname in ipairs(target:get("deps")) do
        _build_target_and_deps(project.target(depname)) 
    end

    -- make target
    _build_target(target)

    -- finished
    _g.finished[target:name()] = true
end

-- stats the given target and deps
function _stat_target_count_and_deps(target)

    -- this target have been finished?
    if _g.finished[target:name()] then
        return 
    end

    -- make for all dependent targets
    for _, depname in ipairs(target:get("deps")) do
        _stat_target_count_and_deps(project.target(depname))
    end

    -- update count
    _g.targetcount = _g.targetcount + 1

    -- finished
    _g.finished[target:name()] = true
end

-- stats targets count
function _stat_target_count(targetname)

    -- init finished states
    _g.finished = {}

    -- init targets count
    _g.targetcount = 0

    -- for the given target?
    if targetname then
        _stat_target_count_and_deps(project.target(targetname))
    else
        -- for default or all targets
        for _, target in pairs(project.targets()) do
            local default = target:get("default")
            if default == nil or default == true or option.get("all") then
                _stat_target_count_and_deps(target)
            end
        end
    end
end

-- the main entry
function main(targetname)

    -- enter toolchains environment
    environment.enter("toolchains")

    -- stat targets count
    _stat_target_count(targetname)

    -- clear finished states
    _g.finished = {}

    -- init target index
    _g.targetindex = 0

    -- build the given target?
    if targetname then
        _build_target_and_deps(project.target(targetname))
    else
        -- build default or all targets
        for _, target in pairs(project.targets()) do
            local default = target:get("default")
            if default == nil or default == true or option.get("all") then
                _build_target_and_deps(target)
            end
        end
    end

    -- leave toolchains environment
    environment.leave("toolchains")
end


