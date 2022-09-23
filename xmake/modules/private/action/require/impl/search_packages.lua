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
-- @file        search_packages.lua
--

-- search packages from repositories
function _search_packages(name, opt)

    -- get package manager name
    local manager_name, package_name = table.unpack(name:split("::", {plain = true, strict = true}))
    if package_name == nil then
        package_name = manager_name
        manager_name = "xmake"
    else
        manager_name = manager_name:lower():trim()
    end

    -- search packages
    local packages = {}
    local result = import("package.manager." .. manager_name .. ".search_package", {anonymous = true})(package_name, opt)
    if result then
        table.join2(packages, result)
    end
    return packages
end

-- search packages
function main(names, opt)
    local results = {}
    for _, name in ipairs(names) do
        local packages = _search_packages(name, opt)
        if packages then
            results[name] = packages
        end
    end
    return results
end
