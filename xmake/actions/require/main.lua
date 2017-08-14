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
import("core.base.task")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("list")
import("info")
import("clear")
import("search")
import("install")

--
-- the default repositories:
--     xmake-repo https://github.com/tboox/xmake-repo.git
--
-- add other repositories:
--     xmake repo --add other-repo https://github.com/other/other-repo.git
-- or
--     add_repositories("other-repo https://github.com/other/other-repo.git")
--
-- add requires:
--
--     add_requires("tboox.tbox >=1.5.1", "zlib >=1.2.11")
--     add_requires("zlib master")
--     add_requires("xmake-repo@tboox.tbox >=1.5.1")
--     add_requires("https://github.com/tboox/tbox.git@tboox.tbox >=1.5.1")
--
-- add package dependencies:
--
--     target("test")
--         add_packages("tboox.tbox", "zlib")
--

-- load project
function _load_project()

    -- config it first
    task.run("config")

    -- enter project directory
    os.cd(project.directory())
end

-- main
function main()

    -- load project first
    _load_project()

    -- clear all installed packages cache
    if option.get("clear") then

        clear(option.get("global"))

    -- search for the given packages from repositories
    elseif option.get("search") then

        search(option.get("packages"))

    -- show the given package info
    elseif option.get("info") then

        info(option.get("packages"))

    -- list all package dependencies
    elseif option.get("list") then

        list()

    -- install and update all outdated package dependencies by default if no arguments
    else
        install(option.get("requires"))
    end
end

