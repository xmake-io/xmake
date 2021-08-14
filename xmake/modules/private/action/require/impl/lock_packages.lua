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
-- @file        lock_packages.lua
--

-- imports
import("core.project.project")

-- lock package
function _lock_package(instance)
    local result = {}
    result.name      = instance:name()
    result.plat      = instance:plat()
    result.arch      = instance:arch()
    result.kind      = instance:kind()
    result.buildhash = instance:buildhash()
    result.version   = instance:version_str()
    return result
end

-- lock all required packages
function main(packages)
    local results = {}
    for _, instance in ipairs(packages) do
        results[instance:displayname()] = _lock_package(instance)
    end
    io.writefile(project.requireslock(), string.serialize(results, {orderkeys = true}))
end

