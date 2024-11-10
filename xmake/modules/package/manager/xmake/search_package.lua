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
-- @file        search_package.lua
--

-- imports
import("core.base.semver")
import("private.xrepo.quick_search.cache")

function _search_package(packages, name, opt)
    for _, packageinfo in ipairs(cache.find(name, {description = opt.description ~= false})) do
        local packagename = packageinfo.name
        local packagedata = packageinfo.data

        local version
        local versions = packagedata.versions
        if versions then
            versions = table.copy(versions)
            table.sort(versions, function (a, b) return semver.compare(a, b) > 0 end)
            if opt.require_version then
                for _, ver in ipairs(versions) do
                    if semver.satisfies(ver, opt.require_version) then
                        version = ver
                    end
                end
            else
                version = versions[1]
            end
        end

        local description = packagedata.description
        if description then
            description = description:gsub(string.ipattern(name), function (w)
                return "${bright}" .. w .. "${clear}"
            end)
        end

        if not opt.require_version or version then
            packages[packagename] = {name = packagename, version = version, description = description, reponame = packagedata.reponame}
        end
    end
end

-- search package using the xmake package manager
--
-- @param name  the package name with pattern
-- @param opt   the options, e.g. {require_version = "1.x"}
--
function main(name, opt)
    opt = opt or {}
    local packages = {}
    _search_package(packages, name, opt)

    local results = {}
    for name, info in table.orderpairs(packages) do
        table.insert(results, info)
    end
    return results
end
