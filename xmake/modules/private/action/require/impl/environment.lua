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
        raise("failed to find unzip or 7zip! please install one of them first")
    end

    -- enter the environments of git
    _g._OLDENVS = packagenv.enter("git")

    -- git not found? install it first
    local packages = {}
    local git = find_tool("git")
    if not git then
        table.join2(packages, install_packages("git"))
    end

    -- missing the necessary unarchivers for *.gz, *.7z? install them first, e.g. gzip, 7z, tar ..
    local zip = (find_tool("gzip") and find_tool("tar")) or find_tool("7z")
    if not zip then
        table.join2(packages, install_packages("7z"))
    end

    -- enter the environments of installed packages
    for _, instance in ipairs(packages) do
        instance:envs_enter()
    end

    -- we need force to detect and flush detect cache after loading all environments
    if not git then
        find_tool("git", {force = true})
    end
    if not zip then
        find_tool("7z", {force = true})
    end
end

-- leave environment
function leave()
    local oldenvs = _g._OLDENVS
    if oldenvs then
        os.setenvs(oldenvs)
    end
end
