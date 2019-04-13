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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        uninstall.lua
--

-- imports
import("core.base.task")
import("core.base.option")
import("core.project.project")
import("impl.package")
import("impl.repository")
import("impl.environment")

-- uninstall the given packages
function main(package_names)

    -- no package name?
    if not package_names then
        return 
    end

    -- enter environment 
    environment.enter()

    -- pull all repositories first if not exists
    if not repository.pulled() then
        task.run("repo", {update = true})
    end

    -- get project requires 
    local project_requires, requires_extra = project.requires_str()
    if not project_requires then
        raise("requires(%s) not found in project!", table.concat(requires, " "))
    end

    -- find required package in project
    local requires = {}
    for _, name in ipairs(package_names) do
        for _, require_str in ipairs(project_requires) do
            if require_str:split(' ')[1]:lower() == name:lower() then
                table.insert(requires, require_str)
            end
        end
    end
    if #requires == 0 then
        raise("%s not found in project!", table.concat(package_names, " "))
    end

    -- uninstall packages
    local packages = package.uninstall_packages(requires, {requires_extra = requires_extra})
    for _, instance in ipairs(packages) do
        print("uninstall: %s%s ok!", instance:name(), instance:version_str() and ("-" .. instance:version_str()) or "")
    end

    -- leave environment
    environment.leave()
end

