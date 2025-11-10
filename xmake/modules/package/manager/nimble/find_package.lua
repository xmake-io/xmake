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
-- Copyright (C) 2015-present, Xmake Open Source Community.
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

-- parse package name and version (with old version)
--
-- e.g.
-- zip  [0.3.1]
-- zip  [(version: 0.3.1, checksum: 747aab3c43ecb7b50671cdd0ec3b2edc2c83494c)]
--
function _parse_packageinfo_v1(line)
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

-- parse package name and version (with new version)
--
-- e.g.
-- bearssl
-- └── @0.2.5 (550e6f9321b85de53bba9c0ffab9c95ffbe12ab3) (C:\Users\V\.nimble\pkgs2\bearssl-0.2.5-550e6f9321b85de53bba9c0ffab9c95ffbe12ab3)
-- imguin
-- ├── @1.92.3.0 (9b1400a393d47e0b7a7301115abd04b11a735b06) (C:\Users\V\.nimble\pkgs2\imguin-1.92.3.0-9b1400a393d47e0b7a7301115abd04b11a735b06)
-- └── @1.92.4.0 (fe2a7f25cfc17144dfb4f34c80655827bbe80fcb) (C:\Users\V\.nimble\pkgs2\imguin-1.92.4.0-fe2a7f25cfc17144dfb4f34c80655827bbe80fcb)
--
function _parse_packageinfo_v2(line)
    -- match package name (top-level entries only, not indented)
    local package_name = line:match("^(%S+)$")
    if package_name then
        return package_name, nil
    end

    -- match version lines like: └── @1.92.4.0 (...) or ├── @0.2.5 (...)
    local version_str = line:match("^[├└].-@([%d%.]+)")
    if version_str then
        local version = semver.match(version_str)
        if version then
            return nil, version:rawstr()
        end
    end

    return nil, nil
end

-- find package with new format
function _find_package_v2(name, list, opt)
    local result
    local current_package
    for _, line in ipairs(list:split("\n", { plain = true })) do
        local package_name, package_version = _parse_packageinfo_v2(line)
        if package_name then
            current_package = package_name
        elseif package_version and current_package == name then
            if opt.require_version then
                if package_version and (opt.require_version == "latest" or semver.satisfies(package_version, opt.require_version)) then
                    result = { version = package_version }
                    break
                end
            else
                result = {}
                break
            end
        end
    end
    return result
end

-- find package with old format
function _find_package_v1(name, list, opt)
    local result
    for _, line in ipairs(list:split("\n", {plain = true})) do
        local package_name, package_version = _parse_packageinfo_v1(line)
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
    return result
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
    local list = os.iorunv(nimble.program, {"list", "-i", "--ver"})
    if not list then
        return
    end

    -- new format?
    local result
    if list:find("Package list format:", 1, true) then
        result = _find_package_v2(name, list, opt)
    else
        result = _find_package_v1(name, list, opt)
    end

    -- @note we don't need return links and includedirs information,
    -- because it's nim source code package and nim will find them automatically
    return result
end
