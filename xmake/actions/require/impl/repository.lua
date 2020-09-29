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
-- @file        repository.lua
--

-- imports
import("core.package.repository")

-- get all repositories
function repositories()

    -- get it from cache it
    if _g._REPOSITORIES then
        return _g._REPOSITORIES
    end

    -- get all repositories (local first)
    local repos = table.join(repository.repositories(false), repository.repositories(true))

    -- save repositories
    _g._REPOSITORIES = repos

    -- ok
    return repos
end

-- the remote repositories have been pulled?
function pulled()
    for _, repo in ipairs(repositories()) do
        -- repository not found? or xmake has been re-installed
        local updatefile = path.join(repo:directory(), "updated")
        if not os.isdir(repo:directory()) or (os.isfile(updatefile) and os.mtime(os.programfile()) > os.mtime(updatefile)) then
            return false
        end
    end
    return true
end

-- get package directory from repositories
function packagedir(packagename, reponame)

    -- strip trailng ~tag, e.g. zlib~debug
    if packagename:find('~', 1, true) then
        packagename = packagename:gsub("~.+$", "")
    end

    -- get it from cache it
    local packagedirs = _g._PACKAGEDIRS or {}
    local foundir = packagedirs[packagename]
    if foundir then
        return foundir[1], foundir[2]
    end

    -- find the package directory from repositories
    for _, repo in ipairs(repositories()) do
        local dir = path.join(repo:directory(), "packages", packagename:sub(1, 1):lower(), packagename)
        if os.isdir(dir) and (not reponame or reponame == repo:name()) then
            foundir = {dir, repo}
            break
        end
    end

    -- found?
    if foundir then

        -- save package directory
        packagedirs[packagename] = foundir

        -- update cache
        _g._PACKAGEDIRS = packagedirs

        -- ok
        return foundir[1], foundir[2]
    end
end

-- search package directories from repositories
function searchdirs(name)

    -- find the package directories from all repositories
    local unique = {}
    local packageinfos = {}
    for _, repo in ipairs(repositories()) do
        for _, file in ipairs(os.files(path.join(repo:directory(), "packages", "*", string.ipattern("*" .. name .. "*"), "xmake.lua"))) do
            local packagename = path.basename(path.directory(file))
            if not unique[packagename] then
                table.insert(packageinfos, {name = packagename, repo = repo, packagedir = path.directory(file)})
                unique[packagename] = true
            end
        end
    end
    return packageinfos
end

