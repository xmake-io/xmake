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
-- @author      glcraft
-- @file        cache.lua
--

import("core.base.json")
import("core.cache.globalcache")
import("core.package.package", {alias = "core_package"})
import("private.action.require.impl.repository")

local cache = globalcache.cache("quick_search")

-- search package directories from repositories
function _list_package_dirs()
    -- find the package directories from all repositories
    local unique = {}
    local packageinfos = {}
    for _, repo in ipairs(repository.repositories()) do
        for _, file in ipairs(os.files(path.join(repo:directory(), "packages", "*", "*", "xmake.lua"))) do
            local dir = path.directory(file)
            local subdirname = path.basename(path.directory(dir))
            if #subdirname == 1 then -- ignore l/luajit/port/xmake.lua
                local packagename = path.filename(dir)
                if not unique[packagename] then
                    table.insert(packageinfos, {name = packagename, repo = repo, packagedir = path.directory(file)})
                    unique[packagename] = true
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
        local package = core_package.load_from_repository(packageinfo.name, packageinfo.repo, packageinfo.packagedir)
        cache:set(packageinfo.name, {
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

function find(name)
    _init()
    local list_result = {}
    for packagename, packagedata in pairs(cache:data()) do
        if packagename:find(name, 1, true) then
            table.insert(list_result, {name = packagename, data = packagedata})
        end
    end
    return list_result
end