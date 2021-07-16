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
-- @file        dump_targets.lua
--

-- imports
import("core.base.hashset")
import("core.project.config")
import("core.project.project")

-- get targets
function _get_targets(targetname)

    -- get targets
    local targets = {}
    if targetname then
        table.insert(targets, project.target(targetname))
    else
        for _, target in pairs(project.targets()) do
            table.insert(targets, target)
        end
    end
    return targets
end

-- dump the build jobs, e.g. xmake l private.diagnosis.dump_buildjobs [targetname]
function main(targetname)
    config.load()
    for _, target in ipairs(_get_targets(targetname)) do
        cprint("${bright}target(%s):${clear} %s", target:name(), target:kind())
        local deps = target:get("deps")
        if deps then
            cprint("  ${color.dump.string}deps:")
            cprint("    ${yellow}->${clear} %s", table.concat(table.wrap(deps), ", "))
        end
        local options = {}
        for _, optname in ipairs(target:get("options")) do
            if not optname:startswith("__") then
                table.insert(options, optname)
            end
        end
        if #options > 0 then
            cprint("  ${color.dump.string}options:")
            cprint("    ${yellow}->${clear} %s", table.concat(table.wrap(options), ", "))
        end
        local packages = target:get("packages")
        if packages then
            cprint("  ${color.dump.string}packages:")
            cprint("    ${yellow}->${clear} %s", table.concat(table.wrap(packages), ", "))
        end
        local rules = target:get("rules")
        if rules then
            cprint("  ${color.dump.string}rules:")
            cprint("    ${yellow}->${clear} %s", table.concat(table.wrap(rules), ", "))
        end
        print("")
    end
end

