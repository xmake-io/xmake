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
            os.rm(filedir)

        -- remove "*.o/obj" files?
        elseif filedir:find("%*") then

            -- match all files
            for _, file in ipairs(os.match(filedir)) do

                -- remove it
                os.rm(file)

            end
        end
    end
end

-- clean the given target files
function _clean_target(target)

    -- remove the target file 
    _remove(target:targetfile()) 

    -- remove the object files 
    _remove(target:objectfiles())

    -- remove the header files 
    local _, dstheaders = target:headerfiles()
    _remove(dstheaders) 

    -- remove all?
    if option.get("all") then 

        -- remove the config.h file
        _remove(target:get("config_h")) 
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

        -- remove makefile
        _remove("$(buildir)/makefile") 

        -- remove the configure directory
        _remove(config.directory())

        -- remove the log file
        _remove("$(buildir)/.build.log")

        -- remove build directory if be empty
        os.rm("$(buildir)", true)
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

    -- load global configure
    global.load()

    -- load project configure
    config.load(targetname)

    -- load platform
    platform.load(config.plat())

    -- load project
    project.load()

    -- check target
    if targetname and targetname ~= "all" and nil == project.target(targetname) then
        raise("unknown target: %s", targetname)
    end

    -- enter project directory
    os.cd(project.directory())

    -- clean the current target
    _clean(targetname) 

    -- leave project directory
    os.cd("-")

    -- trace
    print("clean ok!")
    
end
