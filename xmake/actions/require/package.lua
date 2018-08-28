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
-- @file        package.lua
--

-- imports
import("core.base.semver")
import("core.base.option")
import("core.base.global")
import("core.project.cache")
import("core.project.project")
import("core.package.package", {alias = "core_package"})
import("action")
import("devel.git")
import("net.fasturl")
import("repository")

--
-- parse require string
--
-- add_requires("tbox >=1.5.1", "zlib >=1.2.11")
-- add_requires("zlib master")
-- add_requires("xmake-repo@tbox >=1.5.1") 
-- add_requires("https://github.com/tboox/tbox.git@tboox.tbox >=1.5.1") 
-- add_requires("tbox >=1.5.1 <1.6.0", {optional = true, alias = "tbox"})
--
function _parse_require(require_str, requires_extra, parentinfo)

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

    -- get version
    --
    -- .e.g 
    -- 
    -- lastest
    -- >=1.5.1 <1.6.0  
    -- master || >1.4
    -- ~1.2.3
    -- ^1.1
    --
    local version = "lastest"
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

    -- get require extra
    local require_extra = {}
    if requires_extra then
        require_extra = requires_extra[require_str] or {}
    end

    -- init required item
    local required = {}
    parentinfo = parentinfo or {}
    required.packagename = packagename
    required.requireinfo =
    {
        originstr        = require_str,
        reponame         = reponame,
        packageurl       = packageurl,
        version          = version,
        alias            = require_extra.alias,     -- set package alias name
        system           = require_extra.system,    -- default: true, we can set it to disable system package manually
        option           = require_extra.option,    -- set and attach option
        default          = require_extra.default,   -- default: true, we can set it to disable package manually
        optional         = parentinfo.optional or require_extra.optional -- default: false, inherit parentinfo.optional
    }

    -- save this required item to cache
    requires[require_str] = required
    _g._REQUIRES = requires

    -- ok
    return required.packagename, required.requireinfo
end

-- load package package from the given package url
function _load_package_from_url(packagename, packageurl)
    return core_package.load_from_url(packagename, packageurl)
end

-- load package package from system
function _load_package_from_system(packagename)
    return core_package.load_from_system(packagename)
end

-- load package package from project
function _load_package_from_project(packagename)
    return core_package.load_from_project(packagename)
end

-- load package package from repositories
function _load_package_from_repository(packagename, reponame)

    -- get package directory from the given package name
    local packagedir, repo = repository.packagedir(packagename, reponame)
    if packagedir then
        -- load it
        return core_package.load_from_repository(packagename, repo, packagedir)
    end
end

-- load required packages
function _load_package(packagename, requireinfo)

    -- attempt to get it from cache first
    local packages = _g._PACKAGES or {}
    local package = packages[packagename]
    if package then

        -- satisfy required version? 
        local version_str = package:version_str()
        if version_str and not semver.satisfies(version_str, requireinfo.version) then
            raise("package(%s): version conflict, '%s' does not satisfy '%s'!", packagename, version_str, requireinfo.version)
        end

        -- ok
        return package
    end

    -- load package package
    package = nil
    if requireinfo.packageurl then
        -- load package from the given package url
        package = _load_package_from_url(packagename, requireinfo.packageurl)
    else
        -- load package from project first
        package = _load_package_from_project(packagename)
            
        -- load package from repositories
        if not package then
            package = _load_package_from_repository(packagename, requireinfo.reponame)
        end

        -- load package from system
        if not package then
            package = _load_package_from_system(packagename)
        end
    end

    -- check
    assert(package, "package(%s) not found!", packagename)

    -- save require info to package
    package:requireinfo_set(requireinfo)

    -- save this package package to cache
    packages[packagename] = package
    _g._PACKAGES = packages

    -- ok
    return package
end

-- search package package from project
function _search_package_from_project(name)
--    return core_package.search_from_project(name)
end

-- search package package from repositories
function _search_package_from_repository(name)

    -- search package directories from the given package name
    local packages = {}
    for _, packageinfo in ipairs(repository.searchdirs(name)) do
        local package = core_package.load_from_repository(packageinfo.name, packageinfo.repo, packageinfo.packagedir)
        if package then
            table.insert(packages, package)
        end
    end

    -- ok?
    return packages
end

-- search package from the project and repositories
function _search_package(name)

    -- search package from project first
    local packages = _search_package_from_project(name)
        
    -- search package from repositories
    if not packages or #packages == 0 then
        packages = _search_package_from_repository(name)
    end

    -- ok?
    return packages
end

-- sort package deps
--
-- .e.g 
--
-- a.deps = b
-- b.deps = c
--
-- orderdeps: c -> b -> a
--
function _sort_packagedeps(package)
    local orderdeps = {}
    for _, dep in pairs(package:deps()) do
        table.join2(orderdeps, _sort_packagedeps(dep))
        table.insert(orderdeps, dep) 
    end
    return orderdeps
end

