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
-- @file        export.lua
--

-- imports
import("core.base.task")
import("core.base.option")
import("impl.package")
import("impl.repository")
import("impl.environment")
import("impl.utils.get_requires")

-- export the given packages
function main(requires_raw)

    -- enter environment
    environment.enter()

    -- pull all repositories first if not exists
    if not repository.pulled() then
        task.run("repo", {update = true})
    end

    -- get requires and extra config
    local requires_extra = nil
    local requires, requires_extra = get_requires(requires_raw)
    if not requires or #requires == 0 then
        return
    end

    -- export packages
    local packages = package.export_packages(requires, {requires_extra = requires_extra, exportdir = option.get("exportdir")})
    for _, instance in ipairs(packages) do
        print("export: %s%s ok!", instance:name(), instance:version_str() and ("-" .. instance:version_str()) or "")
    end
    if not packages or #packages == 0 then
        print("local packages not found!")
    end

    -- leave environment
    environment.leave()
end

