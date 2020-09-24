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
local sandbox_core_package_repository = sandbox_core_package_repository or {}

-- load modules
local global        = require("base/global")
local project       = require("project/project")
local repository    = require("package/repository")
local raise         = require("sandbox/modules/raise")
local import        = require("sandbox/modules/import")

-- get repository directory
function sandbox_core_package_repository.directory(is_global)
    return repository.directory(is_global)
end

-- get repository url from the given name
function sandbox_core_package_repository.get(name, is_global)
    return repository.get(name, is_global)
end

-- add repository url to the given name
function sandbox_core_package_repository.add(name, url, branch, is_global)

    -- add it
    local ok, errors = repository.add(name, url, branch, is_global)
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

    -- add main global xmake repository
    local repositories = {}
    if is_global and global.get("network") ~= "private" then

        -- import fasturl
        import("net.fasturl")

        -- sort main urls
        local mainurls = {"https://github.com/xmake-io/xmake-repo.git", "https://gitlab.com/tboox/xmake-repo.git", "https://gitee.com/tboox/xmake-repo.git"}
        fasturl.add(mainurls)
        mainurls = fasturl.sort(mainurls)

        -- add main url
        if #mainurls > 0 then
            local repo = repository.load("xmake-repo", mainurls[1], "master", true)
            if repo then
                table.insert(repositories, repo)
            end
        end
    end

    -- load repositories from repository cache
    for name, repoinfo in pairs(table.wrap(repository.repositories(is_global))) do
        local url = repoinfo
        local branch = nil
        if type(repoinfo) == "table" then
            url = repoinfo[1]
            branch = repoinfo[2]
        end
        local repo = repository.load(name, url, branch, is_global)
        if repo then
            table.insert(repositories, repo)
        end
    end

    -- load repositories from project file
    --
    -- in project xmake.lua:
    --
    --     add_repositories("other-repo https://github.com/other/other-repo.git dev")
    --
    if not is_global then
        for _, repo in ipairs(table.wrap(project.get("repositories"))) do
            local repoinfo = repo:split('%s')
            if #repoinfo <= 3 then
                local repo = repository.load(repoinfo[1], repoinfo[2], repoinfo[3], is_global)
                if repo then
                    table.insert(repositories, repo)
                end
            else
                raise("invalid repository: %s", repo)
            end
        end
    end

    -- load repository from builtin program directory
    if is_global then
        local repo = repository.load("builtin-repo", path.join(os.programdir(), "repository"), nil, true)
        if repo then
            table.insert(repositories, repo)
        end
    end

    -- get the repositories
    return repositories
end

-- return module
return sandbox_core_package_repository
