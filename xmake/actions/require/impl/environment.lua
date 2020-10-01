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
-- @file        environment.lua
--

-- imports
import("core.project.config")
import("core.platform.environment")
import("core.package.package", {alias = "core_package"})
import("lib.detect.find_tool")
import("private.action.require.packagenv")
import("package")

-- enter environment
--
-- ensure that we can find some basic tools: git, unzip, ...
--
-- If these tools not exist, we will install it first.
--
function enter()

    -- set search paths of toolchains
    environment.enter("toolchains")

    -- unzip or 7zip is necessary
    if not find_tool("unzip") and not find_tool("7z") then
        raise("unzip or 7zip not found! we need install it first")
    end

    -- enter the environments of git and 7z
    packagenv.enter("git", "7z")

    -- git not found? install it first
    local packages = {}
    if not find_tool("git") then
        table.join2(packages, package.install_packages("git"))
    end

    -- missing the necessary unarchivers for *.gz, *.7z? install them first, e.g. gzip, 7z, tar ..
    if not ((find_tool("gzip") and find_tool("tar")) or find_tool("7z")) then
        table.join2(packages, package.install_packages("7z"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end
    _g._PACKAGES = packages
end

-- leave environment
function leave()

    -- leave the environments of installed packages
    for _, instance in irpairs(_g._PACKAGES) do
        instance:envs_leave()
    end
    _g._PACKAGES = nil

    -- leave the environments of git and 7z
    packagenv.leave("7z", "git")

    -- restore search paths of toolchains
    environment.leave("toolchains")
end
