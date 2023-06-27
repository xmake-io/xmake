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
import("core.package.package", {alias = "core_package"})
import("private.action.require.impl.repository")

-- search package from name
function _search_package_from_name(name, opt)
    local results = {}
    for _, packageinfo in ipairs(repository.searchdirs(name)) do
        local package = core_package.load_from_repository(packageinfo.name, packageinfo.packagedir, {repo = packageinfo.repo})
        if package then
            local repo = package:repo()
            local version
            local versions = package:versions()
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
            results[package:name()] = {name = package:name(), version = version, description = package:get("description"), reponame = repo and repo:name()}
        end
    end
    return results
end

-- search package from description
function _search_package_from_description(name, opt)
    local results = {}
    for _, packageinfo in ipairs(repository.searchdirs("*")) do
        local package = core_package.load_from_repository(packageinfo.name, packageinfo.packagedir, {repo = packageinfo.repo})
        if package then
            local description = package:description()
            if description and description:find(string.ipattern(name)) then
                local repo = package:repo()
                local version
                local versions = package:versions()
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
                results[package:name()] = {name = package:name(), version = version, description = package:get("description"), reponame = repo and repo:name()}
            end
        end
    end
    return results
end

-- search package using the xmake package manager
--
-- @param name  the package name with pattern
-- @param opt   the options, e.g. {require_version = "1.x"}
--
function main(name, opt)
    opt = opt or {}
    local packages = {}
    table.join2(packages, _search_package_from_name(name, opt))
    table.join2(packages, _search_package_from_description(name, opt))

    local results = {}
    for name, info in table.orderpairs(packages) do
        table.insert(results, info)
    end
    return results
end
