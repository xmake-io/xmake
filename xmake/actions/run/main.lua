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

-- run binary target
function _run_binary(target)

    -- run it
    os.execute("%s %s", target:targetfile(), table.concat(option.get("arguments") or {}, " "))
end

-- run target 
function _run_target(target)

    -- get kind
    local kind = target:get("kind")

    -- get script 
    local scripts =
    {
        binary = _run_binary
    }

    -- check
    assert(scripts[kind], "this target(%s) with kind(%s) can not be executed!", target:name(), kind)

    -- run it
    scripts[kind](target) 
end

-- run the given target 
function _run(target)

    -- the target scripts
    local scripts =
    {
        target:get("run_before")
    ,   target:get("run") or _run_target
    ,   target:get("run_after")
    }

    -- run the target scripts
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end
end

-- main
function main()

    -- get the target name
    local targetname = option.get("target")

    -- build it first
    task.run("build", {target = targetname})

    -- enter project directory
    local olddir = os.cd(project.directory())

    -- run the current target
    _run(project.target(targetname)) 

    -- leave project directory
    os.cd(olddir)
end
