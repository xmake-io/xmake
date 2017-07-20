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
-- @file        builder.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.platform.environment")

-- on build the given target
function _on_build_target(target)

    -- build target
    if not target:isphony() then
        import("kinds." .. target:targetkind()).build(target, _g)
    end
end

-- build the given target 
function _build_target(target)

    -- the target scripts
    local scripts =
    {
        target:script("build_before")
    ,   target:script("build", _on_build_target)
    ,   target:script("build_after")
    }

    -- run the target scripts
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
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

-- build
function build(targetname, rebuild)

    -- enter toolchains environment
    environment.enter("toolchains")

    -- stat targets count
    _stat_target_count(targetname)

    -- mark as rebuild
    _g.rebuild = rebuild

    -- clear finished states
    _g.finished = {}

    -- clear modified states
    _g.modified = {}

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

