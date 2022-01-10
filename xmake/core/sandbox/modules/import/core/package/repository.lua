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
-- @author      ruki
-- @file        repository.lua
--

-- define module
local sandbox_core_package_repository = sandbox_core_package_repository or {}

-- load modules
local global        = require("base/global")
local project       = require("project/project")
local localcache    = require("cache/localcache")
local repository    = require("package/repository")
local raise         = require("sandbox/modules/raise")
local import        = require("sandbox/modules/import")

-- inherit some builtin interfaces
sandbox_core_package_repository.directory = repository.directory
sandbox_core_package_repository.get       = repository.get
sandbox_core_package_repository.load      = repository.load

-- add repository url to the given name
function sandbox_core_package_repository.add(name, url, branch, is_global)
    local ok, errors = repository.add(name, url, branch, is_global)
    if not ok then
        raise(errors)
    end
end

-- remove repository from gobal or local directory
function sandbox_core_package_repository.remove(name, is_global)
    local ok, errors = repository.remove(name, is_global)
    if not ok then
        raise(errors)
    end
end

-- clear all repositories from global or local directory
function sandbox_core_package_repository.clear(is_global)
    local ok, errors = repository.clear(is_global)
    if not ok then
        raise(errors)
    end
end

-- get all repositories from global or local directory
function sandbox_core_package_repository.repositories(is_global)

    -- load repositories from repository cache
    local repositories = {}
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
    --     add_repositories("other-repo dirname", {rootdir = os.scriptdir()})
    --
    if not is_global then
        for _, repo in ipairs(table.wrap(project.get("repositories"))) do
            local repoinfo = repo:split('%s')
            if #repoinfo <= 3 then
                local name    = repoinfo[1]
                local url     = repoinfo[2]
                local branch  = repoinfo[3]
                local rootdir = project.extraconf("repositories", repo, "rootdir")
                if url and rootdir and not path.is_absolute(url) and not url:find(":", 1, true) then
                    url = path.join(rootdir, url)
                end
                local repo = repository.load(name, url, branch, is_global)
                if repo then
                    table.insert(repositories, repo)
                end
            else
                raise("invalid repository: %s", repo)
            end
        end
    end

    -- add global xmake repositories
    if is_global then

        -- add artifacts urls
        local artifacts_urls = localcache.cache("repository"):get("artifacts_urls")
        if not artifacts_urls then
            local binary_repo = os.getenv("XMAKE_BINARY_REPO")
            if binary_repo then
                artifacts_urls = {binary_repo}
            else
                artifacts_urls = {"https://github.com/xmake-mirror/build-artifacts.git",
                                  "https://gitlab.com/xmake-mirror/build-artifacts.git",
                                  "https://gitee.com/xmake-mirror/build-artifacts.git"}
                if global.get("network") ~= "private" then
                    import("net.fasturl")
                    fasturl.add(artifacts_urls)
                    artifacts_urls = fasturl.sort(artifacts_urls)
                    localcache.cache("repository"):set("artifacts_urls", artifacts_urls)
                    localcache.cache("repository"):save()
                end
            end
        end
        if #artifacts_urls > 0 then
            local repo = repository.load("build-artifacts", artifacts_urls[1], "main", true)
            if repo then
                table.insert(repositories, repo)
            end
        end

        -- add main urls
        local mainurls = localcache.cache("repository"):get("mainurls")
        if not mainurls then
            local mainrepo = os.getenv("XMAKE_MAIN_REPO")
            if mainrepo then
                mainurls = {mainrepo}
            else
                mainurls = {"https://github.com/xmake-io/xmake-repo.git",
                            "https://gitlab.com/tboox/xmake-repo.git",
                            "https://gitee.com/tboox/xmake-repo.git"}
                if global.get("network") ~= "private" then
                    import("net.fasturl")
                    fasturl.add(mainurls)
                    mainurls = fasturl.sort(mainurls)
                    localcache.cache("repository"):set("mainurls", mainurls)
                    localcache.cache("repository"):save()
                end
            end
        end
        if #mainurls > 0 then
            local repo = repository.load("xmake-repo", mainurls[1], "master", true)
            if repo then
                table.insert(repositories, repo)
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

