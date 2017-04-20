--!The Make-like Build Utility based on Lua
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
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        repository.lua
--

-- imports
import("core.tool.git")
import("core.base.option")
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

-- pull repositories
function pull(position)

    -- pull all repositories 
    for _, repo in ipairs(repositories()) do

        -- trace
        print("updating repository ..")

        -- the repository directory
        local repodir = path.join(repository.directory(repo.global), repo.name)
        if os.isdir(repodir) then

            -- trace
            vprint("pulling repository(%s): %s to %s ..", repo.name, repo.url, repodir)

            -- pull it
            git.pull({verbose = option.get("verbose"), branch = "master", repodir = repodir})
        else
            -- trace
            vprint("cloning repository(%s): %s to %s ..", repo.name, repo.url, repodir)

            -- clone it
            git.clone(repo.url, {verbose = option.get("verbose"), branch = "master", outputdir = repodir})
        end
    end
end

-- get package directory from repositories
function packagedir(packagename, reponame)

    -- get it from cache it
    local packagedirs = _g._PACKAGEDIRS or {}
    if packagedirs[packagename] then
        return packagedirs[packagename]
    end

    -- find the package directory from the given repository 
    local foundir = nil
    if reponame then
        for _, repodir in ipairs(table.join(repository.directory(false), repository.directory(true))) do
            local dir = path.join(repodir, reponame, "packages", (packagename:gsub('%.', path.seperator())))
            if os.isdir(dir) then
                foundir = dir 
                break
            end
        end
    else
        -- find the package directory from all repositories
        for _, repo in ipairs(repositories()) do

            -- the package directory
            local dir = path.join(repository.directory(repo.global), repo.name, "packages", (packagename:gsub('%.', path.seperator())))
            if os.isdir(dir) then
                foundir = dir 
                break
            end
        end
    end

    -- found?
    if foundir then

        -- save package directory
        packagedirs[packagename] = foundir

        -- update cache
        _g._PACKAGEDIRS = packagedirs
    end

    -- ok
    return foundir
end

