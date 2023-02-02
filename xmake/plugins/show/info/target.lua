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
-- @file        target.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- show target information
function _show_target(target)
    print("The information of target(%s):", target:name())
    cprint("    ${color.dump.string}at${clear}: %s", path.join(target:scriptdir(), "xmake.lua"))
    cprint("    ${color.dump.string}kind${clear}: %s", target:kind())
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
                local values_from_deps = target:get_from_deps(valuename)
                local values_from_opts = target:get_from_opts(valuename)
                local values_from_pkgs = target:get_from_pkgs(valuename)
                values = table.join(values or {}, values_from_deps or {}, values_from_opts or {}, values_from_pkgs or {})
                if #values > 0 then
                    cprint("    ${color.dump.string}%s${clear}:", valuename)
                    for _, value in ipairs(values) do
                        cprint("      ${color.dump.reference}->${clear} %s", value)
                    end
                end
            end
        end
    end
    local files = target:get("files")
    if files then
        cprint("    ${color.dump.string}files${clear}:")
        for _, file in ipairs(files) do
            cprint("      ${color.dump.reference}->${clear} %s", file)
        end
    end
end

function main(name)

    -- get target
    config.load()
    local target = assert(project.target(name), "target(%s) not found!", name)

    -- show target information
    _show_target(target)
end
