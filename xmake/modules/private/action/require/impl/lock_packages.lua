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
import("core.project.config")
import("devel.git")
import("private.action.require.impl.utils.filter")
import("private.action.require.impl.utils.requirekey")

-- get locked package key
function _get_packagelock_key(instance)
    local requireinfo = instance:requireinfo()
    return requireinfo and requireinfo.requirekey
end

-- lock package
function _lock_package(instance)
    local result      = {}
    local repo        = instance:repo()
    result.name       = instance:name()
    result.plat       = instance:plat()
    result.arch       = instance:arch()
    result.version    = instance:version_str()
    result.buildhash  = instance:buildhash()
    result.branch     = instance:branch()
    result.tag        = instance:tag()
    if repo then
        local lastcommit = git.lastcommit({repodir = repo:directory()})
        result.repo      = repo:url() .. "#" .. lastcommit
    end
    return result
end

-- lock all required packages
function main(packages)
    if project.policy("package.requires_lock") then
        local results = {}
        results.version = project.requireslock_version()
        for _, instance in ipairs(packages) do
            local packagelock_key = _get_packagelock_key(instance)
            results[packagelock_key] = _lock_package(instance)
        end
        io.writefile(project.requireslock(), string.serialize(results, {orderkeys = true}))
    end
end

