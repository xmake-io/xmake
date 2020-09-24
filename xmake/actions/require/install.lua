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

-- register the required local package
function _register_required_package(instance, requireinfo)

    -- disable it if this package is optional and missing
    if _g.optional_missing[instance:name()] then
        requireinfo:enable(false)
    else
        -- clear require info first
        requireinfo:clear()

        -- add include and links info
        requireinfo:add(instance:fetch())
        local orderdeps = instance:orderdeps()
        if orderdeps then
            local total = #orderdeps
            for idx, _ in ipairs(orderdeps) do
                local dep = orderdeps[total + 1 - idx]
                if dep then
                    requireinfo:add((dep:fetch()))
                end
            end
        end

        -- add environments
        local envs = {}
        local hasenvs = false
        local installdir = instance:installdir()
        for name, values in pairs(instance:envs()) do
            if name == "PATH" or name == "LD_LIBRARY_PATH" then
                for _, value in ipairs(values) do
                    envs[name] = envs[name] or {}
                    if path.is_absolute(value) then
                        table.insert(envs[name], value)
                    else
                        table.insert(envs[name], path.join(installdir, value))
                    end
                end
            else
                envs[name] = values
            end
            hasenvs = true
        end
        if hasenvs then
            requireinfo:add({envs = envs})
        end

        -- save this package version
        requireinfo:version_set(instance:version_str())

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
        raise("The packages(%s) not found!", table.concat(packages_missing, ", "))
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

    -- enter environment
    environment.enter()

    -- pull all repositories first if not exists
    --
    -- attempt to install git from the builtin-packages first if git not found
    --
    if find_tool("git") and not repository.pulled() then
        task.run("repo", {update = true})
    end

    -- install packages
    local packages = package.install_packages(requires, {requires_extra = requires_extra})
    if packages then

        -- check missing packages
        _check_missing_packages(packages)

        -- register all required local packages
        _register_required_packages(packages)
    end

    -- leave environment
    environment.leave()
end

