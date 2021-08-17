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
import("devel.git")
import("private.action.require.impl.utils.filter")
import("private.action.require.impl.utils.requirekey")

-- get locked package key
function _get_packagelock_key(instance)
    local requireinfo = instance:requireinfo()
    local requirestr  = requireinfo.originstr
    local key         = requirekey(requireinfo, {plat = instance:plat(), arch = instance:arch()})
    return string.format("%s#%s", requirestr, key)
end

-- lock package
function _lock_package(instance)
    local result      = {}
    local repo        = instance:repo()
    result.name       = instance:name()
    result.plat       = instance:plat()
    result.arch       = instance:arch()
    result.kind       = instance:kind()
    result.version    = instance:version_str()
    result.buildhash  = instance:buildhash()
    result.is_built   = instance:is_built()
    if repo then
        local lastcommit = git.lastcommit({repodir = repo:directory()})
        result.repo      = repo:url() .. "#" .. lastcommit
    end
    for _, url in ipairs(instance:urls()) do
        result.urls = result.urls or {}
        local url_alias = instance:url_alias(url)
        url = filter.handle(url, instance)
        if git.asgiturl(url) then
            local revision = instance:revision(url_alias) or instance:tag() or instance:version_str()
            url = url .. "#" .. revision
        else
            local sourcehash = instance:sourcehash(url_alias)
            if sourcehash then
                url = url .. "#" .. sourcehash
            end
        end
        table.insert(result.urls, url)
    end
    for _, dep in ipairs(instance:plaindeps()) do
        result.deps = result.deps or {}
        table.insert(result.deps, _get_packagelock_key(dep))
    end
    return result
end

-- lock all required packages
function main(packages)
    if project.policy("package.requires_lock") then
        local results = {}
        for _, instance in ipairs(packages) do
            local packagelock_key = _get_packagelock_key(instance)
            results[packagelock_key] = _lock_package(instance)
        end
        io.writefile(project.requireslock(), string.serialize(results, {orderkeys = true}))
    end
end

