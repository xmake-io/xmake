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
import("core.base.semver")
import("core.base.option")
import("core.base.global")
import("core.project.cache")
import("core.project.project")
import("core.package.package", {alias = "core_package"})
import("devel.git")
import("net.fasturl")
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

    -- get it from cache first
    local requires = _g._REQUIRES or {}
    local required = requires[require_str]
    if required then
        return required.packagename, required.requireinfo
    end

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

    -- init required item
    local required = {}
    required.packagename = packagename
    required.requireinfo = {reponame = reponame, packageurl = packageurl, version = version, mode = mode}

    -- save this required item to cache
    requires[require_str] = required
    _g._REQUIRES = requires

    -- ok
    return required.packagename, required.requireinfo
end

-- load package instance from the given package url
function _load_package_from_url(packagename, packageurl)

    -- load it
    return core_package.load_from_url(packagename, packageurl)
end

-- load package instance from project
function _load_package_from_project(packagename)

    -- load it
    return core_package.load_from_project(packagename)
end

-- load package instance from repositories
function _load_package_from_repository(packagename, reponame)

    -- get package directory from the given package name
    local packagedir, is_global = repository.packagedir(packagename, reponame)
    if packagedir then
        -- load it
        return core_package.load_from_repository(packagename, is_global, packagedir)
    end
end

-- load required packages
function _load_package(packagename, requireinfo)

    -- attempt to get it from cache first
    local packages = _g._PACKAGES or {}
    local instance = packages[packagename]
    if instance then

        -- satisfy required version? 
        if not semver.satisfies(instance:version(), requireinfo.version) then
            raise("package(%s): version conflict, '%s' does not satisfy '%s'!", packagename, instance:version(), requireinfo.version)
        end

        -- ok
        return instance
    end

    -- load package instance
    instance = nil
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

    -- save require info to package
    instance:requireinfo_set(requireinfo)

    -- save this package instance to cache
    packages[packagename] = instance
    _g._PACKAGES = packages

    -- ok
    return instance
end

-- load all required packages
function _load_packages(requires)

    -- no requires?
    if not requires or #requires == 0 then
        return {}
    end

    -- load packages
    local packages = {}
    for packagename, requireinfo in pairs(load_requires(requires)) do

        -- load package instance
        local package = _load_package(packagename, requireinfo)

        -- load required packages and save them first of this package
        requires = package:get("requires")
        if requires then
            table.join2(packages, _load_packages(requires))
        end

        -- save this package instance
        table.insert(packages, package)
    end

    -- ok?
    return packages
end

-- load all git refs from packages
function _load_packages_gitrefs(packages)

    -- enter cache scope
    cache.enter("local.require")

    -- load cache
    local gitrefs = nil
    if option.get("force") then
        gitrefs = {}
    else
        gitrefs = cache.get("gitrefs") or {}
    end

    -- run tasks
    local results = {}
    process.runjobs(function (index)
        local package = packages[index]
        if package then

            -- attempt to get refs from cache first
            local refs = gitrefs[package:name()]
            if refs then
                results[package:name()] = {tags = refs.tags, branches = refs.branches}
            else
                -- attempt to get refs from the git url
                local tags = {}
                local branches = {}
                for _, url in ipairs(package:urls()) do
                    if git.checkurl(url) then
                        
                        -- fetch refs
                        tags, branches = git.refs(url) 

                        -- save result
                        results[package:name()] = {tags = tags, branches = branches}

                        -- cache result
                        gitrefs[package:name()] = {tags = tags, branches = branches}
                        break
                    end
                end
            end
        end
    end, #packages)

    -- save cache
    cache.set("gitrefs", gitrefs)
    cache.flush()

    -- ok?
    return results
end

-- select package version
function _select_package_version(package, required_ver, gitrefs)

    -- get versions
    local versions = package:get("versions") 

    -- attempt to get tags and branches from the git url
    local refs = {}
    if gitrefs then
        refs = gitrefs[package:name()] or {}
    end

    -- select required version
    return semver.select(required_ver, versions, refs.tags, refs.branches)
end

-- the cache directory
function cachedir()
    return path.join(global.directory(), "cache", "packages")
end

-- load requires
function load_requires(requires)

    -- parse requires
    local requireinfos = {}
    for _, require_str in ipairs(requires) do

        -- parse require info
        local packagename, requireinfo = _parse_require(require_str)

        -- save this required package
        requireinfos[packagename] = requireinfo
    end

    -- ok
    return requireinfos
end

-- load all required packages
function load_packages(requires)

    -- laod all required packages recursively
    local packages = _load_packages(requires)

    -- add all urls to fasturl and prepare to sort them together
    for _, package in ipairs(packages) do
        fasturl.add(package:urls())
    end

    -- load git refs from packages
    local gitrefs = _load_packages_gitrefs(packages)

    -- sort and update urls
    for _, package in ipairs(packages) do

        -- sort package urls
        package:urls_set(fasturl.sort(package:urls()))

        -- exists urls? otherwise be phony package (only as package group)
        if #package:urls() > 0 then

            -- select package version
            local version, source = _select_package_version(package, package:requireinfo().version, gitrefs)

            -- save version to package
            package:version_set(version, source)
        end
    end

    -- ok
    return packages
end

