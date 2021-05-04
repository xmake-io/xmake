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
-- @file        package.lua
--

-- imports
import("core.base.semver")
import("core.base.option")
import("core.base.global")
import("private.async.runjobs")
import("private.utils.progress")
import("core.cache.memcache")
import("core.project.project")
import("core.package.package", {alias = "core_package"})
import("devel.git")
import("private.action.require.impl.repository")

-- get memcache
function _memcache()
    return memcache.cache("require.impl.package")
end

--
-- parse require string
--
-- basic
-- - add_requires("zlib")
--
-- semver
-- - add_requires("tbox >=1.5.1", "zlib >=1.2.11")
-- - add_requires("tbox", {version = ">=1.5.1"})
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
-- - add_requires("zlib~label1")
-- - add_requires("zlib", {label = "label2"})
--
-- private package, only for installation, do not export any links/includes and environments to target
-- - add_requires("zlib", {private = true})
--
-- {system = nil/true/false}:
--   nil: get remote or system packages
--   true: only get system package
--   false: only get remote packages
--
--
function _parse_require(require_str)

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
            packagename = packageinfo:sub(pos + 1)
            reponame = packageinfo:sub(1, pos - 1)
        else
            packagename = packageinfo
        end
    end

    -- check package name
    assert(packagename, "require(\"%s\"): the package name not found!", require_str)
    return packagename, version, reponame
end

-- load require info
function _load_require(require_str, requires_extra, parentinfo)

    -- parse require
    local packagename, version, reponame = _parse_require(require_str)

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
        version          = require_extra.version or version,
        plat             = require_extra.plat,      -- require package in the given platform
        arch             = require_extra.arch,      -- require package in the given architecture
        targetos         = require_extra.targetos,  -- require package in the given target os
        kind             = require_extra.kind,      -- default: library, set package kind, e.g. binary, library, we can set `kind = "binary"` to only detect binary program and ignore library.
        alias            = require_extra.alias,     -- set package alias name
        group            = require_extra.group,     -- only uses the first package in same group
        system           = require_extra.system,    -- default: true, we can set it to disable system package manually
        option           = require_extra.option,    -- set and attach option
        configs          = require_build_configs,   -- the required building configurations
        default          = require_extra.default,   -- default: true, we can set it to disable package manually
        optional         = parentinfo.optional or require_extra.optional, -- default: false, inherit parentinfo.optional
        verify           = require_extra.verify,    -- default: true, we can set false to ignore sha256sum and select any version
        external         = require_extra.external,  -- default: true, we use sysincludedirs/-isystem instead of -I/xxx
        private          = require_extra.private    -- default: false, private package, only for installation, do not export any links/includes and environments
    }
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

-- sort package deps
--
-- e.g.
--
-- a.deps = b
-- b.deps = c
--
-- orderdeps: c -> b -> a
--
function _sort_packagedeps(package, onlylink)
    -- we must use native deps list instead of package:deps() to generate correct linkdeps
    local orderdeps = {}
    for _, dep in ipairs(package:plaindeps()) do
        if dep and (onlylink ~= true or (dep:is_library() and not dep:is_private())) then
            table.join2(orderdeps, _sort_packagedeps(dep, onlylink))
            table.insert(orderdeps, dep)
        end
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
    package:add("configs", "pic", {builtin = true, description = "Enable the position independent code.", default = true, type = "boolean"})
    package:add("configs", "vs_runtime", {builtin = true, description = "Set vs compiler runtime.", values = {"MT", "MTd", "MD", "MDd"}})
    package:add("configs", "toolchains", {builtin = true, description = "Set package toolchains only for cross-compilation."})
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
        local require_verify  = requireinfo.verify
        if (not package:get("versions") or require_verify == false) and semver.is_valid(require_version) then
            -- no version list in package() or need not verify sha256sum? try selecting this version directly
            -- @see https://github.com/xmake-io/xmake/issues/930
            -- https://github.com/xmake-io/xmake/issues/1009
            version = require_version
            source = "versions"
        elseif #package:versions() > 0 and (require_version == "latest" or require_version:find('.', 1, true)) then -- select version?
            version, source = semver.select(require_version, package:versions())
        elseif has_giturl then -- select branch?
            version, source = require_version ~= "latest" and require_version or "master", "branches"
        else
            raise("package(%s %s): not found!", package:displayname(), require_version)
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
            local config_type = conf.type
            if config_type ~= nil and type(value) ~= config_type then
                raise("package(%s %s): invalid type(%s) for config(%s), need type(%s)!", package:displayname(), package:version_str(), type(value), name, config_type)
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
                    raise("package(%s %s): invalid value(%s) for config(%s), please run `xmake require --info %s` to get all valid values!", package:displayname(), package:version_str(), value, name, package:name())
                end
            end
            if conf.restrict then
                if not conf.restrict(value) then
                    raise("package(%s %s): invalid value(%s) for config(%s)!", package:displayname(), package:version_str(), value, name)
                end
            end
        else
            raise("package(%s %s): invalid config(%s), please run `xmake require --info %s` to get all configurations!", package:displayname(), package:version_str(), name, package:name())
        end
    end
