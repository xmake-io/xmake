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
import("core.project.task")
import("core.project.config")
import("core.project.global")
import("core.project.project")
import("core.platform.platform")

-- uninstall package 
function _uninstall_package(target)

    -- remove the package 
    os.rm(format("$(packagedir)/%s.pkg", target:name()))
end

-- uninstall target 
function _uninstall_target(target)

    -- get kind
    local kind = target:get("kind")

    -- get script 
    local scripts =
    {
        binary = _uninstall_package
    ,   static = _uninstall_package
    ,   shared = _uninstall_package
    }

    -- check
    assert(scripts[kind], "this target(%s) with kind(%s) can not be uninstalld!", target:name(), kind)

    -- uninstall it
    scripts[kind](target) 
end

-- uninstall the given target 
function _uninstall(target)

    -- enter project directory
    os.cd(project.directory())

    -- the target scripts
    local scripts =
    {
        target:get("uninstall_before")
    ,   target:get("uninstall") or _uninstall_target
    ,   target:get("uninstall_after")
    }

    -- uninstall the target scripts
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end

    -- leave project directory
    os.cd("-")
end

-- uninstall the given target and deps
function _uninstall_target_and_deps(target)

    -- this target have been finished?
    if _g.finished[target:name()] then
        return 
    end

    -- uninstall for all dependent targets
    for _, depname in ipairs(target:get("deps")) do
        _uninstall_target_and_deps(project.target(depname)) 
    end

    -- uninstall target
    _uninstall_target(target)

    -- finished
    _g.finished[target:name()] = true
end

-- main
function main()

    -- get the target name
    local targetname = option.get("target")

    -- init finished states
    _g.finished = {}

    -- config it first
    task.run("config", {target = targetname})

    -- uninstall all?
    if targetname == "all" then
        for _, target in pairs(project.targets()) do
            _uninstall_target_and_deps(target)
        end
    else
        _uninstall_target_and_deps(project.target(targetname))
    end

    -- trace
    print("uninstall ok!")
end
