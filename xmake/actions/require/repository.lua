--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
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
        local repodir = path.join(repository.directory(repo.global), repo.name)
        if not os.isdir(repodir) then
            return false
        end
    end
    return true
end

-- get package directory from repositories
function packagedir(packagename, reponame)

    -- get it from cache it
    local packagedirs = _g._PACKAGEDIRS or {}
    local foundir = packagedirs[packagename]
    if foundir then
        return foundir[1], foundir[2]
    end

    -- find the package directory from the given repository 
    if reponame then
        for _, from in ipairs({"local", "global"}) do
            local is_global = (from == "global")
            for _, repodir in ipairs(repository.directory(is_global)) do
                local dir = path.join(repodir, reponame, "packages", (packagename:gsub('%.', path.seperator())))
                if os.isdir(dir) then
                    foundir = {dir, is_global} 
                    break
                end
            end
            if foundir then
                break
            end
        end
    else
        -- find the package directory from all repositories
        for _, repo in ipairs(repositories()) do

            -- the package directory
            local dir = path.join(repository.directory(repo.global), repo.name, "packages", (packagename:gsub('%.', path.seperator())))
            if os.isdir(dir) then
                foundir = {dir, repo.global}
                break
            end
        end
    end

    -- not found? find this package from the builtin packages directory
    if not foundir then
        local dir = path.join(os.programdir(), "packages", (packagename:gsub('%.', path.seperator())))
        if os.isdir(dir) then
            foundir = {dir, true}
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

    -- split name by '.'
    local subdirs = "**" .. table.concat(name:split('%.'), "*" .. path.seperator() .. "*") .. "*"

    -- find the package directories from all repositories
    local packageinfos = {}
    for _, repo in ipairs(repositories()) do

        -- the package directory pattern
        for _, file in ipairs(os.files(path.join(repository.directory(repo.global), repo.name, "packages", subdirs, "xmake.lua"))) do
            packageinfos[path.basename(path.directory(file))] = {is_global = repo.global, packagedir = path.directory(file)}
        end
    end

    -- search the package directories from the builtin packages directory
    for _, file in ipairs(os.files(path.join(os.programdir(), "packages", subdirs, "xmake.lua"))) do
        packageinfos[path.basename(path.directory(file))] = {is_global = repo.global, packagedir = path.directory(file)}
    end

    -- ok?
    return packageinfos
end

