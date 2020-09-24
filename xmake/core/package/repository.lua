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

-- define module
local repository = repository or {}
local _instance = _instance or {}

-- load modules
local utils       = require("base/utils")
local string      = require("base/string")
local global      = require("base/global")
local cache       = require("project/cache")
local config      = require("project/config")
local interpreter = require("base/interpreter")

-- new an instance
function _instance.new(name, url, branch, directory, is_global)

    -- new an instance
    local instance = table.inherit(_instance)

    -- init instance
    instance._NAME      = name
    instance._URL       = url
    instance._BRANCH    = branch
    instance._DIRECTORY = directory
    instance._IS_GLOBAL = is_global

    -- ok
    return instance
end

-- get the repository configure
function _instance:get(name)

    -- load info
    local info = self:load()

    -- get if from info
    local value = info and info[name] or nil
    if value ~= nil then
        return value
    end
end

-- get the repository name
function _instance:name()
    return self._NAME
end

-- get the repository url
function _instance:url()
    return self._URL
end

-- get the repository branch
function _instance:branch()
    return self._BRANCH
end

-- is global repository?
function _instance:is_global()
    return self._IS_GLOBAL
end

-- get the repository directory
function _instance:directory()
    return self._DIRECTORY
end

-- load the repository info in xmake.lua
function _instance:load()

    -- do not loaded?
    if not self._INFO then

        -- attempt to load info from the repository script (xmake.lua)
        local scriptpath = path.join(self:directory(), "xmake.lua")
        if os.isfile(scriptpath) then

            -- get interpreter
            local interp = repository._interpreter()

            -- load script
            local ok, errors = interp:load(scriptpath)
            if not ok then
                os.raise("load repo(%s) failed, " .. errors, self:name())
            end

            -- load repository and disable filter
            local results, errors = interp:make(nil, true, false)
            if not results then
                os.raise("load repo(%s) failed, " .. errors, self:name())
            end

            -- save repository info
            self._INFO = results
        end
    end
    return self._INFO
end

-- get cache
function repository._cache(is_global)

    -- get position
    local position = is_global and "global" or "local"

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

-- the interpreter
function repository._interpreter()

    -- the interpreter has been initialized? return it directly
    if repository._INTERPRETER then
        return repository._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)

    -- define apis
    interp:api_define(repository.apis())

    -- save interpreter
    repository._INTERPRETER = interp

    -- ok?
    return interp
end

-- get repository apis
function repository.apis()

    return
    {
        values =
        {
            -- set_xxx
            "set_description"
        }
    }
end

-- get the local or global repository directory
function repository.directory(is_global)

    -- get directory
    if is_global then
        return path.join(global.directory(), "repositories")
    else
        return path.join(config.directory(), "repositories")
    end
end

-- load the repository
function repository.load(name, url, branch, is_global)

    -- check url
    if not url then
        return nil, string.format("invalid repo(%s): url not found!", name)
    end

    -- get it directly from cache first
    repository._REPOS = repository._REPOS or {}
    if repository._REPOS[name] then
        return repository._REPOS[name]
    end

    -- the repository directory
    local repodir = os.isdir(url) and url or path.join(repository.directory(is_global), name)

    -- new an instance
    local instance, errors = _instance.new(name, url, branch, repodir, is_global)
    if not instance then
        return nil, errors
    end

    -- save instance to the cache
    repository._REPOS[name] = instance

    -- ok
    return instance
end

-- get repository url from the given name
function repository.get(name, is_global)

    -- get it
    local repositories = repository.repositories(is_global)
    if repositories then
        local repoinfo = repositories[name]
        if type(repoinfo) == "table" then
            return repoinfo[1], repoinfo[2]
        else
            return repoinfo
        end
    end
end

-- add repository url to the given name
function repository.add(name, url, branch, is_global)

    -- no name?
    if not name then
        return false, string.format("please set name to repository: %s", url)
    end

    -- get repositories
    local repositories = repository.repositories(is_global) or {}

    -- set it
    repositories[name] = {url, branch}

    -- save repositories
    repository._cache(is_global):set("repositories", repositories)

    -- flush it
    repository._cache(is_global):flush()
    return true
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
    repository._cache(is_global):flush()
    return true
end

-- clear all repositories
function repository.clear(is_global)

    -- clear repositories
    repository._cache(is_global):set("repositories", {})

    -- flush it
    repository._cache(is_global):flush()
    return true
end


-- get all repositories from global or local directory
function repository.repositories(is_global)
    return repository._cache(is_global):get("repositories")
end

-- return module
return repository
