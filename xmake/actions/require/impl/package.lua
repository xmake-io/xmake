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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        package.lua
--

-- imports
import("core.base.semver")
import("core.base.option")
import("core.base.global")
import("core.base.hashset")
import("core.base.scheduler")
import("core.base.tty")
import("private.async.runjobs")
import("private.utils.progress")
import("lib.detect.cache", {alias = "detectcache"})
import("core.project.project")
import("core.package.package", {alias = "core_package"})
import("actions.install", {alias = "action_install"})
import("actions.download", {alias = "action_download"})
import("devel.git")
import("net.fasturl")
import("repository")

--
-- parse require string
--
-- basic
-- - add_requires("zlib")
--
-- semver
-- - add_requires("tbox >=1.5.1", "zlib >=1.2.11")
--
-- git branch/tag
-- - add_requires("zlib master")
--
-- with the given repository
-- - add_requires("xmake-repo@tbox >=1.5.1")
--
-- with the given configs
-- - add_requires("aaa_bbb_ccc >=1.5.1 <1.6.0", {optional = true, alias = "mypkg", debug = true})
-- - add_requires("tbox", {config = {coroutine = true, abc = "xxx"}})
--
-- with namespace and the 3rd package manager
-- - add_requires("xmake::xmake-repo@tbox >=1.5.1")
-- - add_requires("vcpkg::ffmpeg")
-- - add_requires("conan::OpenSSL/1.0.2n@conan/stable")
-- - add_requires("conan::openssl/1.1.1g") -- new
-- - add_requires("brew::pcre2/libpcre2-8 10.x", {alias = "pcre2"})
--
-- clone as a standalone package with the different configs
-- we can install and use these three packages at the same time.
-- - add_requires("zlib")
-- - add_requires("zlib~debug", {debug = true})
-- - add_requires("zlib~shared", {configs = {shared = true}, alias = "zlib_shared"})
--
-- {system = nil/true/false}:
--   nil: get local or system packages
--   true: only get system package
--   false: only get local packages
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
    -- e.g.
    --
    -- latest
    -- >=1.5.1 <1.6.0
    -- master || >1.4
    -- ~1.2.3
    -- ^1.1
    --
    local version = "latest"
    if #splitinfo > 1 then
        version = table.concat(table.slice(splitinfo, 2), " ")
    end
    assert(version, "require(\"%s\"): unknown version!", require_str)

    -- require third-party packages? e.g. brew::pcre2/libpcre2-8
    local reponame    = nil
    local packagename = nil
    if require_str:find("::", 1, true) then
        packagename = packageinfo
    else

        -- get repository name, package name and package url
        local pos = packageinfo:lastof('@', true)
        if pos then

            -- get package name
            packagename = packageinfo:sub(pos + 1)

            -- get reponame
            reponame = packageinfo:sub(1, pos - 1)
        else
            packagename = packageinfo
        end
    end

    -- check package name
    assert(packagename, "require(\"%s\"): the package name not found!", require_str)

    -- get require extra
    local require_extra = {}
    if requires_extra then
        require_extra = requires_extra[require_str] or {}
    end

    -- get required building configurations
    local require_build_configs = require_extra.configs or require_extra.config
    if require_extra.debug then
        require_build_configs = require_build_configs or {}
        require_build_configs.debug = true
    end

    -- require packge in the current host platform
    if require_extra.host then
        require_extra.plat = os.host()
        require_extra.arch = os.arch()
    end

    -- init required item
    local required = {}
    parentinfo = parentinfo or {}
    required.packagename = packagename
    required.requireinfo =
    {
        originstr        = require_str,
        reponame         = reponame,
        version          = version,
        plat             = require_extra.plat,      -- require package in the given platform
        arch             = require_extra.arch,      -- require package in the given architecture
        kind             = require_extra.kind,      -- default: library, set package kind, e.g. binary, library, we can set `kind = "binary"` to only detect binary program and ignore library.
        alias            = require_extra.alias,     -- set package alias name
        group            = require_extra.group,     -- only uses the first package in same group
        system           = require_extra.system,    -- default: true, we can set it to disable system package manually
        option           = require_extra.option,    -- set and attach option
        configs          = require_build_configs,   -- the required building configurations
        default          = require_extra.default,   -- default: true, we can set it to disable package manually
        optional         = parentinfo.optional or require_extra.optional -- default: false, inherit parentinfo.optional
    }

    -- save this required item to cache
    requires[require_str] = required
    _g._REQUIRES = requires

    -- ok
    return required.packagename, required.requireinfo
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
    local packagedir, repo = repository.packagedir(packagename, reponame)
    if packagedir then
        return core_package.load_from_repository(packagename, repo, packagedir)
    end
