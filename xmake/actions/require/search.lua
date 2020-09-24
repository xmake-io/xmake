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
-- @file        search.lua
--

-- imports
import("core.base.task")
import("impl.utils.filter")
import("impl.package")
import("impl.repository")
import("impl.environment")

-- search the given packages
function main(names)

    -- no names?
    if not names then
        return
    end

    -- enter environment
    environment.enter()

    -- pull all repositories first if not exists
    if not repository.pulled() then
        task.run("repo", {update = true})
    end

    -- show title
    print("The package names:")

    -- search packages
    for name, packages in pairs(package.search_packages(names)) do
        if #packages > 0 then

            -- show name
            print("    %s: ", name)

            -- show packages
            for _, instance in ipairs(packages) do
                local repo = instance:repo()
                cprint("      -> ${magenta}%s${clear}: %s %s", instance:name(), instance:get("description") or "", repo and ("(in " .. repo:name() .. ")") or "")
            end
        end
    end

    -- leave environment
    environment.leave()
end

