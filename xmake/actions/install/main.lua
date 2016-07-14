--!The Make-like Build Utility based on Lua
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
import("core.platform.installer")

-- install target 
function _install_target(target)

    -- get kind
    local kind = target:get("kind")

    -- get script 
    local scripts =
    {
        binary = installer.install
    ,   static = installer.install
    ,   shared = installer.install
    }

    -- check
    assert(scripts[kind], "this target(%s) with kind(%s) can not be installd!", target:name(), kind)

    -- install it
    scripts[kind](target) 
end

-- install the given target 
function _install(target)

    -- enter project directory
    local olddir = os.cd(project.directory())

    -- the target scripts
    local scripts =
    {
        target:get("install_before")
    ,   target:get("install") or _install_target
    ,   target:get("install_after")
    }

    -- install the target scripts
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end

    -- leave project directory
    os.cd(olddir)
end

-- install the given target and deps
function _install_target_and_deps(target)

    -- this target have been finished?
    if _g.finished[target:name()] then
        return 
    end

    -- install for all dependent targets
    for _, depname in ipairs(target:get("deps")) do
        _install_target_and_deps(project.target(depname)) 
    end

    -- install target
    _install_target(target)

    -- finished
    _g.finished[target:name()] = true
end

-- main
function main()

    -- get the target name
    local targetname = option.get("target")

    -- init finished states
    _g.finished = {}

    -- build it first
    task.run("build", {target = targetname})

    -- install all?
    if targetname == "all" then
        for _, target in pairs(project.targets()) do
            _install_target_and_deps(target)
        end
    else
        _install_target_and_deps(project.target(targetname))
    end

    -- trace
    print("install ok!")
end
