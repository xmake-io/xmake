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
-- @file        scanner.lua
--

-- imports
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- scan project and generate xmake.lua automaticlly if the project codes exist
function make()

    -- trace
    cprint("${yellow}xmake.lua not found, scanning files ..")

    -- scan source files for the current directory
    local sourcefiles = {}
    for _, sourcekind in ipairs(language.sourcekinds()) do
        for _, sourcefile in ipairs(os.files("*" .. sourcekind)) do
            table.insert(sourcefiles, sourcefile)
        end
    end
    sourcefiles = table.unique(sourcefiles)

    -- project not found
    if #sourcefiles == 0 then

        -- remove config directory if exists because the current directory is not a project
        os.rm(config.directory())
        
        -- error
        raise("project not found!")
    end

    -- generate xmake.lua
    local file = io.open("xmake.lua", "w")
    if file then

        -- save file
        file:print("-- define target")
        file:print("target(\"%s\")", "demo")
        file:print("")
        file:print("    -- set kind")
        file:print("    set_kind(\"binary\")")
        file:print("")
        file:print("    -- add files")
        for _, sourcefile in ipairs(sourcefiles) do
            cprint("${green}[+]: ${clear}%s", sourcefile)
            file:print("    add_files(\"%s\")", sourcefile)
        end
        file:print("")
    
        -- exit file
        file:close()
    end

    -- trace
    cprint("target: ${magenta}demo")
    cprint("${bright}xmake.lua generated, scan ok!${clear}${ok_hand}")
end
