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
import("core.base.global")
import("core.package.package", {alias = "core_package"})
import("private.action.require.impl.repository")

local CACHE_PATH = path.join(global.cachedir(), "repositories_data.json")

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

-- update the cache file
function update()
    local result = {}
    for _, packageinfo in ipairs(_list_package_dirs()) do
        local package = core_package.load_from_repository(packageinfo.name, packageinfo.repo, packageinfo.packagedir)
        table.insert(result,{
            name = packageinfo.name,
            description = package:description(),
            versions = package:versions(),
        })
    end
    io.writefile(CACHE_PATH, json.encode(result))
    return result
end

-- remove the cache file
function clear()
    if os.exists(CACHE_PATH) then
        os.rm(CACHE_PATH)
    end
end

-- get the cache data
function get()
    if not os.exists(CACHE_PATH) then
        return update()
    end
    return json.decode(io.readfile(CACHE_PATH))
end