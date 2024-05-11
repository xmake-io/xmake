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
import("core.base.hashset")
import("core.base.json")
import("core.project.project")
import("core.package.package", {alias = "core_package"})
import("private.action.require.impl.package")
import("private.action.require.impl.repository")
import("private.action.require.impl.utils.get_requires")
import("private.action.require.impl.actions.check", {alias = "action_check"})

-- check the given package info
function main(requires_raw)

    -- get requires and extra config
    local requires_extra = nil
    local requires, requires_extra = get_requires(requires_raw)
    if not requires or #requires == 0 then
        return
    end

    -- check the given packages
    for _, instance in irpairs(package.load_packages(requires, {requires_extra = requires_extra, nodeps = true})) do
        action_check(instance)
    end
end

