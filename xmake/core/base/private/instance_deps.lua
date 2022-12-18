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
-- orderdeps: c -> b -> d -> a -> foo
--
-- if they're target, their links order is reverse(orderdeps), e.g. foo-> a -> d -> b -> c
--
function instance_deps.load_deps(instance, instances, deps, orderdeps, depspath)
    local plaindeps = table.wrap(instance:get("deps"))
    local total = #plaindeps
    for idx, _ in ipairs(plaindeps) do
        -- we reverse to get the flat dependencies in order to ensure the correct linking order
        -- @see https://github.com/xmake-io/xmake/issues/3144
        local dep = plaindeps[total + 1 - idx]
        local depinst = instances[dep]
        if depinst then
            local depspath_sub
            if depspath then
                for idx, name in ipairs(depspath) do
                    if name == dep then
                        local circular_deps = table.slice(depspath, idx)
                        table.insert(circular_deps, dep)
                        os.raise("circular dependency(%s) detected!", table.concat(circular_deps, ", "))
                    end
                end
                depspath_sub = table.join(depspath, dep)
            end
            instance_deps.load_deps(depinst, instances, deps, orderdeps, depspath_sub)
            if not deps[dep] then
                deps[dep] = depinst
                table.insert(orderdeps, depinst)
            end
        end
    end
end

-- sort instances for all deps
function instance_deps.sort_deps(instances, orderinstances, instancerefs, instance)
    for _, depname in ipairs(table.wrap(instance:get("deps"))) do
        local instanceinst = instances[depname]
        if instanceinst then
            instance_deps.sort_deps(instances, orderinstances, instancerefs, instanceinst)
        end
    end
    if not instancerefs[instance:name()] then
        instancerefs[instance:name()] = true
        table.insert(orderinstances, instance)
    end
end

-- return module
return instance_deps

