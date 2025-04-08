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
-- @file        instance_deps.lua
--

-- define module
local instance_deps = instance_deps or {}

-- load modules
local option = require("base/option")
local string = require("base/string")
local table = require("base/table")

-- load deps for instance: e.g. option, instance and rule
--
-- e.g.
--
-- a.deps = b
-- b.deps = c
-- foo.deps = a d
--
-- foo.orderdeps: d -> c -> b -> a
--
-- if they're targets, their links order is reverse(orderdeps), e.g. foo: a -> b -> c -> d
--
function instance_deps.load_deps(instance, instances, deps, orderdeps, depspath, walkdep)
    local plaindeps = table.wrap(instance:get("deps"))
    local total = #plaindeps
    for idx, _ in ipairs(plaindeps) do
        -- we reverse to get the flat dependencies in order to ensure the correct linking order
        -- @see https://github.com/xmake-io/xmake/issues/3144
        local depname = plaindeps[total + 1 - idx]
        local depinst = instances[depname]
        if depinst == nil and instance.namespace then
            local namespace = instance:namespace()
            if namespace then
                depinst = instances[namespace .. "::" .. depname]
            end
        end
        if depinst then
            local continue_walk = true
            if walkdep then
                continue_walk = walkdep(instance, depinst)
            end
            if continue_walk then
                if not deps[depname] then
                    deps[depname] = depinst
                    local depspath_sub
                    if depspath then
                        for idx, name in ipairs(depspath) do
                            if name == depname then
                                local circular_deps = table.slice(depspath, idx)
                                table.insert(circular_deps, depname)
                                os.raise("circular dependency(%s) detected!", table.concat(circular_deps, ", "))
                            end
                        end
                        depspath_sub = table.join(depspath, depname)
                    end
                    instance_deps.load_deps(depinst, instances, deps, orderdeps, depspath_sub, walkdep)
                    table.insert(orderdeps, depinst)
                end
            end
        end
    end
end

-- sort the given instance with deps
function instance_deps._sort_instance(instance, instances, orderinstances, instancerefs, depspath)
    if not instancerefs[instance:fullname()] then
        instancerefs[instance:fullname()] = true
        for _, depname in ipairs(table.wrap(instance:get("deps"))) do
            local depinst = instances[depname]
            if depinst == nil and instance.namespace then
                local namespace = instance:namespace()
                if namespace then
                    depinst = instances[namespace .. "::" .. depname]
                end
            end
            if depinst then
                local depspath_sub
                if depspath then
                    for idx, name in ipairs(depspath) do
                        if name == depname then
                            local circular_deps = table.slice(depspath, idx)
                            table.insert(circular_deps, depname)
                            os.raise("circular dependency(%s) detected!", table.concat(circular_deps, ", "))
                        end
                    end
                    depspath_sub = table.join(depspath, depinst:fullname())
                end
                instance_deps._sort_instance(depinst, instances, orderinstances, instancerefs, depspath_sub)
            end
        end
        table.insert(orderinstances, instance)
    end
end

-- sort instances with deps
--
-- e.g.
--
-- a.deps = b
-- b.deps = c
-- foo.deps = a d
--
-- orderdeps: c -> b -> a -> d -> foo
function instance_deps.sort(instances)
    local refs = {}
    local orderinstances = {}
    for _, instance in table.orderpairs(instances) do
        instance_deps._sort_instance(instance, instances, orderinstances, refs, {instance:fullname()})
    end
    return orderinstances
end

-- return module
return instance_deps

