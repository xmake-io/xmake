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
-- @file        check.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("lib.detect.find_tool")
import("private.async.runjobs")
import("private.action.require.impl.package")
import("private.action.require.impl.repository")
import("private.action.require.impl.environment")
import("private.action.require.impl.register_packages")
import("private.action.require.impl.utils.get_requires")

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
    local packages = package.load_packages(requires, {requires_extra = requires_extra})
    if packages then

        -- fetch and register packages (with system) from local first
        runjobs("fetch_packages", function (index)
            local instance = packages[index]
            if instance and (not option.get("force") or (option.get("shallow") and not instance:is_toplevel())) then
                local oldenvs = os.getenvs()
                instance:envs_enter()
                instance:fetch()
                os.setenvs(oldenvs)
            end
        end, {total = #packages, isolate = true})

        -- register all required root packages to local cache
        register_packages(packages)
    end
end