end

-- search packages from repositories
function _search_packages(name)

    local packages = {}
    for _, packageinfo in ipairs(repository.searchdirs(name)) do
        local package = core_package.load_from_repository(packageinfo.name, packageinfo.repo, packageinfo.packagedir)
        if package then
            table.insert(packages, package)
        end
    end
    return packages
end

-- sort package deps
--
-- e.g.
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

-- add some builtin configurations to package
function _add_package_configurations(package)
    package:add("configs", "debug", {builtin = true, description = "Enable debug symbols.", default = false, type = "boolean"})
    package:add("configs", "shared", {builtin = true, description = "Enable shared library.", default = false, type = "boolean"})
    package:add("configs", "cflags", {builtin = true, description = "Set the C compiler flags."})
    package:add("configs", "cxflags", {builtin = true, description = "Set the C/C++ compiler flags."})
    package:add("configs", "cxxflags", {builtin = true, description = "Set the C++ compiler flags."})
    package:add("configs", "asflags", {builtin = true, description = "Set the assembler flags."})
    package:add("configs", "vs_runtime", {builtin = true, description = "Set vs compiler runtime.", default = "MT", values = {"MT", "MD"}})
end

-- select package version
function _select_package_version(package, requireinfo)

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
        local require_version = requireinfo.version
        if #package:versions() > 0 and (require_version == "latest" or require_version:find('.', 1, true)) then -- select version?
            version, source = semver.select(require_version, package:versions())
        elseif has_giturl then -- select branch?
            version, source = require_version ~= "latest" and require_version or "master", "branches"
        elseif not package:get("versions") and semver.is_valid(require_version) then
            -- no version list in package()? try this version directly
            -- @see https://github.com/xmake-io/xmake/issues/930
            version = require_version
            source = "versions"
        else
            raise("package(%s %s): not found!", package:name(), require_version)
        end
        return version, source
    end
end

-- check the configurations of packages
--
-- package("pcre2")
--      add_configs("bitwidth", {description = "Set the code unit width.", default = "8", values = {"8", "16", "32"}})
--      add_configs("bitwidth", {type = "number", values = {8, 16, 32}})
--      add_configs("bitwidth", {restrict = function(value) if tonumber(value) < 100 then return true end})
--
function _check_package_configurations(package)
    local configs_defined = {}
    for _, name in ipairs(package:get("configs")) do
        configs_defined[name] = package:extraconf("configs", name) or {}
    end
    for name, value in pairs(package:configs()) do
        local conf = configs_defined[name]
        if conf then
            local config_type = conf.type or "string"
            if type(value) ~= config_type then
                raise("package(%s %s): invalid type(%s) for config(%s), need type(%s)!", package:name(), package:version_str(), type(value), name, config_type)
            end
            if conf.values then
                local found = false
                for _, config_value in ipairs(conf.values) do
                    if tostring(value) == tostring(config_value) then
                        found = true
                        break
                    end
                end
                if not found then
                    raise("package(%s %s): invalid value(%s) for config(%s), please run `xmake require --info %s` to get all valid values!", package:name(), package:version_str(), value, name, package:name())
                end
            end
            if conf.restrict then
                if not conf.restrict(value) then
                    raise("package(%s %s): invalid value(%s) for config(%s)!", package:name(), package:version_str(), value, name)
                end
            end
        else
            raise("package(%s %s): invalid config(%s), please run `xmake require --info %s` to get all configurations!", package:name(), package:version_str(), name, package:name())
        end
    end
end

-- load required packages
function _load_package(packagename, requireinfo, opt)

    -- attempt to get it from cache first
    opt = opt or {}
    local packages = _g._PACKAGES or {}
    local package = packages[packagename]
    if package then

        -- satisfy required version?
        local version_required = _select_package_version(package, requireinfo)
        if version_required and version_required ~= package:version_str() then
            raise("package(%s): version conflict, '%s' does not satisfy '%s'!", packagename, package:version_str(), requireinfo.version)
        end
        return package
    end

    -- load package from project first
    if os.isfile(os.projectfile()) then
        package = _load_package_from_project(packagename)
    end

    -- load package from repositories
    if not package then
        package = _load_package_from_repository(packagename, requireinfo.reponame)
    end

    -- load package from system
    if not package and opt.system ~= false then
        package = _load_package_from_system(packagename)
    end

    -- check
    assert(package, "package(%s) not found!", packagename)

    -- select package version
    local version, source = _select_package_version(package, requireinfo)
    if version then
        package:version_set(version, source)
    end

    -- save require info to package
    package:requireinfo_set(requireinfo)

    -- add some builtin configurations to package
    _add_package_configurations(package)

    -- check package configurations
    _check_package_configurations(package)

    -- do load for package
    local on_load = package:script("load")
    if on_load then
        on_load(package)
    end

    -- load environments from the manifest to enable the environments of on_install()
    package:envs_load()

    -- save this package package to cache
    packages[packagename] = package
    _g._PACKAGES = packages
    return package
