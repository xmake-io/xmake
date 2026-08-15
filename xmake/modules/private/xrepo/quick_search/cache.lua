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
-- @author      glcraft
-- @file        cache.lua
--

import("core.base.json")
import("core.cache.globalcache")
import("core.package.package", {alias = "core_package"})
import("private.action.require.impl.repository")

local cache = globalcache.cache("quick_search")

-- get the cache key of the given package
--
-- @note the addons are stored with the `addon::` prefix,
-- because an addon and a package may have the same name
--
function _cachekey(packagename, kind)
    return kind == "addon" and ("addon::" .. packagename) or packagename
end

-- search package directories from repositories
--
-- the packages are stored in <repodir>/packages/<first-letter>/<name>,
-- and the addons are stored in <repodir>/addons/<first-letter>/<name>
--
function _list_package_dirs()
    -- find the package directories from all repositories
    local unique = {}
    local packageinfos = {}
    for _, repo in ipairs(repository.repositories()) do
        for _, rootinfo in ipairs({{rootdir = "packages"}, {rootdir = "addons", kind = "addon"}}) do
            for _, file in ipairs(os.files(path.join(repo:directory(), rootinfo.rootdir, "*", "*", "xmake.lua"))) do
                local dir = path.directory(file)
                local subdirname = path.basename(path.directory(dir))
                if #subdirname == 1 then -- ignore l/luajit/port/xmake.lua
                    local packagename = path.filename(dir)
                    local cachekey = _cachekey(packagename, rootinfo.kind)
                    if not unique[cachekey] then
                        table.insert(packageinfos, {name = packagename, kind = rootinfo.kind, repo = repo, packagedir = dir})
                        unique[cachekey] = true
                    end
                end
            end
        end
    end
    return packageinfos
end

-- check cache content exists
function _init()
    if table.empty(cache:data()) then
        update()
    end
end

-- update the cache file
function update()
    for _, packageinfo in ipairs(_list_package_dirs()) do
        local package = core_package.load_from_repository(packageinfo.name, packageinfo.packagedir, {repo = packageinfo.repo})
        cache:set(_cachekey(packageinfo.name, packageinfo.kind), {
            name = packageinfo.name,
            kind = packageinfo.kind,
            reponame = package:repo() and package:repo():name(),
            description = package:description(),
            versions = package:versions(),
        })
    end
    cache:save()
end

-- remove the cache file
function clear()
    cache:clear()
    cache:save()
end

-- get the cache data
function get()
    _init()
    return cache:data()
end

-- find package
--
-- @param name  the package name (support lua pattern)
-- @param opt   the options, e.g. {prefix = true, description = true, kind = "addon"}
--
function find(name, opt)
    _init()
    opt = opt or {}
    local list_result = {}
    for cachekey, packagedata in table.orderpairs(cache:data()) do
        -- we only search the packages with the given kind, e.g. nil (package), "addon"
        local packagename = packagedata.name or cachekey
        if packagedata.kind == opt.kind then
            local found = false
            if opt.prefix then
                found = packagename:startswith(name)
            else
                found = packagename:find(path.pattern(name))
            end
            if not found and opt.description and packagedata.description and packagedata.description:find(name) then
                found = true
            end
            if found then
                table.insert(list_result, {name = packagename, data = packagedata})
            end
        end
    end
    return list_result
end

