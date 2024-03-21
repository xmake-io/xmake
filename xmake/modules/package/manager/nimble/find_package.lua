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
-- @file        find_package.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.project.config")
import("core.project.target")
import("lib.detect.find_tool")
import("lib.detect.find_file")

-- parse package name and version
--
-- e.g.
-- zip  [0.3.1]
-- zip  [(version: 0.3.1, checksum: 747aab3c43ecb7b50671cdd0ec3b2edc2c83494c)]
--
function _parse_packageinfo(line)
    local splitinfo = line:split("%s+", {limit = 2})
    local package_name = splitinfo[1]
    local version_str = splitinfo[2]
    if version_str then
        local version = semver.match(version_str)
        if version then
            package_version = version:rawstr()
        end
    end
    return package_name, package_version
end

-- find package using the nimble package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, require_version = "1.12.x")
--
function main(name, opt)

    -- find nimble
    local nimble = find_tool("nimble")
    if not nimble then
        raise("nimble not found!")
    end

    -- find it from all installed package list
    local result
    local list = os.iorunv(nimble.program, {"list", "-i"})
    for _, line in ipairs(list:split("\n", {plain = true})) do
        local package_name, package_version = _parse_packageinfo(line)
        if package_name == name then
            if opt.require_version then
                if package_version and (opt.require_version == "latest" or semver.satisfies(package_version, opt.require_version)) then
                    result = {version = package_version}
                    break
                end
            else
                result = {}
                break
            end
        end
    end
    -- @note we don't need return links and includedirs information,
    -- because it's nim source code package and nim will find them automatically
    return result
end
