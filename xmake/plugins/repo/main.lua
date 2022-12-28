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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("core.package.repository")
import("devel.git")
import("net.proxy")
import("private.async.runjobs")
import("private.action.require.impl.environment")

function _clear_quick_search_cache(is_global)
    if is_global then
        import("private.xrepo.quick_search.cache")
        cache.clear()
    end
end

-- add repository url
function _add(name, url, branch, is_global)

    -- remove previous repository if exists
    local repodir = path.join(repository.directory(is_global), name)
    if os.isdir(repodir) then
        os.rmdir(repodir)
    end

    -- enter environment
    environment.enter()

    -- clone repository
    if not os.isdir(url) then
        local remoteurl = proxy.mirror(url) or url
        git.clone(remoteurl, {verbose = option.get("verbose"), branch = branch, outputdir = repodir})
    end

    -- add url
    repository.add(name, url, branch, is_global)

    -- trace
    cprint("${color.success}add %s repository(%s): %s%s ok!", (is_global and "global" or "local"), name, url, branch and (" " .. branch) or "")

    -- leave environment
    environment.leave()

    -- clear quick search cache
    _clear_quick_search_cache(is_global)
end

-- remove repository url
function _remove(name, is_global)

    -- remove url
    repository.remove(name, is_global)

    -- remove repository
    local repodir = path.join(repository.directory(is_global), name)
    if os.isdir(repodir) then
        os.rmdir(repodir)
    end

    -- clear quick search cache
    _clear_quick_search_cache(is_global)

    -- trace
    cprint("${bright}remove %s repository(%s): ok!", (is_global and "global" or "local"), name)

end

-- update repositories
function _update()

    -- enter environment
    environment.enter()

    -- trace
    printf("updating repositories .. ")
    if option.get("verbose") then
        print("")
    end

    -- create a pull task
    local task = function ()

        -- get all repositories (local first)
        local repos = table.join(repository.repositories(false), repository.repositories(true))

        -- pull all repositories
        local pulled = {}
        for _, repo in ipairs(repos) do
            local repodir = repo:directory()
            if not pulled[repodir] then
                if os.isdir(repodir) then
                    -- only update the local repository with the remote url
                    if not os.isdir(repo:url()) then
                        vprint("pulling repository(%s): %s to %s ..", repo:name(), repo:url(), repodir)
                        git.pull({verbose = option.get("verbose"), branch = repo:branch(), repodir = repodir})
                        io.save(path.join(repodir, "updated"), {})
                    end
                else
                    vprint("cloning repository(%s): %s to %s ..", repo:name(), repo:url(), repodir)
                    local remoteurl = proxy.mirror(repo:url()) or repo:url()
                    git.clone(remoteurl, {verbose = option.get("verbose"), branch = repo:branch(), outputdir = repodir})
                    io.save(path.join(repodir, "updated"), {})
                end
                pulled[repodir] = true
            end
        end

        -- clear quick search cache
        _clear_quick_search_cache(true)
    end

    -- pull repositories
    if option.get("verbose") then
        task()
    else
        runjobs("update repo", task, {progress = true, isolate = true})
    end

    -- leave environment
    environment.leave()

    -- trace
    cprint("${green}ok")
end

-- clear all repositories
function _clear(is_global)

    -- clear all urls
    repository.clear(is_global)

    -- remove all repositories
    local repodir = repository.directory(is_global)
    if os.isdir(repodir) then
        os.rmdir(repodir)
    end

    -- clear quick search cache
    _clear_quick_search_cache(is_global)

    -- trace
    cprint("${color.success}clear %s repositories: ok!", (is_global and "global" or "local"))
end

-- list all repositories
function _list(is_global)

    -- list all repositories
    local count = 0
    for _, position in ipairs(is_global and "global" or {"local", "global"}) do

        -- trace
        print("%s repositories:", position)

        -- list all
        for _, repo in pairs(repository.repositories(position == "global")) do

            -- trace
            local description = repo:get("description")
            print("    %s %s%s %s", repo:name(), repo:url(), repo:branch() and (" " .. repo:branch()) or "", description and ("(" .. description .. ")") or "")

            -- update count
            count = count + 1
        end

        -- trace
        print("")
    end

    -- trace
    print("%d repositories were found!", count)
end

-- get the repository directory
function _directory(is_global)
    print(repository.directory(is_global))
end

-- load project
function _load_project()

    -- enter project directory
    os.cd(project.directory())

    -- load config
    config.load()

    -- load platform
    platform.load(config.plat())
end

-- main
function main()

    -- load project if operate local repositories
    if not option.get("global") then
        _load_project()
    end

    -- add repository url
    if option.get("add") then

        _add(option.get("name"), option.get("url"), option.get("branch"), option.get("global"))

    -- remove repository url
    elseif option.get("remove") then

        _remove(option.get("name"), option.get("global"))

    -- update repository url
    elseif option.get("update") then

        _update()

    -- clear all repositories
    elseif option.get("clear") then

        _clear(option.get("global"))

    -- list all repositories
    elseif option.get("list") then

        _list(option.get("global"))

    -- show repo directory
    else
        _directory(option.get("global"))
    end
end

