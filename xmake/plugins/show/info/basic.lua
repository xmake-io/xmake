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
-- @file        basic.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.project.project")
import("core.package.package")

-- show basic info
function main()

    -- get target
    config.load()

    -- show xmake information
    print("The information of xmake:")
    cprint("    ${color.dump.string}version${clear}: %s", xmake.version())
    cprint("    ${color.dump.string}host${clear}: %s/%s", os.host(), os.arch())
    cprint("    ${color.dump.string}programdir${clear}: %s", xmake.programdir())
    cprint("    ${color.dump.string}programfile${clear}: %s", xmake.programfile())
    cprint("    ${color.dump.string}globaldir${clear}: %s", global.directory())
    cprint("    ${color.dump.string}tmpdir${clear}: %s", os.tmpdir())
    cprint("    ${color.dump.string}workingdir${clear}: %s", os.workingdir())
    cprint("    ${color.dump.string}packagedir${clear}: %s", package.installdir())
    cprint("    ${color.dump.string}packagedir(cache)${clear}: %s", package.cachedir())
    print("")

    local projectfile = os.projectfile()
    if os.isfile(projectfile) then
        print("The information of project: %s", project.name() and project.name() or "")
        local version = project.version()
        if version then
            cprint("    ${color.dump.string}version${clear}: %s", version)
        end
        if config.plat() then
            cprint("    ${color.dump.string}plat${clear}: %s", config.plat())
        end
        if config.arch() then
            cprint("    ${color.dump.string}arch${clear}: %s", config.arch())
        end
        if config.mode() then
            cprint("    ${color.dump.string}mode${clear}: %s", config.mode())
        end
        if config.buildir() then
            cprint("    ${color.dump.string}buildir${clear}: %s", config.buildir())
        end
        cprint("    ${color.dump.string}configdir${clear}: %s", config.directory())
        cprint("    ${color.dump.string}projectdir${clear}: %s", os.projectdir())
        cprint("    ${color.dump.string}projectfile${clear}: %s", projectfile)
        print("")
    end
end
