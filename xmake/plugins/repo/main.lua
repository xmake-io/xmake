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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("core.package.repository")

-- add repository url
function _add(name, url, global)

    -- add it
    repository.add(name, url, global)

    -- trace
    cprint("${bright}add %s repository(%s): %s ok!", ifelse(global, "global", "local"), name, url)
end

-- remove repository url
function _remove(name, global)

    -- remove it
    repository.remove(name, global)

    -- trace
    cprint("${bright}remove %s repository(%s): %s ok!", ifelse(global, "global", "local"), name, url)
end

-- clear all repositories
function _clear(global)

    -- clear all
    repository.clear(global)

    -- trace
    cprint("${bright}clear %s repositories: ok!", ifelse(global, "global", "local"))
end

-- list all repositories
function _list(global)

    -- trace
    print("%s repositories:", ifelse(global, "global", "local"))

    -- list all
    local count = 0
    for _, repo in pairs(repository.repositories(global)) do

        -- trace
        print("    %s %s", repo.name, repo.url)

        -- update count
        count = count + 1
    end

    -- trace
    print("%d repositories were found!", count)
end

-- load project
function _load_project()

    -- enter project directory
    os.cd(project.directory())

    -- load config
    config.load()

    -- load platform
    platform.load(config.plat())

    -- load project
    project.load()
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

    -- clear all repositories
    elseif option.get("clear") then

        _clear(option.get("global"))

    -- list all repositories
    elseif option.get("list") then

        _list(option.get("global"))

    -- show help
    else
        option.show_help()
    end
end

