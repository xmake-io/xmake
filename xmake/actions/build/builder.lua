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
-- @file        builder.lua
--

-- imports
import("core.project.project")
import("core.platform.environment")

-- on build the given target
function _on_build_target(target)

    -- the target kind
    local kind = target:get("kind") 
    assert(kind, "target(%s).kind not found!", target:name())

    -- build target
    import("kinds." .. kind).build(target, _g)
end

-- build the given target 
function _build_target(target)

    -- the target scripts
    local scripts =
    {
        target:get("build_before")
    ,   target:get("build") or _on_build_target
    ,   target:get("build_after")
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

    -- for all?
    if targetname == "all" then

        -- make all targets
        for _, target in pairs(project.targets()) do
            _stat_target_count_and_deps(target)
        end
    else

        -- make target
        _stat_target_count_and_deps(project.target(targetname))
    end
end

-- build
function build(targetname)

    -- enter toolchains environment
    environment.enter("toolchains")

    -- stat targets count
    _stat_target_count(targetname)

    -- clear finished states
    _g.finished = {}

    -- init target index
    _g.targetindex = 0

    -- for all?
    if targetname == "all" then

        -- make all targets
        for _, target in pairs(project.targets()) do
            _build_target_and_deps(target)
        end
    else

        -- make target
        _build_target_and_deps(project.target(targetname))
    end

    -- leave toolchains environment
    environment.leave("toolchains")
end