end

-- match require path
function _match_requirepath(requirepath, requireconf)

    -- get pattern
    local function _get_pattern(pattern)
        pattern = pattern:gsub("([%+%.%-%^%$%(%)%%])", "%%%1")
        pattern = pattern:gsub("%*%*", "\001")
        pattern = pattern:gsub("%*", "\002")
        pattern = pattern:gsub("\001", ".*")
        pattern = pattern:gsub("\002", "[^.]*")
        pattern = string.ipattern(pattern, true)
        return pattern
    end

    -- get the excludes
    local excludes = requireconf:match("|.*$")
    if excludes then excludes = excludes:split("|", {plain = true}) end

    -- do match
    local pattern = requireconf:gsub("|.*$", "")
    pattern = _get_pattern(pattern)
    if (requirepath:match('^' .. pattern .. '$')) then
        -- exclude sub-deps, e.g. "libwebp.**|cmake|autoconf"
        local splitinfo = requirepath:split(".", {plain = true})
        if #splitinfo > 0 then
            local name = splitinfo[#splitinfo]
            for _, exclude in ipairs(excludes) do
                pattern = _get_pattern(exclude)
                if (name:match('^' .. pattern .. '$')) then
                    return false
                end
            end
        end
        return true
    end
end

-- init requireinfo
function _init_requireinfo(requireinfo, package, opt)
    -- pass root toolchains to top library package
    requireinfo.configs = requireinfo.configs or {}
    if opt.is_toplevel then
        requireinfo.is_toplevel = true
        if package:is_cross() and package:is_library() then
            -- TODO get extra configs of toolchain
            requireinfo.configs.toolchains = requireinfo.configs.toolchains or project.get("target.toolchains") or get_config("toolchain")
        end
        requireinfo.configs.vs_runtime = requireinfo.configs.vs_runtime or project.get("target.runtimes") or get_config("vs_runtime")
    end
end

-- set default requireinfo
function _set_requireinfo_default(requireinfo, package)
    requireinfo.configs = requireinfo.configs or {}
    if requireinfo.configs.vs_runtime == nil and package:is_plat("windows") then
        requireinfo.configs.vs_runtime = "MT"
    end
end

-- merge requireinfo from `add_requireconfs()`
--
-- add_requireconfs("*",                         {system = false, configs = {vs_runtime = "MD"}})
-- add_requireconfs("lib*",                      {system = false, configs = {vs_runtime = "MD"}})
-- add_requireconfs("libwebp",                   {system = false, configs = {vs_runtime = "MD"}})
-- add_requireconfs("libpng.zlib",               {system = false, override = true, configs = {cxflags = "-DTEST1"}, version = "1.2.10"})
-- add_requireconfs("libtiff.*",                 {system = false, configs = {cxflags = "-DTEST2"}})
-- add_requireconfs("libwebp.**|cmake|autoconf", {system = false, configs = {cxflags = "-DTEST3"}}) -- recursive deps
--
function _merge_requireinfo(requireinfo, requirepath)

    -- only for project
    if not os.isfile(os.projectfile()) then
        return
    end

    -- find requireconf from the given requirepath
    local requireconf_result = {}
    local requireconfs, requireconfs_extra = project.requireconfs_str()
    if requireconfs then
        for _, requireconf in ipairs(requireconfs) do
            if _match_requirepath(requirepath, requireconf) then
                local requireconf_extra = requireconfs_extra[requireconf]
                table.insert(requireconf_result, {requireconf = requireconf, requireconf_extra = requireconf_extra})
            end
        end
    end

    -- append requireconf_extra into requireinfo
    -- and the configs of add_requires have a higher priority than add_requireconfs.
    --
    -- e.g.
    -- add_requireconfs("*", {configs = {debug = false}})
    -- add_requires("foo", "bar", {configs = {debug = true}})
    --
    -- foo and bar will be debug mode
    --
    -- we can also override the configs of add_requires
    --
    -- e.g.
    -- add_requires("zlib 1.2.11")
    -- add_requireconfs("zlib", {override = true, version = "1.2.10"})
    --
    -- we override the version of zlib to 1.2.10
    --
    if #requireconf_result == 1 then
        local requireconf_extra = requireconf_result[1].requireconf_extra
        if requireconf_extra then
            -- preprocess requireconf_extra, (debug, override ..)
            local override = requireconf_extra.override
            requireconf_extra.override = nil
            if requireconf_extra.debug then
                requireconf_extra.configs = requireconf_extra.configs or {}
                requireconf_extra.configs.debug = true
                requireconf_extra.debug = nil
            end
            -- append or override configs and extra options
            for k, v in pairs(requireconf_extra.configs) do
                requireinfo.configs = requireinfo.configs or {}
                if override or requireinfo.configs[k] == nil then
                    requireinfo.configs[k] = v
                end
            end
            for k, v in pairs(requireconf_extra) do
                if k ~= "configs" then
                    if override or requireinfo[k] == nil then
                        requireinfo[k] = v
                    end
                end
            end
        end
    elseif #requireconf_result > 1 then
        local confs = {}
        for _, item in ipairs(requireconf_result) do
            table.insert(confs, item.requireconf)
        end
        raise("package(%s) will match multiple add_requireconfs(%s)!", requirepath, table.concat(confs, " "))
    end
end

-- get package key
function _get_packagekey(packagename, requireinfo, version)
    local key = packagename .. "/" .. (version or requireinfo.version)
    if requireinfo.plat then
        key = key .. "/" .. requireinfo.plat
    end
    if requireinfo.arch then
        key = key .. "/" .. requireinfo.arch
    end
    if requireinfo.label then
        key = key .. "/" .. requireinfo.label
    end
    local configs = requireinfo.configs
    if configs then
        local configs_order = {}
        for k, v in pairs(configs) do
            table.insert(configs_order, k .. "=" .. tostring(v))
        end
        table.sort(configs_order)
        key = key .. ":" .. string.serialize(configs_order, true)
    end
    return key
end

-- inherit some builtin configs of parent package if these config values are not default value
-- e.g. add_requires("libpng", {configs = {vs_runtime = "MD", pic = false}})
--
function _inherit_parent_configs(requireinfo, package, parentinfo)
    if package:is_library() then
        local requireinfo_configs = requireinfo.configs or {}
        local parentinfo_configs  = parentinfo.configs or {}
        if not requireinfo_configs.shared then
            if requireinfo_configs.vs_runtime == nil then
                requireinfo_configs.vs_runtime = parentinfo_configs.vs_runtime
            end
            if requireinfo_configs.pic == nil then
                requireinfo_configs.pic = parentinfo_configs.pic
            end
        end
        if parentinfo.plat then
            requireinfo.plat = parentinfo.plat
        end
        if parentinfo.arch then
            requireinfo.arch = parentinfo.arch
        end
        if parentinfo.private ~= nil then
            requireinfo.private = parentinfo.private
        end
        requireinfo_configs.toolchains = requireinfo_configs.toolchains or parentinfo_configs.toolchains
        requireinfo_configs.vs_runtime = requireinfo_configs.vs_runtime or parentinfo_configs.vs_runtime
        requireinfo.configs = requireinfo_configs
    end
end

-- load required packages
function _load_package(packagename, requireinfo, opt)

    -- strip trailng ~tag, e.g. zlib~debug
    local displayname
    if packagename:find('~', 1, true) then
        displayname = packagename
        local splitinfo = packagename:split('~', {plain = true, limit = 2})
        packagename = splitinfo[1]
        requireinfo.alias = requireinfo.alias or displayname
        requireinfo.label = splitinfo[2]
    end

    -- load package from project first
    local package
    if os.isfile(os.projectfile()) then
        package = _load_package_from_project(packagename)
    end

    -- load package from repositories
    if not package then
        package = _load_package_from_repository(packagename, requireinfo.reponame)
    end

    -- load package from system
    local system = requireinfo.system
    if system == nil then
        system = opt.system
    end
    if not package and (system ~= false or packagename:find("::", 1, true)) then
        package = _load_package_from_system(packagename)
    end

    -- check
    assert(package, "package(%s) not found!", packagename)

    -- init requireinfo
    _init_requireinfo(requireinfo, package, {is_toplevel = not opt.parentinfo})

    -- merge requireinfo from `add_requireconfs()`
    _merge_requireinfo(requireinfo, opt.requirepath)

    -- inherit some builtin configs of parent package, e.g. vs_runtime, pic
    if opt.parentinfo then
        _inherit_parent_configs(requireinfo, package, opt.parentinfo)
    end

    -- set default requireinfo
    _set_requireinfo_default(requireinfo, package)

    -- select package version
    local version, source = _select_package_version(package, requireinfo)
    if version then
        package:version_set(version, source)
    end

    -- get package key
    local packagekey = _get_packagekey(packagename, requireinfo, version)

    -- get package from cache first
    local package_cached = _memcache():get2("packages", packagekey)
    if package_cached then
        return package_cached
    end

    -- save require info
    package:requireinfo_set(requireinfo)

    -- save display name
    if not displayname then
        local packageid = _memcache():get2("packageids", packagename)
        displayname = packagename
        if packageid then
            displayname = displayname .. "#" .. tostring(packageid)
        end
        _memcache():set2("packageids", packagename, (packageid or 0) + 1)
    end
    package:displayname_set(displayname)

    -- disable parallelize if the package cache directory conflicts
    local cachedirs = _memcache():get2("cachedirs", package:cachedir())
    if cachedirs then
        package:set("parallelize", false)
    end
    _memcache():set2("cachedirs", package:cachedir(), true)

    -- add some builtin configurations to package
    _add_package_configurations(package)

    -- check package configurations
    _check_package_configurations(package)

    -- do load
    local on_load = package:script("load")
    if on_load then
        on_load(package)
    end

    -- load environments from the manifest to enable the environments of on_install()
    package:envs_load()

    -- save this package package to cache
    _memcache():set2("packages", packagekey, package)
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
    local packages_nodeps = {}
    for _, requireitem in ipairs(load_requires(requires, opt.requires_extra, opt)) do

        -- load package
        local requireinfo = requireitem.info
        local requirepath = opt.requirepath and (opt.requirepath .. "." .. requireitem.name) or requireitem.name
        local package     = _load_package(requireitem.name, requireinfo, table.join(opt, {requirepath = requirepath}))

        -- maybe package not found and optional
        if package then

            -- load dependent packages and save them first of this package
            if not package._DEPS then
                if package:get("deps") and opt.nodeps ~= true then

                    -- load dependent packages and do not load system/3rd packages for package/deps()
                    local packagedeps = {}
                    local deps, plaindeps = _load_packages(package:get("deps"), {requirepath = requirepath,
                                                        requires_extra = package:extraconf("deps") or {},
                                                        parentinfo = requireinfo,
                                                        nodeps = opt.nodeps,
                                                        system = false})
                    for _, dep in ipairs(deps) do
                        dep:parents_add(package)
                        table.insert(packages, dep)
                        packagedeps[dep:name()] = dep
                    end
                    package._DEPS = packagedeps
                    package._PLAINDEPS = plaindeps
                    package._ORDERDEPS = table.unique(_sort_packagedeps(package))
                    package._LINKDEPS = table.unique(_sort_packagedeps(package, true))
                end
            end

            -- save this package
            table.insert(packages, package)
            table.insert(packages_nodeps, package)
        end
    end
    return packages, packages_nodeps
end

-- get package parents string
function _get_parents_str(package)
    local parents = package:parents()
    if parents then
        local parentnames = {}
        for _, parent in pairs(parents) do
            table.insert(parentnames, parent:displayname())
        end
        if #parentnames == 0 then
            return
        end
        return table.concat(parentnames, ",")
    end
end

-- check dependences conflicts
--
-- It exists conflict for dependent packages for each root packages? resolve it first
-- e.g.
-- add_requires("foo") -> bar -> zlib 1.2.10
--                     -> xyz -> zlib 1.2.11 or other configs
--
-- add_requires("ddd") -> zlib
--
-- We assume that there is no conflict between `foo` and `ddd`.
--
-- Of course, conflicts caused by `add_packages("foo", "ddd")`
-- cannot be detected at present and can only be resolved by the user
--
function _check_package_depconflicts(package)
    local packagekeys = {}
    for _, dep in ipairs(package:linkdeps()) do
        local key = _get_packagekey(dep:name(), dep:requireinfo())
        local prevkey = packagekeys[dep:name()]
        if prevkey then
            assert(key == prevkey, "package(%s): conflict dependences with package(%s)!", key, prevkey)
        else
            packagekeys[dep:name()] = key
        end
    end
end

-- the cache directory
function cachedir()
    return path.join(global.directory(), "cache", "packages")
end

-- this package should be install?
function should_install(package)
    if package:exists() then
        return false
    end
    -- we need not install it if this package need only be fetched
    if package:is_fetchonly() then
        return false
    end
    -- only get system package? e.g. add_requires("xxx", {system = true})
    local requireinfo = package:requireinfo()
    if requireinfo and requireinfo.system then
        return false
    end
    if package:parents() then
        -- if all the packages that depend on it already exist, then there is no need to install it
        for _, parent in pairs(package:parents()) do
            if should_install(parent) and not parent:exists() then
                return true
            end
        end
    else
        return true
    end
end

-- get package configs string
function get_configs_str(package)
    local configs = {}
    if package:is_optional() then
        table.insert(configs, "optional")
    end
    if package:is_private() then
        table.insert(configs, "private")
    end
    local requireinfo = package:requireinfo()
    if requireinfo then
        if requireinfo.plat then
            table.insert(configs, requireinfo.plat)
        end
        if requireinfo.arch then
            table.insert(configs, requireinfo.arch)
        end
        for k, v in pairs(requireinfo.configs) do
            if type(v) == "boolean" then
                table.insert(configs, k .. ":" .. (v and "y" or "n"))
            else
                table.insert(configs, k .. ":" .. v)
            end
        end
    end
    local parents_str = _get_parents_str(package)
    if parents_str then
        table.insert(configs, "from:" .. parents_str)
    end
    local configs_str = #configs > 0 and "[" .. table.concat(configs, ", ") .. "]" or ""
    local limitwidth = os.getwinsize().width * 2 / 3
    if #configs_str > limitwidth then
        configs_str = configs_str:sub(1, limitwidth) .. " ..)"
    end
    return configs_str
end

-- load requires
function load_requires(requires, requires_extra, opt)
    opt = opt or {}
    local requireitems = {}
    for _, require_str in ipairs(requires) do
        local packagename, requireinfo = _load_require(require_str, requires_extra, opt.parentinfo)
        table.insert(requireitems, {name = packagename, info = requireinfo})
    end
    return requireitems
end

-- load all required packages
function load_packages(requires, opt)
    opt = opt or {}
    local unique = {}
    local packages = {}
    for _, package in ipairs((_load_packages(requires, opt))) do
        if package:is_toplevel() then
            _check_package_depconflicts(package)
        end
        local key = _get_packagekey(package:name(), package:requireinfo())
        if not unique[key] then
            table.insert(packages, package)
            unique[key] = true
        end
    end
    return packages
end

