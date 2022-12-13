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
-- @file        register_packages.lua
--

-- imports
import("core.project.project")

-- register required package environments
-- envs: bin path for *.dll, program ..
function _register_required_package_envs(instance, envs)
    for name, values in table.orderpairs(instance:envs()) do
        envs[name] = envs[name] or {}
        table.join2(envs[name], values)
    end
end

-- register required package libraries
-- libs: includedirs, links, linkdirs ...
function _register_required_package_libs(instance, required_package, is_deps)
    if instance:is_library() then
        local fetchinfo = table.clone(instance:fetch())
        if fetchinfo then
            fetchinfo.name = nil
            if is_deps then
                -- we need only reserve license for root package
                --
                -- @note the license compatibility between the root package and
                -- its dependent packages is guaranteed by the root package itself
                --
                fetchinfo.license = nil

                -- we need only some infos for root package
                fetchinfo.version = nil
                fetchinfo.static  = nil
                fetchinfo.shared  = nil
                fetchinfo.installdir = nil
                fetchinfo.extra = nil
            end

            -- merge into the root values
            local components = fetchinfo.components
            fetchinfo.components = nil
            required_package:add(fetchinfo)

            -- save components list and dependencies
            if components then
                required_package:set("__components_deps", instance:components_deps())
                required_package:set("__components_default", instance:components_default())
                required_package:set("__components_orderlist", instance:components_orderlist())
            end

            -- merge into the components values
            local required_components = required_package:get("components")
            if required_components then
                fetchinfo.libfiles = nil
                local components_base = required_components.__base or {}
                for k, v in table.orderpairs(fetchinfo) do
                    local values = table.wrap(components_base[k])
                    components_base[k] = table.unwrap(table.unique(table.join(values, v)))
                end
                required_components.__base = components_base
            else
                required_package:set("components", components)
            end
        end
    end
end

-- register the base info of required package
function _register_required_package_base(instance, required_package)
    if not instance:is_system() and not instance:is_thirdparty() then
        required_package:set("installdir", instance:installdir())
    end
end

-- register the required local package
function _register_required_package(instance, required_package)

    -- disable it if this package is missing
    if not instance:exists() then
        required_package:enable(false)
    else
        -- clear require info first
        required_package:clear()

        -- add packages info with all dependencies
        local envs = {}
        _register_required_package_base(instance, required_package)
        _register_required_package_libs(instance, required_package)
        _register_required_package_envs(instance, envs)
        for _, dep in ipairs(instance:librarydeps()) do
            if instance:is_library() then
                _register_required_package_libs(dep, required_package, true)
            end
        end
        for _, dep in ipairs(instance:orderdeps()) do
            if not dep:is_private() then
                _register_required_package_envs(dep, envs)
            end
        end
        if #table.keys(envs) > 0 then
            required_package:add({envs = envs})
        end

        -- enable this require info
        required_package:enable(true)
    end

    -- save this require info and flush the whole cache file
    required_package:save()
end

-- register all required root packages to local cache
function main(packages)
    for _, instance in ipairs(packages) do
        if instance:is_toplevel() then
            local required_packagename = instance:alias() or instance:name()
            local required_package = project.required_package(required_packagename)
            if required_package then
                _register_required_package(instance, required_package)
            end
        end
    end
end

