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
import("core.project.project")
import("core.project.cache")
import("core.platform.platform")
import("core.tool.tool")
import("builder")

-- main
function main()

    -- get the target name
    local targetname = option.get("target")

    -- config it first
    task.run("config", {target = targetname})

    -- enter cache scope
    cache.enter("local.config")

    -- rebuild?
    if option.get("rebuild") or cache.get("rebuild") then
        
        -- clean it first
        task.run("clean", {target = targetname})

        -- reset state
        cache.set("rebuild", nil)
    end

    -- flush cache to file
    cache.flush()

    -- enter project directory
    local olddir = os.cd(project.directory())

    -- build it
    try
    {
        function ()

            -- build 
            builder.build(targetname or "all")
        
        end,

        catch 
        {
            function (errors)

                -- failed
                if errors then
                    raise(errors)
                else
                    raise("build target: %s failed!", targetname)
                end
            end
        }
    }

    -- leave project directory
    os.cd(olddir)

    -- trace
    cprint("${bright}build ok!")
end
