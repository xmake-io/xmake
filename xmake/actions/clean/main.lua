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

-- remove the given files or directories
function _remove(filedirs)

    -- done
    for _, filedir in ipairs(filedirs) do
 
        -- exists? remove it
        if os.exists(filedir) then

            -- remove it
            os.rm(filedir, true)

        -- remove "*.o/obj" files?
        elseif filedir:find("%*") then

            -- match all files
            for _, file in ipairs(os.match(filedir)) do

                -- remove it
                os.rm(file, true)
            end
        end
    end
end

-- on clean target 
function _on_clean_target(target)

    -- remove the target file 
    _remove(target:targetfile()) 

    -- remove the target arguments file if exists
    _remove(target:targetfile() .. ".arg") 

    -- remove the object files 
    _remove(target:objectfiles())

    -- remove the header files 
    local _, dstheaders = target:headerfiles()
    _remove(dstheaders) 

    -- remove all?
    if option.get("all") then 

        -- remove the config.h file
        _remove(target:configheader()) 
    end
end

-- clean the given target files
function _clean_target(target)

    -- the target scripts
    local scripts =
    {
        target:get("clean_before")
    ,   target:get("clean") or _on_clean_target
    ,   target:get("clean_after")
    }

    -- run the target scripts
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end
end

-- clean the given target and all dependent targets
function _clean_target_and_deps(target)

    -- remove the target
    _clean_target(target) 
     
    -- exists the dependent targets?
    for _, dep in ipairs(target:get("deps")) do
        _clean_target_and_deps(project.target(dep))
    end
end

-- clean the given target 
function _clean(targetname)

    -- the target name
    if targetname and targetname ~= "all" then

        -- clean target
        _clean_target_and_deps(project.target(targetname)) 

    else

        -- clean targets
        for _, target in pairs(project.targets()) do
            _clean_target(target) 
        end
    end

    -- remove all
    if option.get("all") then 

        -- remove the configure directory
        _remove(config.directory())
    end
end

-- main
function main()

    -- check xmake.lua
    if not os.isfile(project.file()) then
        raise("xmake.lua not found!")
    end

    -- get the target name
    local targetname = option.get("target")

    -- config it first
    task.run("config", {target = targetname})

    -- enter project directory
    local olddir = os.cd(project.directory())

    -- clean the current target
    _clean(targetname) 

    -- leave project directory
    os.cd(olddir)

    -- trace
    print("clean ok!")
    
end
