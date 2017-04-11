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
import("core.package.package")
import("repository")

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

--
-- parse require string
--
-- add_requires("tboox.tbox >=1.5.1", "zlib >=1.2.11")
-- add_requires("zlib master")
-- add_requires("xmake-repo@tboox.tbox >=1.5.1")
-- add_requires("https://github.com/tboox/tbox.git@tboox.tbox >=1.5.1")
--
function _parse_require(require_str)

    -- split package and version info
    local splitinfo = require_str:split(' ')
    assert(splitinfo and #splitinfo == 2, "invalid require(\"%s\")", require_str)

    -- get package info
    local packageinfo = splitinfo[1]

    -- get version info
    local versioninfo = splitinfo[2]

    -- get repository name, package name and package url
    local reponame    = nil
    local packageurl  = nil
    local packagename = nil
    splitinfo = packageinfo:split('@')
    if splitinfo and #splitinfo == 2 then

        -- is package url?
        if splitinfo[1]:find('[/\\]') then
            packageurl = splitinfo[1]
        else
            reponame = splitinfo[1]
        end

        -- get package name
        packagename = splitinfo[2]
    else 
        packagename = packageinfo
    end

    -- ok
    return {reponame = reponame, packagename = packagename, packageurl = packageurl, versioninfo = versioninfo}
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

-- install and update all outdated package dependencies
function _install(is_global)

    -- TODO need optimization
    -- pull all local and global repositories first
    repository.pull(false)
    repository.pull(true)

    -- parse requires
    local requires = {}
    for _, require_str in ipairs(project.requires()) do
        table.insert(requires, _parse_require(require_str))
    end

    table.dump(requires)
end

-- clear all installed packages cache
function _clear(is_global)
    -- TODO
end

-- search for the given packages from repositories
function _search(packages)
    -- TODO
end

-- show the given package info
function _info(packages)
    -- TODO
end

-- list all package dependencies
function _list()
    -- TODO
end

-- main
function main()

    -- load project first
    _load_project()

    -- install and update all outdated package dependencies
    if option.get("install") then

        _install(option.get("global"))

    -- clear all installed packages cache
    elseif option.get("clear") then

        _clear(option.get("global"))

    -- search for the given packages from repositories
    elseif option.get("search") then

        _search(option.get("packages"))

    -- show the given package info
    elseif option.get("info") then

        _info(option.get("packages"))

    -- list all package dependencies
    elseif option.get("list") then

        _list()

    -- install and update all outdated package dependencies by default if no arguments
    else
        _install(option.get("global"))
    end
end

