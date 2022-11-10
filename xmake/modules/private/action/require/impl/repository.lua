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
import("net.proxy")

-- get package directory from the locked repository
function _get_packagedir_from_locked_repo(packagename, locked_repo)

    -- find global repository directory
    local repo_global
    for _, repo in ipairs(repositories()) do
        if locked_repo.url == repo:url() and locked_repo.branch == repo:branch() then
            repo_global = repo
            break
        end
    end
    local reponame = hash.uuid(locked_repo.url):gsub("%-", ""):lower() .. ".lock"

    -- get local repodir
    local repodir_local
    if os.isdir(locked_repo.url) then
        repodir_local = locked_repo.url
    elseif not locked_repo.commit and repo_global then
        repodir_local = repo_global:directory()
    else
        repodir_local = path.join(config.directory(), "repositories", reponame)
    end

    -- clone repository to local
    local lastcommit
    if not os.isdir(repodir_local) then
        if repo_global then
            git.clone(repo_global:directory(), {verbose = option.get("verbose"), outputdir = repodir_local})
            lastcommit = repo_global:commit()
        elseif global.get("network") ~= "private" then
            local remoteurl = proxy.mirror(locked_repo.url) or locked_repo.url
            git.clone(remoteurl, {verbose = option.get("verbose"), branch = locked_repo.branch, outputdir = repodir_local})
        else
            wprint("we cannot lock repository(%s) in private network mode!", locked_repo.url)
            return
        end
    end

    -- lock commit
    local ok
    if locked_repo.commit and os.isdir(path.join(repodir_local, ".git")) then
        lastcommit = lastcommit or try {function()
            return git.lastcommit({repodir = repodir_local})
        end}
        if locked_repo.commit ~= lastcommit then
            -- try checkout to the given commit
            ok = try {function () git.checkout(locked_repo.commit, {verbose = option.get("verbose"), repodir = repodir_local}); return true end}
            if not ok then
                if global.get("network") ~= "private" then
                    -- pull the latest commit
                    local remoteurl = proxy.mirror(locked_repo.url) or locked_repo.url
                    git.pull({verbose = option.get("verbose"), remote = remoteurl, branch = locked_repo.branch, repodir = repodir_local})
                    -- re-checkout to the given commit
                    ok = try {function () git.checkout(locked_repo.commit, {verbose = option.get("verbose"), repodir = repodir_local}); return true end}
                else
                    wprint("we cannot lock repository(%s) in private network mode!", locked_repo.url)
                    return
                end
            end
        else
            ok = true
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
            if not os.isdir(repo:url()) then
                -- repository not found? or xmake has been re-installed
                local repodir = repo:directory()
                local updatefile = path.join(repodir, "updated")
                if not os.isfile(updatefile) or (os.isfile(updatefile) and os.mtime(os.programfile()) > os.mtime(updatefile)) then
                    -- fix broken empty directory
                    -- @see https://github.com/xmake-io/xmake/issues/2159
                    if os.isdir(repodir) and os.emptydir(repodir) then
                        os.tryrm(repodir)
                    end
                    return false
                end
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
        cachekey = cachekey .. locked_repo.url .. (locked_repo.commit or "") .. (locked_repo.branch or "")
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
            foundir = _get_packagedir_from_locked_repo(packagename, locked_repo)
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
        foundir = foundir or {}
        packagedirs[cachekey] = foundir
    end

    -- save the current commit
    local dir  = foundir[1]
    local repo = foundir[2]
    if repo and not repo:commit() then
        local lastcommit = try {function()
            if os.isdir(path.join(repo:directory(), ".git")) then
                return git.lastcommit({repodir = repo:directory()})
            end
        end}
        repo:commit_set(lastcommit)
    end
    return dir, repo
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

