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

-- define module
local sandbox_core_package_repository = sandbox_core_package_repository or {}

-- load modules
local project       = require("project/project")
local repository    = require("package/repository")
local raise         = require("sandbox/modules/raise")

-- get repository directory
function sandbox_core_package_repository.directory(is_global)
    return repository.directory(is_global)
end

-- get repository url from the given name
function sandbox_core_package_repository.get(name, is_global)

    -- get it
    return repository.get(name, is_global)
end

-- add repository url to the given name
function sandbox_core_package_repository.add(name, url, is_global)

    -- add it
    local ok, errors = repository.add(name, url, is_global)
    if not ok then
        raise(errors)
    end
end

-- remove repository from gobal or local directory
function sandbox_core_package_repository.remove(name, is_global)

    -- remove it
    local ok, errors = repository.remove(name, is_global)
    if not ok then
        raise(errors)
    end
end

-- clear all repositories from global or local directory
function sandbox_core_package_repository.clear(is_global)

    -- clear all repositories
    local ok, errors = repository.clear(is_global)
    if not ok then
        raise(errors)
    end
end

-- get all repositories from global or local directory
function sandbox_core_package_repository.repositories(is_global)

    -- add default global xmake repository
    local repositories = {}
    if is_global then
        table.insert(repositories, {name = "xmake-repo", url = "https://github.com/tboox/xmake-repo.git", global = true})
    end

    -- load repositories from repository cache 
    for name, url in pairs(table.wrap(repository.repositories(is_global))) do
        table.insert(repositories, {name = name, url = url, global = is_global})
    end

    -- load repositories from project file
    if not is_global then
        for _, repo in ipairs(table.wrap(project.get("repositories"))) do
            local repoinfo = repo:split(' ')
            if #repoinfo == 2 then
                table.insert(repositories, {name = repoinfo[1], url = repoinfo[2], global = is_global})
            else
                raise("invalid repository: %s", repo)
            end
        end
    end

    -- get the repositories
    return repositories
end

-- return module
return sandbox_core_package_repository
