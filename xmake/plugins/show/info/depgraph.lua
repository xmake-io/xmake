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
import("private.detect.check_targetnames")

function _collect_target_entry(target)
    local deps = {}
    for _, depname in ipairs(table.wrap(target:get("deps"))) do
        local dep = target:dep(depname)
        if dep then
            table.insert(deps, dep:fullname())
        end
    end
    json.mark_as_array(deps)
    return {
        name = target:fullname(),
        deps = deps
    }
end

function _collect_target_graph(root_target)
    local targets = {}
    local selected = {}
    if root_target then
        selected[root_target:fullname()] = true
        for _, dep in ipairs(root_target:orderdeps() or {}) do
            selected[dep:fullname()] = true
        end
    end

    for _, target in ipairs(project.ordertargets()) do
        if not root_target or selected[target:fullname()] then
            table.insert(targets, _collect_target_entry(target))
        end
    end

    local roots = {}
    if root_target then
        table.insert(roots, root_target:fullname())
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

    json.mark_as_array(roots)
    return {
        root_targets = roots,
        targets = targets
    }
end

function _print_dep_tree(targets_map, name, prefix, expanded)
    expanded[name] = true
    local entry = targets_map[name]
    local deps = entry and entry.deps or {}
    for i, dep in ipairs(deps) do
        local is_last = (i == #deps)
        local connector = is_last and "\\-- " or "|-- "
        local next_prefix = prefix .. (is_last and "    " or "|   ")
        local dep_entry = targets_map[dep]
        local dep_deps = dep_entry and dep_entry.deps or {}
        if expanded[dep] and #dep_deps > 0 then
            cprint("%s%s${color.dump.reference}%s${clear} ${dim}(*)${clear}", prefix, connector, dep)
        else
            cprint("%s%s${color.dump.reference}%s${clear}", prefix, connector, dep)
            _print_dep_tree(targets_map, dep, next_prefix, expanded)
        end
    end
end

function _print_target_graph(graph)
    local targets_map = {}
    for _, target in ipairs(graph.targets) do
        targets_map[target.name] = target
    end
    local expanded = {}
    for _, root in ipairs(graph.root_targets) do
        cprint("${color.dump.string}%s${clear}", root)
        _print_dep_tree(targets_map, root, "", expanded)
    end
end

function _print_dot_graph(graph)
    print("digraph {")
    for _, target in ipairs(graph.targets) do
        if #target.deps == 0 then
            print(string.format("    \"%s\"", target.name))
        else
            for _, dep in ipairs(target.deps) do
                print(string.format("    \"%s\" -> \"%s\"", target.name, dep))
            end
        end
    end
    print("}")
end

function main(name)
    config.load()

    local root_target
    if name then
        root_target = assert(check_targetnames(name))
    end

    local graph = _collect_target_graph(root_target)

    -- support --format=json/dot/plain, with --json/--pretty backward compatibility
    local format = option.get("format") or "plain"
    if format == "plain" and option.get("json") then
        format = "json"
    end
    if format == "json" then
        local json_opt = {pretty = true, orderkeys = true}
        if option.get("json") and not option.get("pretty") then
            json_opt = nil
        end
        print(json.encode(graph, json_opt))
    elseif format == "dot" then
        _print_dot_graph(graph)
    else
        _print_target_graph(graph)
    end
end
