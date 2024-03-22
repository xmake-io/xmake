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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- update compile_commandss.json automatically
--
-- @code
-- add_rules("plugin.compile_commands.autoupdate", {outputdir = ".vscode", lsp = "clangd"})
-- target("test")
--     set_kind("binary")
--     add_files("src/*.c")
-- @endcode
--
rule("plugin.compile_commands.autoupdate")
    set_kind("project")
    after_build(function (opt)

        -- imports
        import("core.project.config")
        import("core.project.depend")
        import("core.project.project")
        import("core.base.task")

        -- we should not update it if we are installing xmake package
        if os.getenv("XMAKE_IN_XREPO") then
            return
        end

        -- run only once for all xmake process
        local tmpfile = path.join(config.buildir(), ".gens", "rules", "plugin.compile_commands.autoupdate")
        local dependfile = tmpfile .. ".d"
        local lockfile = io.openlock(tmpfile .. ".lock")
        if lockfile:trylock() then
            local outputdir
            local lsp
            local sourcefiles = {}
            for _, target in pairs(project.targets()) do
                table.join2(sourcefiles, target:sourcefiles(), (target:headerfiles()))
                local extraconf = target:extraconf("rules", "plugin.compile_commands.autoupdate")
                if extraconf then
                    outputdir = extraconf.outputdir
                    lsp = extraconf.lsp
                end
            end
            table.sort(sourcefiles)
            depend.on_changed(function ()
                -- we use task instead of os.exec("xmake") to avoid the project lock
                local filename = "compile_commands.json"
                local filepath = outputdir and path.join(outputdir, filename) or filename
                task.run("project", {kind = "compile_commands", outputdir = outputdir, lsp = lsp})
                print("compile_commands.json updated!")
            end, {dependfile = dependfile,
                  files = table.join(project.allfiles(), config.filepath()),
                  values = sourcefiles})
            lockfile:close()
        end
    end)
