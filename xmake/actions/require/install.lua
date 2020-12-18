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
-- @file        package.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("core.project.project")
import("lib.detect.find_tool")
import("impl.package")
import("impl.repository")
import("impl.environment")
import("impl.utils.get_requires")

-- register required package environments
-- envs: bin path for *.dll, program ..
function _register_required_package_envs(instance, envs)
    for name, values in pairs(instance:envs()) do
        if name == "PATH" or name == "LD_LIBRARY_PATH" or name == "DYLD_LIBRARY_PATH" then
            for _, value in ipairs(values) do
                envs[name] = envs[name] or {}
                if path.is_absolute(value) then
                    table.insert(envs[name], value)
                else
                    table.insert(envs[name], path.join(instance:installdir(), value))
                end
            end
        else
            envs[name] = envs[name] or {}
            table.join2(envs[name], values)
        end
    end
end

-- register required package libraries
-- libs: includedirs, links, linkdirs ...
function _register_required_package_libs(instance, requireinfo, is_deps)
    if instance:kind() ~= "binary" then
        local fetchinfo = instance:fetch()
        if fetchinfo then
            fetchinfo.name    = nil
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
            end
            requireinfo:add(fetchinfo)
        end
    end
end

-- register the required local package
function _register_required_package(instance, requireinfo)

    -- disable it if this package is optional and missing
    if _g.optional_missing[instance:name()] then
        requireinfo:enable(false)
    else
        -- clear require info first
        requireinfo:clear()

        -- add packages info with all dependencies
        local envs = {}
        _register_required_package_libs(instance, requireinfo)
        _register_required_package_envs(instance, envs)
        local orderdeps = instance:orderdeps()
        if orderdeps then
            local total = #orderdeps
            for idx, _ in ipairs(orderdeps) do
                local dep = orderdeps[total + 1 - idx]
                if dep then
                    _register_required_package_libs(dep, requireinfo, true)
                    _register_required_package_envs(dep, envs)
                end
            end
        end
        if #table.keys(envs) > 0 then
            requireinfo:add({envs = envs})
        end

        -- enable this require info
        requireinfo:enable(true)
    end

    -- save this require info and flush the whole cache file
    requireinfo:save()
end

-- register all required local packages
function _register_required_packages(packages)
    local registered_in_group = {}
    for _, instance in ipairs(packages) do

        -- only register the first package in same group
        local group = instance:group()
        if not group or not registered_in_group[group] then

            -- do not register binary package
            local requireinfo = project.require(instance:alias() or instance:name())
            if requireinfo then
                _register_required_package(instance, requireinfo)
            end

            -- mark as registered in group
            if group then
                registered_in_group[group] = true
            end
        end
    end
end

-- check missing packages
function _check_missing_packages(packages)

    -- get all missing packages
    local packages_missing = {}
    local optional_missing = {}
    for _, instance in ipairs(packages) do
        if not instance:exists() and (#instance:urls() > 0 or instance:isSys()) then
            if instance:optional() then
                optional_missing[instance:name()] = instance
            else
                table.insert(packages_missing, instance:name())
            end
        end
    end

    -- raise tips
    if #packages_missing > 0 then
        local cmd = "xmake repo -u"
        if os.getenv("XREPO_WORKING") then
            cmd = "xrepo update-repo"
        end
        raise("The packages(%s) not found, please run `%s` first!", table.concat(packages_missing, ", "), cmd)
    end

    -- save the optional missing packages
    _g.optional_missing = optional_missing
end

-- install packages
function main(requires_raw)

    -- avoid to run this task repeatly
    if _g.installed then return end
    _g.installed = true

    -- get requires and extra config
    local requires_extra = nil
    local requires, requires_extra = get_requires(requires_raw)
    if not requires or #requires == 0 then
        return
    end

    -- find git
    environment.enter()
    local git = find_tool("git")
    environment.leave()

    -- pull all repositories first if not exists
    --
    -- attempt to install git from the builtin-packages first if git not found
    --
    if git and not repository.pulled() then
        task.run("repo", {update = true})
    end

    -- install packages
    environment.enter()
    local packages = package.install_packages(requires, {requires_extra = requires_extra})
    if packages then

        -- check missing packages
        _check_missing_packages(packages)

        -- register all required local packages
        _register_required_packages(packages)
    end
    environment.leave()
end

