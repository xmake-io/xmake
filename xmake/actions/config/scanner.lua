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
    local sourcefiles_main = {}
    for _, sourcekind in ipairs(language.sourcekinds()) do

        -- load language instance
        local instance = language.load_from_kind(sourcekind)

        -- get check main() script
        local check_main = instance:get("check_main")

        -- scan source files
        for _, sourcefile in ipairs(os.files("*" .. sourcekind)) do
            if check_main and check_main(sourcefile) then
                table.insert(sourcefiles_main, sourcefile)
            else
                table.insert(sourcefiles, sourcefile)
            end
        end
    end
    sourcefiles         = table.unique(sourcefiles)
    sourcefiles_main    = table.unique(sourcefiles_main)

    -- remove config directory first
    os.rm(config.directory())
        
    -- project not found
    if #sourcefiles == 0 and #sourcefiles_main == 0 then

        -- error
        raise("project not found!")
    end

    -- generate xmake.lua
    local file = io.open("xmake.lua", "w")
    if file then

        -- get target name
        local targetname = path.basename(os.curdir())

        -- define static target
        if #sourcefiles > 0 then

            -- trace
            cprint("target(${magenta}%s${clear}): static", targetname)

            -- add target
            file:print("-- define target")
            file:print("target(\"%s\")", targetname)
            file:print("")
            file:print("    -- set kind")
            file:print("    set_kind(\"static\")")
            file:print("")
            file:print("    -- add files")
            for _, sourcefile in ipairs(sourcefiles) do

                -- trace
                cprint("    ${green}[+]: ${clear}%s", sourcefile)

                -- add file
                file:print("    add_files(\"%s\")", sourcefile)
            end
            file:print("")
        end

        -- define binary targets
        for _, sourcefile in ipairs(sourcefiles_main) do

            -- trace
            cprint("target(${magenta}%s${clear}): binary", path.basename(sourcefile))
            cprint("    ${green}[+]: ${clear}%s", sourcefile)

            -- add target
            file:print("-- define target")
            file:print("target(\"%s\")", path.basename(sourcefile))
            file:print("")
            file:print("    -- set kind")
            file:print("    set_kind(\"binary\")")
            file:print("")
            file:print("    -- add files")
            file:print("    add_files(\"%s\")", sourcefile)
            file:print("")
    
            -- add links
            if #sourcefiles > 0 then
                file:print("    -- add deps")
                file:print("    add_deps(\"%s\")", targetname)
                file:print("")
                file:print("    -- add links")
                file:print("    add_links(\"%s\")", targetname)
                file:print("    add_linkdirs(\"%$(buildir)\")")
                file:print("")
            end
        end
    
        -- exit file
        file:close()
    end

    -- trace
    cprint("${bright}xmake.lua generated, scan ok!${clear}${ok_hand}")
end
