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
local repository = repository or {}

-- load modules
local utils     = require("base/utils")
local string    = require("base/string")
local global    = require("base/global")
local cache     = require("project/cache")
local config    = require("project/config")

-- get cache
function repository._cache(is_global)

    -- get position
    local position = utils.ifelse(is_global, "global", "local")

    -- get it from cache first if exists
    if repository._CACHE and repository._CACHE[position] then
        return repository._CACHE[position]
    end

    -- init cache
    repository._CACHE = repository._CACHE or {}
    repository._CACHE[position] = cache(position .. ".repository")

    -- ok
    return repository._CACHE[position]
end

-- get the local or global package directory
function repository.directory(is_global)

    -- get directory
    if is_global then
        return path.join(global.directory(), "repositories")
    else
        return path.join(config.directory(), "repositories")
    end
end

-- get repository url from the given name
function repository.get(name, is_global)

    -- get it
    local repositories = repository.repositories(is_global)
    if repositories then
        return repositories[name]
    end
end

-- add repository url to the given name
function repository.add(name, url, is_global)

    -- no name?
    if not name then
        return false, string.format("please set name to repository: %s", url)
    end

    -- get repositories
    local repositories = repository.repositories(is_global) or {}

    -- set it
    repositories[name] = url

    -- save repositories
    repository._cache(is_global):set("repositories", repositories)

    -- flush it
    return repository._cache(is_global):flush()
end

-- remove repository from gobal or local directory
function repository.remove(name, is_global)

    -- get repositories
    local repositories = repository.repositories(is_global) or {} 
    if not repositories[name] then
        return false, string.format("repository(%s): not found!", name)
    end

    -- remove it
    repositories[name] = nil

    -- save repositories
    repository._cache(is_global):set("repositories", repositories)

    -- flush it
    return repository._cache(is_global):flush()
end

-- clear all repositories
function repository.clear(is_global)

    -- clear repositories
    repository._cache(is_global):set("repositories", {})

    -- flush it
    return repository._cache(is_global):flush()
end


-- get all repositories from global or local directory
function repository.repositories(is_global)

    -- get repositories
    return repository._cache(is_global):get("repositories")
end

-- return module
return repository
