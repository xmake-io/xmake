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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("core.package.repository")
import("devel.git")
import("actions.require.environment", {rootdir = os.programdir()})

-- add repository url
function _add(name, url, is_global)

    -- add url
    repository.add(name, url, is_global)

    -- remove previous repository if exists
    local repodir = path.join(repository.directory(is_global), name)
    if os.isdir(repodir) then
        os.rmdir(repodir)
    end

    -- enter environment 
    environment.enter()

    -- clone repository
    git.clone(url, {verbose = option.get("verbose"), branch = "master", outputdir = repodir})

    -- trace
    cprint("${bright}add %s repository(%s): %s ok!", ifelse(is_global, "global", "local"), name, url)

    -- leave environment 
    environment.leave()
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

    -- trace
    cprint("${bright}remove %s repository(%s): ok!", ifelse(is_global, "global", "local"), name)
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

            -- the repository directory
            local repodir = repo:directory()

            -- remove repeat and only pull the first repository
            if not pulled[repodir] then
                if os.isdir(repodir) then
                    
                    -- update the local repository with the remote url
                    if not os.isdir(repo:url()) then

                        -- trace
                        vprint("pulling repository(%s): %s to %s ..", repo:name(), repo:url(), repodir)

                        -- pull it
                        git.pull({verbose = option.get("verbose"), branch = "master", repodir = repodir})
                    end
                else
                    -- trace
                    vprint("cloning repository(%s): %s to %s ..", repo:name(), repo:url(), repodir)

                    -- clone it
                    git.clone(repo:url(), {verbose = option.get("verbose"), branch = "master", outputdir = repodir})
                end

                -- pull this repository ok
                pulled[repodir] = true
            end
        end
    end
 
    -- pull repositories
    if option.get("verbose") then
        task()
    else
        process.asyncrun(task)
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

    -- trace
    cprint("${bright}clear %s repositories: ok!", ifelse(is_global, "global", "local"))
end

-- list all repositories
function _list()

    -- list all repositories
    local count = 0
    for _, position in ipairs({"local", "global"}) do

        -- trace
        print("%s repositories:", position)

        -- list all
        for _, repo in pairs(repository.repositories(position == "global")) do

            -- trace
            local description = repo:get("description")
            print("    %s %s %s", repo:name(), repo:url(), description and ("(" .. description .. ")") or "")

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

        _add(option.get("name"), option.get("url"), option.get("global"))

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

        _list()

    -- show repo directory
    else
        _directory(option.get("global"))
    end
end

