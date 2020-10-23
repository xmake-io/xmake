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
-- @file        fetch.lua
--

-- imports
import("core.base.task")
import("core.base.option")
import("core.base.hashset")
import("core.project.project")
import("core.package.package", {alias = "core_package"})
import("devel.git")
import("utils.archive")
import("impl.utils.filter")
import("impl.package")
import("impl.repository")
import("impl.environment")
import("impl.utils.get_requires")

-- fetch the given package info
function main(requires_raw)

    -- get requires and extra config
    local requires_extra = nil
    local requires, requires_extra = get_requires(requires_raw)
    if not requires or #requires == 0 then
        return
    end

    -- fetch all packages
    local fetchinfos = {}
    for _, instance in ipairs(package.load_packages(requires, {requires_extra = requires_extra})) do
        local fetchinfo = instance:fetch()
        if fetchinfo then
            table.insert(fetchinfos, fetchinfo)
        end
    end

    -- show results
    if #fetchinfos > 0 then
        print(fetchinfos)
    end
end

