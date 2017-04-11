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
-- @file        package.lua
--

-- imports
import("core.project.project")
import("core.package.package")
import("repository")

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
    assert(splitinfo and #splitinfo == 2, "require(\"%s\"): invalid!", require_str)

    -- get package info
    local packageinfo = splitinfo[1]

    -- get version 
    local version = splitinfo[2]

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

    -- check package name
    assert(packagename, "require(\"%s\"): the package name not found!", require_str)

    -- ok
    return packagename, {reponame = reponame, packageurl = packageurl, version = version}
end

-- load requires
function _load_requires()

    -- parse requires
    local requires = {}
    for _, require_str in ipairs(project.requires()) do

        -- parse require info
        local packagename, packageinfo = _parse_require(require_str)

        -- save this required package
        requires[packagename] = packageinfo
    end

    -- ok
    return requires
end

-- load package info from repositories
function _load_packageinfo_from_repo(packagename, requireinfo)

    -- get package directory from repositories
    local packagedir = repository.packagedir(packagename, requireinfo.reponame)

    -- TODO
    print(packagedir)

    return {}
end

-- create a new package info from the given package url
function _create_packageinfo_from_url(pacakgename, requireinfo)
    -- TODO
    return {}
end

-- load all required packages
function load_packages()

    -- load requires
    for packagename, requireinfo in pairs(_load_requires()) do

        -- load package info
        local packageinfo = nil
        if requireinfo.packageurl then
            -- create a new package from the given package url
            packageinfo = _create_packageinfo_from_url(packagename, requireinfo)
        else
            -- load package info from repositories
            packageinfo = _load_packageinfo_from_repo(packagename, requireinfo)
        end
    end

    -- ok
    return {}
end