-- load all required packages
function _load_packages(requires, requires_extra, parentinfo)

    -- no requires?
    if not requires or #requires == 0 then
        return {}
    end

    -- load packages
    local packages = {}
    for packagename, requireinfo in pairs(load_requires(requires, requires_extra, parentinfo)) do

        -- attempt to get project option about this package
        local packageopt = project.option(packagename)
        if packageopt == nil or packageopt:enabled() then -- this package is enabled?

            -- load package package
            local package = _load_package(packagename, requireinfo)

            -- maybe package not found and optional
            if package then

                -- load dependent packages and save them first of this package
                local deps = package:get("deps")
                if deps then
                    local packagedeps = {}
                    for _, dep in ipairs(_load_packages(deps, package:get("__extra_deps"), requireinfo)) do
                        table.insert(packages, dep)
                        packagedeps[dep:name()] = dep
                    end
                    package._DEPS = packagedeps
                    package._ORDERDEPS = table.unique(_sort_packagedeps(package))
                end

                -- save this package package
                table.insert(packages, package)
            end
        end
    end

    -- ok?
    return packages
end

-- sort packages urls
function _sort_packages_urls(packages)

    -- add all urls to fasturl and prepare to sort them together
    for _, package in ipairs(packages) do
        fasturl.add(package:urls())
    end

    -- sort and update urls
    for _, package in ipairs(packages) do
        package:urls_set(fasturl.sort(package:urls()))
    end
end

-- select packages version
function _select_packages_version(packages)

    -- sort and update urls
    for _, package in ipairs(packages) do

        -- exists urls? otherwise be phony package (only as package group)
        if #package:urls() > 0 then

            -- has git url?
            local has_giturl = false
            for _, url in ipairs(package:urls()) do
                if git.checkurl(url) then
                    has_giturl = true
                    break
                end
            end

            -- select package version
            local source = nil
            local version = nil
            local require_version = package:requireinfo().version
            if require_version == "lastest" or require_version:find('.', 1, true) then -- select version?
                version, source = semver.select(require_version, package:versions())
            elseif has_giturl then -- select branch?
                version, source = require_version, "branches"
            else
                raise("package(%s %s): not found!", package:name(), require_version)
            end

            -- save version to package
            package:version_set(version, source)
        end
    end
end

-- get user confirm
function _get_confirm(packages)

    -- init confirmed packages
    local confirmed_packages = {}
    for _, package in ipairs(packages) do
        if (option.get("force") or not package:exists()) and (#package:urls() > 0 or package:script("install")) then 
            table.insert(confirmed_packages, package)
        end
    end
    if #confirmed_packages == 0 then
        return true
    end

    -- get confirm
    local confirm = option.get("yes")
    if confirm == nil then
    
        -- show tips
        cprint("${bright yellow}note: ${default yellow}try installing these packages (pass -y to skip confirm)?")
        for _, package in ipairs(confirmed_packages) do
            print("  -> %s %s", package:name(), package:version_str() or "")
        end
        cprint("please input: y (y/n)")

        -- get answer
        io.flush()
        local answer = io.read()
        if answer == 'y' or answer == '' then
            confirm = true
        end
    end

    -- ok?
    return confirm
end

-- the cache directory
function cachedir()
    return path.join(global.directory(), "cache", "packages")
end

-- load requires
function load_requires(requires, requires_extra, parentinfo)

    -- parse requires
    local requireinfos = {}
    for _, require_str in ipairs(requires) do

        -- parse require info
        local packagename, requireinfo = _parse_require(require_str, requires_extra, parentinfo)

        -- save this required package
        requireinfos[packagename] = requireinfo
    end

    -- ok
    return requireinfos
end

-- load all required packages
function load_packages(requires, requires_extra)

    -- laod all required packages recursively
    local packages = _load_packages(requires, requires_extra)

    -- sort package urls
    _sort_packages_urls(packages)

    -- select packages version
    _select_packages_version(packages)

    -- ok
    return packages
end

-- install packages
function install_packages(requires, requires_extra)

    -- load packages
    local packages = load_packages(requires, requires_extra)

    -- fetch packages from local first
    local packages_remote = {}
    if option.get("force") then 
        for _, package in ipairs(packages) do
            if package and #package:urls() > 0 then
                table.insert(packages_remote, package)
            end
        end
    else
        process.runjobs(function (index)
            local package = packages[index]
            if package and not package:fetch() and #package:urls() > 0 then -- @note fetch first for only system packge 
                table.insert(packages_remote, package)
            end
        end, #packages)
    end

    -- get user confirm
    if not _get_confirm(packages) then
        return 
    end

    -- download remote packages
    local waitindex = 0
    local waitchars = {'\\', '|', '/', '-'}
    process.runjobs(function (index)

        local package = packages_remote[index]
        if package then
            action.download(package)
        end

    end, #packages_remote, ifelse(option.get("verbose"), 1, 4), 300, function (indices) 

        -- do not print progress info if be verbose 
        if option.get("verbose") then
            return 
        end
 
        -- update waitchar index
        waitindex = ((waitindex + 1) % #waitchars)

        -- make downloading packages list
        local downloading = {}
        for _, index in ipairs(indices) do
            local package = packages_remote[index]
            if package then
                table.insert(downloading, package:name())
            end
        end
       
        -- trace
        cprintf("\r${yellow}  => ${clear}downloading %s .. %s", table.concat(downloading, ", "), waitchars[waitindex + 1])
        io.flush()
    end)

    -- install all required packages from repositories
    for _, package in ipairs(packages) do
        if (option.get("force") or not package:exists()) and (#package:urls() > 0 or package:script("install")) then 
            action.install(package)
        end
    end

    -- ok
    return packages
end

-- search packages
function search_packages(names)

    -- search all names
    local results = {}
    for _, name in ipairs(names) do
        local packages = _search_package(name)
        if packages then
            results[name] = packages
        end
    end
    return results
end