end

-- load all required packages
function _load_packages(requires, opt)

    -- no requires?
    if not requires or #requires == 0 then
        return {}
    end

    -- load packages
    local packages = {}
    for _, requireinfo in ipairs(load_requires(requires, opt.requires_extra, opt.parentinfo)) do

        -- load package
        local package = _load_package(requireinfo.name, requireinfo.info, opt)

        -- maybe package not found and optional
        if package then

            -- load dependent packages and save them first of this package
            if not package._DEPS then
                local deps = package:get("deps")
                if deps and opt.nodeps ~= true then

                    -- get the extra configs dependent packages and inherit some builtin configs
                    local extraconfs = package:extraconf("deps") or {}
                    if not package:config("shared") then
                        for _, depstr in ipairs(deps) do
                            local depconf = extraconfs[depstr]
                            if not depconf then
                                depconf = {}
                                extraconfs[depstr] = depconf
                            end
                            depconf.configs = depconf.configs or {}
                            if depconf.configs.vs_runtime == nil then
                                depconf.configs.vs_runtime = package:config("vs_runtime")
                            end
                        end
                    end

                    -- load dependent packages and do not load system packages for package/deps()
                    local packagedeps = {}
                    for _, dep in ipairs(_load_packages(deps, {requires_extra = extraconfs, parentinfo = requireinfo.info, nodeps = opt.nodeps, system = false})) do
                        dep:parents_add(package)
                        table.insert(packages, dep)
                        packagedeps[dep:name()] = dep
                    end
                    package._DEPS = packagedeps
                    package._ORDERDEPS = table.unique(_sort_packagedeps(package))
                end
            end

            -- save this package package
            table.insert(packages, package)
        end
    end
    return packages
end

-- sort packages urls
function _sort_packages_urls(packages)

    -- add all urls to fasturl and prepare to sort them together
    for _, package in pairs(packages) do
        fasturl.add(package:urls())
    end

    -- sort and update urls
    for _, package in pairs(packages) do
        package:urls_set(fasturl.sort(package:urls()))
    end
end

-- get package status string
function _get_package_status_str(package)
    local status = {}
    if package:debug() then
        table.insert(status, "debug")
    end
    if package:optional() then
        table.insert(status, "optional")
    end
    return #status > 0 and "(" .. table.concat(status, ", ") .. ")" or ""
end

-- get user confirm
function _get_confirm(packages)

    -- no confirmed packages?
    if #packages == 0 then
        return true
    end

    -- get confirm
    local confirm = utils.confirm({default = true, description = function ()

        -- get packages for each repositories
        local packages_repo = {}
        local packages_group = {}
        for _, package in ipairs(packages) do
            -- achive packages by repository
            local reponame = package:repo() and package:repo():name() or (package:isSys() and "system" or "")
            if package:is3rd() then
                reponame = package:name():lower():split("::")[1]
            end
            packages_repo[reponame] = packages_repo[reponame] or {}
            table.insert(packages_repo[reponame], package)

            -- achive packages by group
            local group = package:group()
            if group then
                packages_group[group] = packages_group[group] or {}
                table.insert(packages_group[group], package)
            end
        end

        -- show tips
        cprint("${bright color.warning}note: ${clear}try installing these packages (pass -y to skip confirm)?")
        for reponame, packages in pairs(packages_repo) do
            if reponame ~= "" then
                print("in %s:", reponame)
            end
            local packages_showed = {}
            for _, package in ipairs(packages) do
                if not packages_showed[tostring(package)] then
                    local group = package:group()
                    if group and packages_group[group] and #packages_group[group] > 1 then
                        for idx, package_in_group in ipairs(packages_group[group]) do
                            cprint("  ${yellow}%s${clear} %s %s %s", idx == 1 and "->" or "   or", package_in_group:name(), package_in_group:version_str() or "", _get_package_status_str(package_in_group))
                            packages_showed[tostring(package_in_group)] = true
                        end
                        packages_group[group] = nil
                    else
                        cprint("  ${yellow}->${clear} %s %s %s", package:name(), package:version_str() or "", _get_package_status_str(package))
                        packages_showed[tostring(package)] = true
                    end
                end
            end
        end
    end})
    return confirm
