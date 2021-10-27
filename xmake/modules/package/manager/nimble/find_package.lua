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
        local splitinfo = line:split("%s+")
        local package_name = splitinfo[1]
        local package_version = splitinfo[2]
        if package_name == name and package_version then
            if package_version then
                package_version = package_version:match("%[(.+)%]")
            end
            if opt.require_version then
                if package_version and (opt.require_version == "latest" or semver.match(package_version, 1, opt.require_version)) then
                    result = {version = package_version}
                    break
                end
            else
                result = {}
                break
            end
        end
    end
    -- @note we need not return links and includedirs information,
    -- because it's nim source code package and nim will find them automatically
    return result
end
