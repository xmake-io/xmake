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
-- @file        target.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- show target info
function main(name)

    -- get target
    config.load()
    local target = assert(project.target(name), "target(%s) not found!", name)

    -- show target information
    print("The information of target(%s):", name)
    cprint("    ${color.dump.string}kind${clear}: %s", target:targetkind())
    cprint("    ${color.dump.string}targetfile${clear}: %s", target:targetfile())
    local deps = target:get("deps")
    if deps then
        cprint("    ${color.dump.string}deps${clear}: %s", table.concat(table.wrap(deps), ", "))
    end
    local rules = target:get("rules")
    if rules then
        cprint("    ${color.dump.string}rules${clear}: %s", table.concat(table.wrap(rules), ", "))
    end
    local options = {}
    for _, opt in ipairs(target:get("options")) do
        if not opt:startswith("__") then
            table.insert(options, opt)
        end
    end
    if #options > 0 then
        cprint("    ${color.dump.string}options${clear}: %s", table.concat(options, ", "))
    end
    local packages = target:get("packages")
    if packages then
        cprint("    ${color.dump.string}packages${clear}: %s", table.concat(table.wrap(packages), ", "))
    end
    for _, apiname in ipairs(table.join(language.apis().values, language.apis().paths)) do
        if apiname:startswith("target.") then
            local valuename = apiname:split('.add_', {plain = true})[2]
            if valuename then
                local values = target:get(valuename)
                if values then
                    cprint("    ${color.dump.string}%s${clear}: %s", valuename, table.concat(table.wrap(values), ", "))
                end
            end
        end
    end
    cprint("    ${color.dump.string}at${clear}: %s", path.join(target:scriptdir(), "xmake.lua"))
    for _, sourcebatch in pairs(target:sourcebatches()) do
        cprint("    ${color.dump.string}sourcebatch${clear}(%s): with rule(%s)", sourcebatch.sourcekind, sourcebatch.rulename)
        for idx, sourcefile in ipairs(sourcebatch.sourcefiles) do
            cprint("      -> %s", sourcefile)
            cprint("         ${dim}-> %s", sourcebatch.objectfiles[idx])
            cprint("         ${dim}-> %s", sourcebatch.dependfiles[idx])
        end
    end
end
