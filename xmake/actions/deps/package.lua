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
import("core.tool.git")
import("core.base.semver")
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
-- add_requires("tboox.tbox >=1.5.1 <1.6.0 optional")
--
function _parse_require(require_str)

    -- split package and version info
    local splitinfo = require_str:split('%s+')
    assert(splitinfo and #splitinfo > 0, "require(\"%s\"): invalid!", require_str)

    -- get package info
    local packageinfo = splitinfo[1]

    -- get mode at last position
    --
    -- .e.g
    --
    -- must
    -- optional
    --
    local mode = "must"
    if #splitinfo > 1 then

        -- get mode
        local modes = {must = true, optional = true}
        local value = splitinfo[#splitinfo]:lower()
        if modes[value] then
            mode = value
            table.remove(splitinfo)
        end
    end

    -- get version
    --
    -- .e.g 
    -- 
    -- >=1.5.1 <1.6.0  
    -- master || >1.4
    -- ~1.2.3
    -- ^1.1
    --
    local version = "master"
    if #splitinfo > 1 then
        version = table.concat(table.slice(splitinfo, 2), " ")
    end
    assert(version, "require(\"%s\"): unknown version!", require_str)

    -- get repository name, package name and package url
    local reponame    = nil
    local packageurl  = nil
    local packagename = nil
    local pos = packageinfo:find_last('@', true)
    if pos then

        -- get package name
        packagename = packageinfo:sub(pos + 1)

        -- get reponame or packageurl
        local repo_or_pkgurl = packageinfo:sub(1, pos - 1)

        -- is package url?
        if repo_or_pkgurl:find('[/\\]') then
            packageurl = repo_or_pkgurl
        else
            reponame = repo_or_pkgurl
        end
    else 
        packagename = packageinfo
    end

    -- check package name
    assert(packagename, "require(\"%s\"): the package name not found!", require_str)

    -- ok
    return packagename, {reponame = reponame, packageurl = packageurl, version = version, mode = mode}
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

-- load package instance from the given package url
function _load_package_from_url(packagename, packageurl)

    -- load it
    return package.load_from_url(packagename, packageurl)
end

-- load package instance from project
function _load_package_from_project(packagename)

    -- load it
    return package.load_from_project(packagename)
end

-- load package instance from repositories
function _load_package_from_repository(packagename, reponame)

    -- get package directory from the given package name
    local packagedir = repository.packagedir(packagename, reponame)
    if packagedir then
        -- load it
        return package.load_from_repository(packagename, packagedir)
    end
end

-- select package version
function _select_package_version(package, required_ver)

    -- get package url    
    local url = package:get("url")
    assert(url, "package(%s): url not found!", package:name())

    -- is git url?
    local is_giturl = git.checkurl(url)

    -- get versions
    local versions = package:get("versions") 

    -- attempt to get tags and branches from the git url
    local tags = nil
    local branches = nil
    if is_giturl then
        tags, branches = git.refs(url) 
    end

    -- check
    assert(versions or tags or branches, "cannot get versions or refs from package(%s)!", package:name())

    -- select required version
    return semver.select(required_ver, versions, tags, branches)
end

-- load all required packages
function load_packages()

    -- load packages
    local packages = {}
    for packagename, requireinfo in pairs(_load_requires()) do

        -- load package instance
        local instance = nil
        if requireinfo.packageurl then
            -- load package from the given package url
            instance = _load_package_from_url(packagename, requireinfo.packageurl)
        else
            -- load package from project first
            instance = _load_package_from_project(packagename)
            if not instance then
                -- load package from repositories
                instance = _load_package_from_repository(packagename, requireinfo.reponame)
            end
        end

        -- check
        assert(instance, "package(%s) not found!", packagename)

        -- select package version
        local version, kind = _select_package_version(instance, requireinfo.version)

        -- save this package instance
        table.insert(packages, instance)
    end

    -- ok
    return packages
end

