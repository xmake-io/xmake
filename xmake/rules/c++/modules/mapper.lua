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
-- @author      ruki, Arthapz
-- @file        mapper.lua
--

import("support")
import("core.base.hashset")

-- get or create a target module mapper
function get_mapper_for(target, opt)
    local localcache = support.localcache()
    local mapper = localcache:get2(target:fullname(), "module_mapper")
    local invalidate = opt and opt.invalidate
    if not mapper or invalidate then
        mapper = {}
        localcache:set2(target:fullname(), "module_mapper", mapper)
    end
    return mapper
end

function reuse_modules(target)
    local localcache = support.localcache()
    local reused_modules = localcache:get2(target:fullname(), "reused_modules")
    for key, from_name in pairs(reused_modules) do
        local dep = target:dep(from_name)
        assert(dep)
        support.set_reused(target, dep, key)
    end
end

-- feed the module mapper
function feed(target, modules, sourcefiles)

    local mapper = get_mapper_for(target, {invalidate = true})
    local localcache = support.localcache()
    local deps_names = hashset.new()
    local deps_names_map = {}
    local headerunit_aliases = {}
    for _, module in pairs(modules) do
        if module.headerunit and module.alias then
            table.insert(headerunit_aliases, module)
        elseif not module.sourcealias then
            local name = module.headerunit and (module.name .. module.key) or module.name
            if name then
                if name ~= "std" and name ~= "std.compat" and deps_names:has(name) then
                    raise("duplicate module name detected for \"" .. name .. "\"\n  <" .. target:fullname() .. "> -> " .. module.sourcefile .. "\n  <" .. deps_names_map[name] .. "> -> " .. mapper[name].sourcefile)
                end
                deps_names:insert(module.name)
                deps_names_map[name] = target:fullname()
                if module.headerunit then
                    if not mapper[name] then
                        mapper[name] = module
                    end
                else
                    mapper[name] = module
                end
            end
            if not module.headerunit and not mapper[module.sourcefile] then
                mapper[module.sourcefile] = table.clone(module)
                mapper[module.sourcefile].sourcealias = true
            end
        end
    end
    local reuse = target:policy("build.c++.modules.reuse") or
                  target:policy("build.c++.modules.tryreuse")
    -- replace target reused module by dep module
    if reuse then
        for _, sourcefile in ipairs(sourcefiles) do
            local external = support.is_external(target, sourcefile)
            if external then
                local reused, from = support.is_reused(target, sourcefile)
                if reused then
                    local module = get(from, sourcefile)
                    mapper[module.name] =  module
                    for dep_name, dep_module in pairs(module.deps) do
                        if dep_module.headerunit then
                            local key = dep_name .. dep_module.key
                            mapper[key] = get(from, key)
                            local sourcefile = mapper[key].sourcefile
                            mapper[sourcefile .. dep_module.key] = table.clone(mapper[key])
                            mapper[sourcefile .. dep_module.key].alias = false
                        end
                    end
                end
            end
        end
    end
    -- insert aliases
    for _, alias in pairs(headerunit_aliases) do
        local name = alias.name .. alias.key
        if not mapper[name] then
            local _module = table.clone(mapper[alias.sourcefile .. alias.key])
            _module.name = alias.name
            _module.alias = true
            mapper[name] = _module
        end
    end

    localcache:save()
end

-- get a module from target mapper by name
function get(target, name)
    local mapper = get_mapper_for(target)
    assert(mapper)
    return mapper[name]
end

