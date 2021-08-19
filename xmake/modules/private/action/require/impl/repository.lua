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

-- imports
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.package.repository")
import("devel.git")

-- get package directory from the locked repository
function _get_packagedir_from_locked_repo(packagename, locked_repo)
    print(packagename, locked_repo)

    -- find global repository directory
    local repodir_global
    for _, repo in ipairs(repositories()) do
        if locked_repo.url == repo:url() and locked_repo.branch == repo:branch() then
            repodir_global = repo:directory()
            break
        end
    end

    -- clone repository to local
    local reponame = path.basename(locked_repo.url)
    local repodir_local = path.join(config.directory(), "repositories", reponame)
    if not os.isdir(repodir_local) then
        if repodir_global then
            git.clone(repodir_global, {verbose = option.get("verbose"), outputdir = repodir_local})
        elseif global.get("network") ~= "private" then
            git.clone(locked_repo.url, {verbose = option.get("verbose"), branch = locked_repo.branch, outputdir = repodir_local})
        else
            wprint("we cannot lock repository(%s) in private network mode!", locked_repo.url)
            return
        end
    end

    -- try checkout to the given commit
    local ok = try {function () git.checkout(locked_repo.commit, {verbose = option.get("verbose"), repodir = repodir_local}); return true end}
    if not ok then
        if global.get("network") ~= "private" then
            -- pull the latest commit
            git.pull({verbose = option.get("verbose"), branch = locked_repo.branch, repodir = repodir_local})
            -- re-checkout to the given commit
            ok = try {function () git.checkout(locked_repo.commit, {verbose = option.get("verbose"), repodir = repodir_local}); return true end}
        else
            wprint("we cannot lock repository(%s) in private network mode!", locked_repo.url)
            return
        end
    end

    -- find package directory
    local foundir
    if ok then
        local dir = path.join(repodir_local, "packages", packagename:sub(1, 1), packagename)
        if os.isdir(dir) and os.isfile(path.join(dir, "xmake.lua")) then
            local repo = repository.load(reponame, locked_repo.url, locked_repo.branch, false)
            foundir = {dir, repo}
            vprint("lock package(%s) in %s from repository(%s)/%s", packagename, dir, locked_repo.url, locked_repo.commit)
        end
    end
    return foundir
end

-- get all repositories
function repositories()
    if _g._REPOSITORIES then
        return _g._REPOSITORIES
    end
    -- get all repositories (local first)
    local repos = table.join(repository.repositories(false), repository.repositories(true))
    _g._REPOSITORIES = repos
    return repos
end

-- the remote repositories have been pulled?
function pulled()
    if global.get("network") ~= "private" then
        for _, repo in ipairs(repositories()) do
            -- repository not found? or xmake has been re-installed
            local updatefile = path.join(repo:directory(), "updated")
            if not os.isdir(repo:directory()) or (os.isfile(updatefile) and os.mtime(os.programfile()) > os.mtime(updatefile)) then
                return false
            end
        end
    end
    return true
end

-- get package directory from repositories
function packagedir(packagename, opt)

    -- strip trailng ~tag, e.g. zlib~debug
    opt = opt or {}
    packagename = packagename:lower()
    if packagename:find('~', 1, true) then
        packagename = packagename:gsub("~.+$", "")
    end

    -- get cache key
    local reponame = opt.name
    local cachekey = packagename
    local locked_repo = opt.locked_repo
    if locked_repo then
        cachekey = cachekey .. locked_repo.url .. locked_repo.commit .. (locked_repo.branch or "")
    end
    local packagedirs = _g._PACKAGEDIRS
    if not packagedirs then
        packagedirs = {}
        _g._PACKAGEDIRS = packagedirs
    end

    -- get the package directory
    local foundir = packagedirs[cachekey]
    if not foundir then

        -- find the package directory from the locked repository
        if locked_repo then
            local dir, repo = _get_packagedir_from_locked_repo(packagename, locked_repo)
            if dir and repo then
                foundir = {dir, repo}
            end
        end

        -- find the package directory from repositories
        if not foundir then
            for _, repo in ipairs(repositories()) do
                local dir = path.join(repo:directory(), "packages", packagename:sub(1, 1), packagename)
                if os.isdir(dir) and os.isfile(path.join(dir, "xmake.lua")) and (not reponame or reponame == repo:name()) then
                    foundir = {dir, repo}
                    break
                end
            end
        end
        packagedirs[cachekey] = foundir or {}
    end
    return foundir[1], foundir[2]
end

-- get artifacts manifest from repositories
function artifacts_manifest(packagename, version)
    packagename = packagename:lower()
    for _, repo in ipairs(repositories()) do
        local manifestfile = path.join(repo:directory(), "packages", packagename:sub(1, 1), packagename, version, "manifest.txt")
        if os.isfile(manifestfile) then
            return io.load(manifestfile)
        end
    end
end

-- search package directories from repositories
function searchdirs(name)

    -- find the package directories from all repositories
    local unique = {}
    local packageinfos = {}
    for _, repo in ipairs(repositories()) do
        for _, file in ipairs(os.files(path.join(repo:directory(), "packages", "*", string.ipattern("*" .. name .. "*"), "xmake.lua"))) do
            local dir = path.directory(file)
            local subdirname = path.basename(path.directory(dir))
            if #subdirname == 1 then -- ignore l/luajit/port/xmake.lua
                local packagename = path.basename(dir)
                if not unique[packagename] then
                    table.insert(packageinfos, {name = packagename, repo = repo, packagedir = path.directory(file)})
                    unique[packagename] = true
                end
            end
        end
    end
    return packageinfos
end