end

-- patch some builtin dependent packages
function _patch_packages(packages_install, packages_download)

    -- @NOTE use git.apply instead of patch
    -- we can add some builtin packages like this
    --[[
    -- add package(patch)
    local patched_package = nil
    for _, package in ipairs(packages_install) do
        if package:patches() then
            patched_package = package
            break
        end
    end
    if patched_package then
        local packages = load_packages("patch")
        if packages and #packages > 0 then
            -- install patch package
            local package = packages[1]
            if not package:fetch() then
                packages_download[tostring(package)] = package
                table.insert(packages_install, 1, package)
            end
            -- add dependences to ensure to be installed first
            patched_package:deps_add(package)
        end
    end
    ]]
end

-- install packages
function _install_packages(packages_install, packages_download)

    -- we need hide wait characters if is not a tty
    local show_wait = io.isatty()

    -- do install
    local progress_helper = show_wait and progress.new() or nil
    local packages_installing = {}
    local packages_downloading = {}
    local packages_pending = table.copy(packages_install)
    local packages_in_group = {}
    local installing_count = 0
    local parallelize = true
    runjobs("install_packages", function (index)

        -- fetch a new package
        local package = nil
        while package == nil and #packages_pending > 0 do
            for idx, pkg in ipairs(packages_pending) do

                -- all dependences has been installed? we install it now
                local ready = true
                for _, dep in ipairs(pkg:orderdeps()) do
                    if not dep:exists() then
                        ready = false
                    end
                end
                local group = pkg:group()
                if ready and group then
                    -- this group has been installed? skip it
                    local group_status = packages_in_group[group]
                    if group_status == 1 then
                        table.remove(packages_pending, idx)
                        break
                    -- this group is installing? wait it
                    elseif group_status == 0 then
                        ready = false
                    end
                end

                -- get a package with the ready status
                if ready then
                    package = pkg
                    table.remove(packages_pending, idx)
                    break
                end
            end
            if package == nil and #packages_pending > 0 then
                scheduler.co_yield()
            end
        end
        if package then

            -- only install the first package in same group
            local group = package:group()
            if not group or not packages_in_group[group] then

                -- disable parallelize?
                if not package:parallelize() then
                    parallelize = false
                end
                if not parallelize then
                    while installing_count > 0 do
                        scheduler.co_yield()
                    end
                end
                installing_count = installing_count + 1

                -- mark this group as 'installing'
                if group then
                    packages_in_group[group] = 0
                end

                -- download this package first
                local downloaded = true
                if packages_download[tostring(package)] then
                    packages_downloading[index] = package
                    downloaded = action_download(package)
                    packages_downloading[index] = nil
                end

                -- install this package
                packages_installing[index] = package
                if downloaded then
                    action_install(package)
                end
                packages_installing[index] = nil

                -- mark this group as 'installed' or 'failed'
                if group then
                    packages_in_group[group] = package:exists() and 1 or -1
                end

                -- enable parallelize
                parallelize = true
                installing_count = installing_count - 1
            end
        end
        packages_installing[index] = nil
        packages_downloading[index] = nil

    end, {total = #packages_install, comax = (option.get("verbose") or option.get("diagnosis")) and 1 or 4, on_timer = function (running_jobs_indices)

        -- do not print progress info if be verbose
        if option.get("verbose") or not show_wait then
            return
        end

        -- make installing and downloading packages list
        local installing = {}
        local downloading = {}
        for _, index in ipairs(running_jobs_indices) do
            local package = packages_installing[index]
            if package then
                table.insert(installing, package:name())
            end
            local package = packages_downloading[index]
            if package then
                table.insert(downloading, package:name())
            end
        end

        -- get waitobjs tips
        local tips = nil
        local waitobjs = scheduler.co_group_waitobjs("install_packages")
        if waitobjs:size() > 0 then
            local names = {}
            for _, obj in waitobjs:keys() do
                if obj:otype() == scheduler.OT_PROC then
                    table.insert(names, obj:name())
                elseif obj:otype() == scheduler.OT_SOCK then
                    table.insert(names, "sock")
                elseif obj:otype() == scheduler.OT_PIPE then
                    table.insert(names, "pipe")
                end
            end
            names = table.unique(names)
            if #names > 0 then
                names = table.concat(names, ",")
                if #names > 16 then
                    names = names:sub(1, 16) .. ".."
                end
                tips = string.format("(%d/%s)", waitobjs:size(), names)
            end
        end

        -- trace
        progress_helper:clear()
        tty.erase_line_to_start().cr()
        cprintf("${yellow}  => ")
        if #downloading > 0 then
            cprintf("downloading ${magenta}%s", table.concat(downloading, ", "))
        end
        if #installing > 0 then
            cprintf("%sinstalling ${magenta}%s", #downloading > 0 and ", " or "", table.concat(installing, ", "))
        end
        cprintf(" .. %s", tips and ("${dim}" .. tips .. "${clear} ") or "")
        progress_helper:write()
    end, exit = function(errors)
        if errors then
            tty.erase_line_to_start().cr()
            io.flush()
        end
    end})
end

-- the cache directory
function cachedir()
    return path.join(global.directory(), "cache", "packages")
end

-- load requires
function load_requires(requires, requires_extra, parentinfo)
    local requireinfos = {}
    for _, require_str in ipairs(requires) do
        local packagename, requireinfo = _parse_require(require_str, requires_extra, parentinfo)
        table.insert(requireinfos, {name = packagename, info = requireinfo})
    end
    return requireinfos
end

-- load all required packages
function load_packages(requires, opt)
    opt = opt or {}
    local unique = {}
    local packages = {}
    for _, package in ipairs(_load_packages(requires, opt)) do
        -- remove repeat packages with same the package name and version
        local key = package:name() .. (package:version_str() or "")
        if not unique[key] then
            table.insert(packages, package)
            unique[key] = true
        end
    end
    return packages
end

-- install packages
function install_packages(requires, opt)

    -- init options
    opt = opt or {}

    -- load packages
    local packages = load_packages(requires, opt)

    -- fetch packages (with system) from local first
    runjobs("fetch_packages", function (index)
        local package = packages[index]
        if package and (not option.get("force") or (option.get("shallow") and package:parents())) then
            package:envs_enter()
            package:fetch()
            package:envs_leave()
        end
    end, {total = #packages})

    -- filter packages
    local packages_install = {}
    local packages_download = {}
    local packages_unsupported = {}
    for _, package in ipairs(packages) do
        if not package:exists() and (#package:urls() > 0 or package:script("install")) then
            if package:supported() then
                if #package:urls() > 0 then
                    packages_download[tostring(package)] = package
                end
                table.insert(packages_install, package)
            elseif not package:optional() then
                table.insert(packages_unsupported, package)
            end
        end
    end

    -- exists unsupported packages?
    if #packages_unsupported > 0 then
        -- show tips
        cprint("${bright color.warning}note: ${clear}the following packages are unsupported for $(plat)/$(arch)!")
        for _, package in ipairs(packages_unsupported) do
            print("  -> %s %s", package:name(), package:version_str() or "")
        end
        raise()
    end

    -- patch some dependent builtin packages
    _patch_packages(packages_install, packages_download)

    -- get user confirm
    if not _get_confirm(packages_install) then
        local packages_must = {}
        for _, package in ipairs(packages_install) do
            if not package:optional() then
                table.insert(packages_must, package:name())
            end
        end
        if #packages_must > 0 then
            raise("packages(%s): must be installed!", table.concat(packages_must, ", "))
        else
            -- continue other actions
            return
        end
    end

    -- sort package urls
    _sort_packages_urls(packages_download)

    -- install all required packages from repositories
    _install_packages(packages_install, packages_download)

    -- ok
    return packages
end

-- uninstall packages
function uninstall_packages(requires, opt)

    -- init options
    opt = opt or {}

    -- do not remove dependent packages
    opt.nodeps = true

    -- clear the detect cache
    detectcache.clear()

    -- remove all packages
    local packages = {}
    for _, instance in ipairs(load_packages(requires, opt)) do
        if os.isfile(instance:manifest_file()) then
            table.insert(packages, instance)
        end
        os.tryrm(instance:installdir())
    end
    return packages
end

-- export packages
function export_packages(requires, opt)

    -- init options
    opt = opt or {}

    -- get the export directory
    local exportdir = assert(opt.exportdir)

    -- export all packages
    local packages = {}
    for _, instance in ipairs(load_packages(requires, opt)) do

        -- get the exported name
        local name = instance:name():lower():gsub("::", "_")
        if instance:version_str() then
            name = name .. "_" .. instance:version_str()
        end
        name = name .. "_" .. instance:buildhash()

        -- export this package
        os.cp(instance:installdir(), path.join(exportdir, name))
        table.insert(packages, instance)
    end
    return packages
end

-- search packages
function search_packages(names)

    -- search all names
    local results = {}
    for _, name in ipairs(names) do
        local packages = _search_packages(name)
        if packages then
            results[name] = packages
        end
    end
    return results
end
