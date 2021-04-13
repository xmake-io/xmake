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
-- @file        environment.lua
--

-- imports
import("core.project.config")
import("lib.detect.find_tool")
import("private.action.require.impl.packagenv")
import("private.action.require.impl.install_packages")

-- enter environment
--
-- ensure that we can find some basic tools: git, unzip, ...
--
-- If these tools not exist, we will install it first.
--
function enter()

    -- unzip or 7zip is necessary
    if not find_tool("unzip") and not find_tool("7z") then
        raise("unzip or 7zip not found! we need install it first")
    end

    -- enter the environments of git
    packagenv.enter("git")

    -- git not found? install it first
    local packages = {}
    if not find_tool("git") then
        table.join2(packages, install_packages("git"))
        find_tool("git", {force = true}) -- we need force to detect and flush detect cache
    end

    -- missing the necessary unarchivers for *.gz, *.7z? install them first, e.g. gzip, 7z, tar ..
    if not ((find_tool("gzip") and find_tool("tar")) or find_tool("7z")) then
        table.join2(packages, install_packages("7z"))
        find_tool("7z", {force = true})
    end

    -- enter the environments of installed packages
    _g._OLDENVS = os.getenvs()
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end
    _g._PACKAGES = packages
end

-- leave environment
function leave()

    -- leave the environments of installed packages
    os.setenvs(_g._OLDENVS)
    _g._OLDENVS = nil
    _g._PACKAGES = nil

    -- leave the environments of git
    packagenv.leave("git")
end
