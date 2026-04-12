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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        depgraph.lua
--

-- imports
import("core.base.option")
import("core.base.json")
import("core.project.config")
import("core.project.project")
import("private.detect.check_targetname")

function _collect_target_entry(target)
    local deps = {}
    local plain_deps = target:get("deps")
    if plain_deps then
        for _, dep in ipairs(plain_deps) do
            table.insert(deps, dep)
        end
    end

    return {
        name = target:name(),
        kind = target:kind(),
        group = target:get("group"),
        default = target:is_default(),
        deps = deps
    }
end

function _collect_target_graph(root_target)
    local targets = {}
    local selected = {}
    if root_target then
        selected[root_target:name()] = true
        for _, dep in ipairs(root_target:orderdeps() or {}) do
            selected[dep:name()] = true
        end
    end

    for _, target in ipairs(project.ordertargets()) do
        if not root_target or selected[target:name()] then
            table.insert(targets, _collect_target_entry(target))
        end
    end

    local roots = {}
    if root_target then
        table.insert(roots, root_target:name())
    else
        local indegrees = {}
        for _, target in ipairs(targets) do
            indegrees[target.name] = 0
        end
        for _, target in ipairs(targets) do
            for _, depname in ipairs(target.deps) do
                if indegrees[depname] ~= nil then
                    indegrees[depname] = indegrees[depname] + 1
                end
            end
        end
        for _, target in ipairs(targets) do
            if indegrees[target.name] == 0 then
                table.insert(roots, target.name)
            end
        end
    end

    return {
        root_targets = roots,
        targets = targets
    }
end

function _print_target_graph(graph)
    print("The dependency graph of targets:")
    cprint("")
    cprint("  ${color.dump.string}root targets${clear}: %s", table.concat(graph.root_targets, ", "))
    cprint("")
    for _, target in ipairs(graph.targets) do
        local deps = #target.deps > 0 and table.concat(target.deps, ", ") or "(none)"
        cprint("  ${color.dump.string}%s${clear}:", target.name)
        cprint("    ${dim}kind${clear}: %s", target.kind)
        if target.group then
            cprint("    ${dim}group${clear}: %s", target.group)
        end
        cprint("    ${dim}default${clear}: %s", tostring(target.default))
        cprint("    ${dim}deps${clear}: %s", deps)
    end
end

function main(name)
    config.load()

    local root_target
    if name then
        root_target = assert(check_targetname(name))
    end

    local graph = _collect_target_graph(root_target)
    if option.get("json") then
        local json_opt
        if option.get("pretty") then
            json_opt = {pretty = true, orderkeys = true}
        end
        print(json.encode(graph, json_opt))
    else
        _print_target_graph(graph)
    end
end
