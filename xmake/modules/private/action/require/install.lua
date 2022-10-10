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
-- @file        install.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("lib.detect.find_tool")
import("private.action.require.impl.package")
import("private.action.require.impl.repository")
import("private.action.require.impl.environment")
import("private.action.require.impl.install_packages")
import("private.action.require.impl.utils.get_requires")

-- check missing packages
function _check_missing_packages(packages)

    -- get all missing packages
    local packages_missing = {}
    local optional_missing = {}
    for _, instance in ipairs(packages) do
        if package.should_install(instance, {install_finished = true}) or (instance:is_fetchonly() and not instance:exists()) then
            if instance:is_optional() then
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
    if git and (not repository.pulled() or option.get("upgrade")) then
        task.run("repo", {update = true})
    end

    -- install packages
    environment.enter()
    local packages = install_packages(requires, {requires_extra = requires_extra})
    if packages then
        _check_missing_packages(packages)
    end
    environment.leave()
end

