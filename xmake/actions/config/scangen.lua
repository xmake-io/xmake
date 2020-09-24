--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        scangen.lua
--

-- imports
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- scan project and generate xmake.lua automaticlly if the project codes exist
function main()

    -- trace
    cprint("${color.warning}xmake.lua not found, scanning files ..")

    -- scan source files for the current directory
    local targetkinds = {}
    local sourcefiles = {}
    local sourcefiles_main = {}
    for extension, sourcekind in pairs(language.extensions()) do

        -- load language instance
        local instance = language.load_sk(sourcekind)

        -- get check main() script
        local check_main = instance:get("check_main")

        -- scan source files
        local filecount = 0
        for _, sourcefile in ipairs(os.files("*" .. extension)) do
            if check_main and check_main(sourcefile) then
                table.insert(sourcefiles_main, sourcefile)
            else
                table.insert(sourcefiles, sourcefile)
            end
            filecount = filecount + 1
        end

        -- add targetkinds
        if filecount > 0 then
            for targetkind, _ in pairs(instance:targetkinds()) do
                targetkinds[targetkind] = true
            end
        end
    end
    sourcefiles         = table.unique(sourcefiles)
    sourcefiles_main    = table.unique(sourcefiles_main)

    -- project not found
    if #sourcefiles == 0 and #sourcefiles_main == 0 then
        raise("project not found!")
    end

    -- generate xmake.lua
    local file = io.open("xmake.lua", "w")
    if file then

        -- get target name
        local targetname = path.basename(os.curdir())

        -- define static/binary target
        if #sourcefiles > 0 then

            -- get targetkind
            local targetkind = nil
            if targetkinds["static"] then
                targetkind = "static"
            elseif targetkinds["binary"] then
                targetkind = "binary"
            end
            assert(targetkind, "unknown target kind!")

            -- trace
            cprint("target(${magenta}%s${clear}): %s", targetname, targetkind)

            -- add rules
            file:print("-- add rules: debug/release")
            file:print("add_rules(\"mode.debug\", \"mode.release\")")
            file:print("")

            -- add target
            file:print("-- define target")
            file:print("target(\"%s\")", targetname)
            file:print("")
            file:print("    -- set kind")
            file:print("    set_kind(\"%s\")", targetkind)
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
            local name = path.basename(sourcefile)
            if name == targetname then
                name = name .. "1"
            end
            cprint("target(${magenta}%s${clear}): binary", name)
            cprint("    ${green}[+]: ${clear}%s", sourcefile)

            -- add target
            file:print("-- define target")
            file:print("target(\"%s\")", name)
            file:print("")
            file:print("    -- set kind")
            file:print("    set_kind(\"binary\")")
            file:print("")
            file:print("    -- add files")
            file:print("    add_files(\"%s\")", sourcefile)
            file:print("")

            -- add deps
            if #sourcefiles > 0 then
                file:print("    -- add deps")
                file:print("    add_deps(\"%s\")", targetname)
                file:print("")
            end
        end

        -- add FAQ
        file:print(io.readfile(path.join(os.programdir(), "scripts", "faq.lua")))

        -- exit file
        file:close()
    end

    -- generate .gitignore if not exists
    if not os.isfile(".gitignore") then
        os.cp("$(programdir)/scripts/gitignore", ".gitignore")
    end

    -- trace
    cprint("${color.success}xmake.lua generated, scan ok!")
end
