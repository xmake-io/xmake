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
-- See the License for the specific package governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        package.lua
--

-- define module
local package   = package or {}
local _instance = _instance or {}

-- load modules
local os             = require("base/os")
local io             = require("base/io")
local path           = require("base/path")
local utils          = require("base/utils")
local table          = require("base/table")
local global         = require("base/global")
local semver         = require("base/semver")
local option         = require("base/option")
local scopeinfo      = require("base/scopeinfo")
local interpreter    = require("base/interpreter")
local sandbox        = require("sandbox/sandbox")
local config         = require("project/config")
local platform       = require("platform/platform")
local platform_menu  = require("platform/menu")
local language       = require("language/language")
local language_menu  = require("language/menu")
local sandbox        = require("sandbox/sandbox")
local sandbox_os     = require("sandbox/modules/os")
local sandbox_module = require("sandbox/modules/import/core/sandbox/module")

-- new an instance
function _instance.new(name, info, scriptdir)
    local instance = table.inherit(_instance)
    instance._NAME = name
    instance._INFO = info
    instance._SCRIPTDIR = scriptdir
    return instance
end

-- get the package name
function _instance:name()
    return self._NAME
end

-- get the package configure
function _instance:get(name)

    -- get it from info first
    local value = self._INFO:get(name)
    if value ~= nil then
        return value
    end
end

-- set the value to the package info
function _instance:set(name, ...)
    self._INFO:apival_set(name, ...)
end

-- add the value to the package info
function _instance:add(name, ...)
    self._INFO:apival_add(name, ...)
end

-- get the extra configuration
function _instance:extraconf(name, item, key)
    return self._INFO:extraconf(name, item, key)
end

-- get the package description
function _instance:description()
    return self:get("description")
end

-- get the platform of package
function _instance:plat()
    -- @note we uses os.host() instead of them for the binary package
    if self:kind() == "binary" then
        return os.host()
    end
    local requireinfo = self:requireinfo()
    if requireinfo and requireinfo.plat then
        return requireinfo.plat
    end
    return config.get("plat") or os.host()
end

-- get the architecture of package
function _instance:arch()
    -- @note we uses os.arch() instead of them for the binary package
    if self:kind() == "binary" then
        return os.arch()
    end
    local requireinfo = self:requireinfo()
    if requireinfo and requireinfo.arch then
        return requireinfo.arch
    end
    return config.get("arch") or os.arch()
end

-- get the build mode
function _instance:mode()
    return self:debug() and "debug" or "release"
end

-- get the repository of this package
function _instance:repo()
    return self._REPO
end

-- the current platform is belong to the given platforms?
function _instance:is_plat(...)
    local plat = self:plat()
    for _, v in ipairs(table.join(...)) do
        if v and plat == v then
            return true
        end
    end
end

-- the current architecture is belong to the given architectures?
function _instance:is_arch(...)
    local arch = self:arch()
    for _, v in ipairs(table.join(...)) do
        if v and arch:find("^" .. v:gsub("%-", "%%-") .. "$") then
            return true
        end
    end
end

-- get the package alias
function _instance:alias()
    local requireinfo = self:requireinfo()
    if requireinfo then
        return requireinfo.alias
    end
end

-- get urls
function _instance:urls()
    return self._URLS or table.wrap(self:get("urls"))
end

-- get urls
function _instance:urls_set(urls)
    self._URLS = urls
end

-- get the alias of url, @note need raw url
function _instance:url_alias(url)
    return self:extraconf("urls", url, "alias")
end

-- get the version filter of url, @note need raw url
function _instance:url_version(url)
    return self:extraconf("urls", url, "version")
end

-- get the excludes list of url for the archive extractor, @note need raw url
function _instance:url_excludes(url)
    return self:extraconf("urls", url, "excludes")
end

-- get the given dependent package
function _instance:dep(name)
    local deps = self:deps()
    if deps then
        return deps[name]
    end
end

-- get deps
function _instance:deps()
    return self._DEPS
end

-- get order deps
function _instance:orderdeps()
    return self._ORDERDEPS
end

-- add deps
function _instance:deps_add(...)
    for _, dep in ipairs({...}) do
        self:add("deps", dep:name())
        self._DEPS = self._DEPS or {}
        self._DEPS[dep:name()] = dep
        self._ORDERDEPS = self._ORDERDEPS or {}
        table.insert(self._ORDERDEPS, dep)
    end
end

-- get parents
function _instance:parents()
    return self._PARENTS
end

-- add parents
function _instance:parents_add(...)
    for _, parent in ipairs({...}) do
        self._PARENTS = self._PARENTS or {}
        self._PARENTS[parent:name()] = parent
    end
end

-- get hash of the source package for the url_alias@version_str
function _instance:sourcehash(url_alias)

    -- get sourcehash
    local versions    = self:get("versions")
    local version_str = self:version_str()
    if versions and version_str then

        local sourcehash = nil
        if url_alias then
            sourcehash = versions[url_alias .. ":" ..version_str]
        end
        if not sourcehash then
            sourcehash = versions[version_str]
        end

        -- ok?
        return sourcehash
    end
end

-- get revision(commit, tag, branch) of the url_alias@version_str, only for git url
function _instance:revision(url_alias)
    local revision = self:sourcehash(url_alias)
    if revision and #revision <= 40 then
        -- it will be sha256 of tar/gz file, not commit number if longer than 40 characters
        return revision
    end
end

-- get the package kind, binary or nil(library)
function _instance:kind()
    local kind = self:get("kind")
    if not kind then
        local requireinfo = self:requireinfo()
        if requireinfo then
            kind = requireinfo.kind
        end
    end
    return kind
end

-- get the filelock of the whole package directory
function _instance:filelock()
    local filelock = self._FILELOCK
    if filelock == nil then
        filelock = io.openlock(path.join(self:cachedir(), "package.lock"))
        if not filelock then
            os.raise("cannot create filelock for package(%s)!", package:name())
        end
        self._FILELOCK = filelock
    end
    return filelock
end

-- lock the whole package
function _instance:lock(opt)
    if self:filelock():trylock(opt) then
        return true
    elseif option.get("diagnosis") then
        utils.warning("the current package is being accessed by other processes, please waiting!")
    end
    local ok, errors = self:filelock():lock(opt)
    if not ok then
        os.raise(errors)
    end
end

-- unlock the whole package
function _instance:unlock()
    local ok, errors = self:filelock():unlock()
    if not ok then
        os.raise(errors)
    end
end

-- get the cached directory of this package
function _instance:cachedir()
    local name = self:name():lower():gsub("::", "_")
    return path.join(package.cachedir(), name:sub(1, 1):lower(), name, self:version_str())
end

-- get the installed directory of this package
function _instance:installdir(...)
    local name = self:name():lower():gsub("::", "_")
    local dir = path.join(package.installdir(), name:sub(1, 1):lower(), name)
    if self:version_str() then
        dir = path.join(dir, self:version_str())
    end
    dir = path.join(dir, self:buildhash(), ...)
    if not os.isdir(dir) then
        os.mkdir(dir)
    end
    return dir
end

-- get the script directory
function _instance:scriptdir()
    return self._SCRIPTDIR
end

-- get the references info of this package
function _instance:references()
    local references_file = path.join(self:installdir(), "references.txt")
    if os.isfile(references_file) then
        local references, errors = io.load(references_file)
        if not references then
            os.raise(errors)
        end
        return references
    end
end

-- get the manifest file of this package
function _instance:manifest_file()
    return path.join(self:installdir(), "manifest.txt")
end

-- load the manifest file of this package
function _instance:manifest_load()
    local manifest = self._MANIFEST
    if not manifest then
        local manifest_file = self:manifest_file()
        if os.isfile(manifest_file) then
            local errors = nil
            manifest, errors = io.load(manifest_file)
            if not manifest then
                os.raise(errors)
            end
            self._MANIFEST = manifest
        end
    end
    return manifest
end

-- save the manifest file of this package
function _instance:manifest_save()

    -- make manifest
    local manifest       = {}
    manifest.name        = self:name()
    manifest.description = self:description()
    manifest.version     = self:version_str()
    manifest.kind        = self:kind()
    manifest.plat        = self:plat()
    manifest.arch        = self:arch()
    manifest.mode        = self:mode()
    manifest.configs     = self:configs()
    manifest.envs        = self:envs()

    -- save variables
    local vars = {}
    local apis = language.apis()
    for _, apiname in ipairs(table.join(apis.values, apis.paths)) do
        if apiname:startswith("package.add_") or apiname:startswith("package.set_")  then
            local name = apiname:sub(13)
            local value = self:get(name)
            if value ~= nil then
                vars[name] = value
            end
        end
    end
    manifest.vars = vars

    -- save repository
    local repo = self:repo()
    if repo then
        manifest.repo        = {}
        manifest.repo.name   = repo:name()
        manifest.repo.url    = repo:url()
        manifest.repo.branch = repo:branch()
    end

    -- save manifest
    local ok, errors = io.save(self:manifest_file(), manifest)
    if not ok then
        os.raise(errors)
    end
end

-- get the exported environments
function _instance:envs()
    local envs = self._ENVS
    if not envs then
        envs = {}
        if self:kind() == "binary" then
            envs.PATH = {"bin"}
        end
        -- add LD_LIBRARY_PATH to load *.so directory
        if os.host() ~= "windows" and self:is_plat(os.host()) and self:is_arch(os.arch()) then
            envs.LD_LIBRARY_PATH = {"lib"}
        end
        self._ENVS = envs
    end
    return envs
end

-- load the package environments from the manifest
function _instance:envs_load()
    local manifest = self:manifest_load()
    if manifest then
        local envs = self:envs()
        for name, values in pairs(manifest.envs) do
            envs[name] = values
        end
    end
end

-- enter the package environments
function _instance:envs_enter()

    -- save the old environments
    local oldenvs = self._OLDENVS
    if not oldenvs then
        oldenvs = {}
        self._OLDENVS = oldenvs
    end

    -- add the new environments
    local installdir = self:installdir()
    for name, values in pairs(self:envs()) do
        oldenvs[name] = oldenvs[name] or os.getenv(name)
        if name == "PATH" or name == "LD_LIBRARY_PATH" then
            for _, value in ipairs(values) do
                if path.is_absolute(value) then
                    os.addenv(name, value)
                else
                    os.addenv(name, path.join(installdir, value))
                end
            end
        else
            os.addenv(name, unpack(table.wrap(values)))
        end
    end
end

-- leave the package environments
function _instance:envs_leave()
    if self._OLDENVS then
        for name, values in pairs(self._OLDENVS) do
            os.setenv(name, values)
        end
        self._OLDENVS = nil
    end
end

-- get the given environment variable
function _instance:getenv(name)
    return self:envs()[name]
end

-- set the given environment variable
function _instance:setenv(name, ...)
    self:envs()[name] = {...}
end

-- add the given environment variable
function _instance:addenv(name, ...)
    self:envs()[name] = table.join(self:envs()[name] or {}, ...)
end

-- get the given build environment variable
function _instance:build_getenv(name)
    return self:build_envs(true)[name]
end

-- set the given build environment variable
function _instance:build_setenv(name, ...)
    self:build_envs(true)[name] = table.unwrap({...})
end

-- add the given build environment variable
function _instance:build_addenv(name, ...)
    self:build_envs(true)[name] = table.unwrap(table.join(table.wrap(self:build_envs()[name]), ...))
end

-- get the build environments
function _instance:build_envs(lazy_loading)
    local build_envs = self._BUILD_ENVS
    if build_envs == nil then
        -- lazy loading the given environment value and cache it
        build_envs = {}
        setmetatable(build_envs, { __index = function (tbl, key)
            local value = config.get(key)
            if value == nil then
                value = platform.toolconfig(key, self:plat())
            end
            if value == nil then
                value = platform.tool(key, self:plat())
            end
            value = table.unique(table.join(table.wrap(value), self:config(key)))
            if #value > 0 then
                value = table.unwrap(value)
                rawset(tbl, key, value)
                return value
            end
            return rawget(tbl, key)
        end})

        -- save build environments
        self._BUILD_ENVS = build_envs
    end

    -- force to load all values if need
    if not lazy_loading then
        for _, opt in ipairs(table.join(language_menu.options("config"), platform_menu.options("config"))) do
            local optname = opt[2]
            if type(optname) == "string" then
                -- we need only index it to force load it's value
                local value = build_envs[optname]
            end
        end
    end
    return build_envs
end

-- get the user private data
function _instance:data(name)
    return self._DATA and self._DATA[name] or nil
end

-- set user private data
function _instance:data_set(name, data)
    self._DATA = self._DATA or {}
    self._DATA[name] = data
end

-- add user private data
function _instance:data_add(name, data)
    self._DATA = self._DATA or {}
    self._DATA[name] = table.unwrap(table.join(self._DATA[name] or {}, data))
end

-- get the downloaded original file
function _instance:originfile()
    return self._ORIGINFILE
end

-- set the downloaded original file
function _instance:originfile_set(filepath)
    self._ORIGINFILE = filepath
end

-- get versions
function _instance:versions()

    -- make versions
    if self._VERSIONS == nil then

        -- get versions
        local versions = {}
        for version, _ in pairs(table.wrap(self:get("versions"))) do

            -- remove the url alias prefix if exists
            local pos = version:find(':', 1, true)
            if pos then
                version = version:sub(pos + 1, -1)
            end
            table.insert(versions, version)
        end

        -- remove repeat
        self._VERSIONS = table.unique(versions)
    end
    return self._VERSIONS
end

-- get the version
function _instance:version()
    return self._VERSION
end

-- get the version string
function _instance:version_str()
    if self:is3rd() then
        local requireinfo = self:requireinfo()
        if requireinfo then
            return requireinfo.version
        end
    end
    return self._VERSION_STR
end

-- get branch version
function _instance:branch()
    return self._BRANCH
end

-- get tag version
function _instance:tag()
    return self._TAG
end

-- is git ref?
function _instance:gitref()
    return self:branch() or self:tag()
end

-- set the version, source: branches, tags, versions
function _instance:version_set(version, source)

    -- save the semver version
    local sv = semver.new(version)
    if sv then
        self._VERSION = sv
    end

    -- save branch and tag
    if source == "branches" then
        self._BRANCH = version
    elseif source == "tags" then
        self._TAG = version
    end

    -- save source and version string
    self._SOURCE      = source
    self._VERSION_STR = version
end

-- get the require info
function _instance:requireinfo()
    return self._REQUIREINFO
end

-- set the require info
function _instance:requireinfo_set(requireinfo)
    self._REQUIREINFO = requireinfo
end

-- get the given configuration value of package
function _instance:config(name)
    local configs = self:configs()
    if configs then
        return configs[name]
    end
end

-- get the configurations of package
function _instance:configs()
    local configs = self._CONFIGS
    if configs == nil then
        local configs_defined = self:get("configs")
        if configs_defined then
            configs = {}
            local requireinfo = self:requireinfo()
            local configs_required = requireinfo and requireinfo.configs or {}
            for _, name in ipairs(table.wrap(configs_defined)) do
                local value = configs_required[name]
                if value == nil then
                    value = self:extraconf("configs", name, "default")
                end
                configs[name] = value
            end
        else
            configs = false
        end
        self._CONFIGS = configs
    end
    return configs and configs or nil
end

-- get the build hash
function _instance:buildhash()
    if self._BUILDHASH == nil then
        local str = self:plat() .. self:arch()
        local configs = self:configs()
        if configs then
            -- since luajit v2.1, the key order of the table is random and undefined.
            -- We cannot directly deserialize the table, so the result may be different each time
            local configs_order = {}
            for k, v in pairs(table.wrap(configs)) do
                table.insert(configs_order, k .. "=" .. tostring(v))
            end
            table.sort(configs_order)

            -- We need to be compatible with the hash value string for the previous luajit version
            local configs_str = string.serialize(configs_order, true)
            configs_str = configs_str:gsub("\"", "")
            str = str .. configs_str
        end
        self._BUILDHASH = hash.uuid4(str):gsub('-', ''):lower()
    end
    return self._BUILDHASH
end

-- get the group name
function _instance:group()
    local requireinfo = self:requireinfo()
    if requireinfo then
        return requireinfo.group
    end
end

-- is optional package?
function _instance:optional()
    local requireinfo = self:requireinfo()
    return requireinfo and requireinfo.optional or false
end

-- is debug package?
function _instance:debug()
    return self:config("debug")
end

-- is the supported package?
function _instance:supported()
    -- attempt to get the install script with the current plat/arch
    return self:script("install") ~= nil
end

-- support parallelize for installation?
function _instance:parallelize()
    return self:get("parallelize") ~= false
end

-- is the third-party package? e.g. brew::pcre2/libpcre2-8, conan::OpenSSL/1.0.2n@conan/stable
-- we need install and find package by third-party package manager directly
--
function _instance:is3rd()
    return self._is3rd
end

-- is the system package?
function _instance:isSys()
    return self._isSys
end

-- get xxx_script
function _instance:script(name, generic)

    -- get script
    local script = self:get(name)
    local result = nil
    if type(script) == "function" then
        result = script
    elseif type(script) == "table" then

        -- get plat and arch
        local plat = self:plat() or ""
        local arch = self:arch() or ""

        -- match pattern
        --
        -- `@linux`
        -- `@linux|x86_64`
        -- `@macosx,linux`
        -- `android@macosx,linux`
        -- `android|armeabi-v7a@macosx,linux`
        -- `android|armeabi-v7a@macosx,linux|x86_64`
        -- `android|armeabi-v7a@linux|x86_64`
        --
        for _pattern, _script in pairs(script) do
            local hosts = {}
            local hosts_spec = false
            _pattern = _pattern:gsub("@(.+)", function (v)
                for _, host in ipairs(v:split(',')) do
                    hosts[host] = true
                    hosts_spec = true
                end
                return ""
            end)
            if not _pattern:startswith("__") and (not hosts_spec or hosts[os.host() .. '|' .. os.arch()] or hosts[os.host()])
            and (_pattern:trim() == "" or (plat .. '|' .. arch):find('^' .. _pattern .. '$') or plat:find('^' .. _pattern .. '$')) then
                result = _script
                break
            end
        end

        -- get generic script
        result = result or script["__generic__"] or generic
    end

    -- only generic script
    result = result or generic

    -- imports some modules first
    if result and result ~= generic then
        local scope = getfenv(result)
        if scope then
            for _, modulename in ipairs(table.wrap(self:get("imports"))) do
                scope[sandbox_module.name(modulename)] = sandbox_module.import(modulename, {anonymous = true})
            end
        end
    end

    -- ok
    return result
end

-- fetch the local package info
--
-- @param opt   the fetch option, e.g. {force = true, system = false}
--
-- @return {packageinfo}, fetchfrom (e.g. xmake/system)
--
function _instance:fetch(opt)

    -- init options
    opt = opt or {}

    -- attempt to get it from cache
    local fetchinfo = self._FETCHINFO
    if not opt.force and fetchinfo then
        return fetchinfo
    end

    -- fetch the require version
    local require_ver = opt.version or self:requireinfo().version
    if not self:is3rd() and not require_ver:find('.', 1, true) then
        -- strip branch version only system package
        require_ver = nil
    end

    -- nil: find xmake or system packages
    -- true: only find system package
    -- false: only find xmake packages
    local system = opt.system or self:requireinfo().system
    if self:is3rd() then
        -- we need ignore `{system = true/false}` argument if be 3rd package
        -- @see https://github.com/xmake-io/xmake/issues/726
        system = nil
    end

    -- fetch binary tool?
    fetchinfo = nil
    local isSys = nil
    if self:kind() == "binary" then

        -- import find_tool
        self._find_tool = self._find_tool or sandbox_module.import("lib.detect.find_tool", {anonymous = true})

        -- only fetch it from the xmake repository first
        if not fetchinfo and system ~= true and not self:is3rd() then
            fetchinfo = self._find_tool(self:name(), {version = self:version_str(),
                                                      cachekey = "fetch_package_xmake",
                                                      buildhash = self:buildhash(),
                                                      norun = true, -- we need not run it to check for xmake/packages, @see https://github.com/xmake-io/xmake-repo/issues/66
                                                      force = opt.force})
            if fetchinfo then
                isSys = self._isSys
            end
        end

        -- fetch it from the system directories
        if not fetchinfo and system ~= false then
            fetchinfo = self._find_tool(self:name(), {cachekey = "fetch_package_system",
                                                      force = opt.force})
            if fetchinfo then
                isSys = true
            end
        end
    else

        -- import find_package
        self._find_package = self._find_package or sandbox_module.import("lib.detect.find_package", {anonymous = true})

        -- only fetch it from the xmake repository first
        if not fetchinfo and system ~= true and not self:is3rd() then
            fetchinfo = self._find_package("xmake::" .. self:name(), {version = self:version_str(),
                                                                      cachekey = "fetch_package_xmake",
                                                                      buildhash = self:buildhash(),
                                                                      pkgconfigs = self:configs(),
                                                                      force = opt.force})
            if fetchinfo then
                isSys = self._isSys
            end
        end

        -- fetch it from the system directories
        if not fetchinfo and system ~= false then
            fetchinfo = self._find_package(self:name(), {force = opt.force,
                                                         version = require_ver,
                                                         mode = self:mode(),
                                                         pkgconfigs = self:configs(),
                                                         buildhash = self:is3rd() and self:buildhash(), -- only for 3rd package manager, e.g. go:: ..
                                                         cachekey = "fetch_package_system",
                                                         system = true})
            if fetchinfo then
                isSys = true
            end
        end
    end

    -- save to cache
    self._FETCHINFO = fetchinfo

    -- mark as system package?
    if isSys ~= nil then
        self._isSys = isSys
    end

    -- ok
    return fetchinfo
end

-- exists this package?
function _instance:exists()
    return self._FETCHINFO ~= nil
end

-- fetch all local info with dependencies
function _instance:fetchdeps()
    local fetchinfo = self:fetch()
    if not fetchinfo then
        return
    end
    local orderdeps = self:orderdeps()
    if orderdeps then
        local total = #orderdeps
        for idx, _ in ipairs(orderdeps) do
            local dep = orderdeps[total + 1 - idx]
            local depinfo = dep:fetch()
            if depinfo then
                for name, values in pairs(depinfo) do
                    fetchinfo[name] = table.wrap(fetchinfo[name])
                    table.join2(fetchinfo[name], values)
                end
            end
        end
    end
    if fetchinfo then
        for name, values in pairs(fetchinfo) do
            fetchinfo[name] = table.unwrap(table.unique(table.wrap(values)))
        end
    end
    return fetchinfo
end

-- get the patches of the current version
function _instance:patches()
    local patches = self._PATCHES
    if patches == nil then
        local patchinfos = self:get("patches")
        if patchinfos then
            local version_str = self:version_str()
            patchinfos = patchinfos[version_str]
            if patchinfos then
                patches = {}
                patchinfos = table.wrap(patchinfos)
                for idx = 1, #patchinfos, 2 do
                    table.insert(patches , {url = patchinfos[idx], sha256 = patchinfos[idx + 1]})
                end
            end
        end
        self._PATCHES = patches or false
    end
    return patches and patches or nil
end

-- get the resources of the current version
function _instance:resources()
    local resources = self._RESOURCES
    if resources == nil then
        local resourceinfos = self:get("resources")
        if resourceinfos then
            local version_str = self:version_str()
            resourceinfos = resourceinfos[version_str]
            if resourceinfos then
                resources = {}
                resourceinfos = table.wrap(resourceinfos)
                for idx = 1, #resourceinfos, 3 do
                    local name = resourceinfos[idx]
                    resources[name] = {url = resourceinfos[idx + 1], sha256 = resourceinfos[idx + 2]}
                end
            end
        end
        self._RESOURCES = resources or false
    end
    return resources and resources or nil
end

-- get the the given resource
function _instance:resource(name)
    local resources = self:resources()
    return resources and resources[name] or nil
end

-- get the the given resource file
function _instance:resourcefile(name)
    local resource = self:resource(name)
    if resource and resource.url then
        return path.join(self:cachedir(), "resources", name, (path.filename(resource.url):gsub("%?.+$", "")))
    end
end

-- get the the given resource directory
function _instance:resourcedir(name)
    local resource = self:resource(name)
    if resource and resource.url then
        return path.join(self:cachedir(), "resources", name, (path.filename(resource.url):gsub("%?.+$", "")) .. ".dir")
    end
end

-- has the given c funcs?
--
-- @param funcs     the funcs
-- @param opt       the argument options, e.g. { includes = ""}
--
-- @return          true or false
--
function _instance:has_cfuncs(funcs, opt)
    if self:plat() ~= config.get("plat") then
        -- TODO
        return true
    end
    opt = opt or {}
    opt.configs = table.join(self:fetchdeps(), opt.configs)
    return sandbox_module.import("lib.detect.has_cfuncs", {anonymous = true})(funcs, opt)
end

-- has the given c++ funcs?
--
-- @param funcs     the funcs
-- @param opt       the argument options, e.g. { includes = ""}
--
-- @return          true or false
--
function _instance:has_cxxfuncs(funcs, opt)
    if self:plat() ~= config.get("plat") then
        -- TODO
        return true
    end
    opt = opt or {}
    opt.configs = table.join(self:fetchdeps(), opt.configs)
    return sandbox_module.import("lib.detect.has_cxxfuncs", {anonymous = true})(funcs, opt)
end

-- has the given c types?
--
-- @param types  the types
-- @param opt       the argument options, e.g. { defines = ""}
--
-- @return          true or false
--
function _instance:has_ctypes(types, opt)
    if self:plat() ~= config.get("plat") then
        -- TODO
        return true
    end
    opt = opt or {}
    opt.configs = table.join(self:fetchdeps(), opt.configs)
    return sandbox_module.import("lib.detect.has_ctypes", {anonymous = true})(types, opt)
end

-- has the given c++ types?
--
-- @param types  the types
-- @param opt       the argument options, e.g. { defines = ""}
--
-- @return          true or false
--
function _instance:has_cxxtypes(types, opt)
    if self:plat() ~= config.get("plat") then
        -- TODO
        return true
    end
    opt = opt or {}
    opt.configs = table.join(self:fetchdeps(), opt.configs)
    return sandbox_module.import("lib.detect.has_cxxtypes", {anonymous = true})(types, opt)
end

-- has the given c includes?
--
-- @param includes  the includes
-- @param opt       the argument options, e.g. { defines = ""}
--
-- @return          true or false
--
function _instance:has_cincludes(includes, opt)
    if self:plat() ~= config.get("plat") then
        -- TODO
        return true
    end
    opt = opt or {}
    opt.configs = table.join(self:fetchdeps(), opt.configs)
    return sandbox_module.import("lib.detect.has_cincludes", {anonymous = true})(includes, opt)
end

-- has the given c++ includes?
--
-- @param includes  the includes
-- @param opt       the argument options, e.g. { defines = ""}
--
-- @return          true or false
--
function _instance:has_cxxincludes(includes, opt)
    if self:plat() ~= config.get("plat") then
        -- TODO
        return true
    end
    opt = opt or {}
    opt.configs = table.join(self:fetchdeps(), opt.configs)
    return sandbox_module.import("lib.detect.has_cxxincludes", {anonymous = true})(includes, opt)
end

-- check the given c snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options, e.g. { includes = ""}
--
-- @return          true or false
--
function _instance:check_csnippets(snippets, opt)
    if self:plat() ~= config.get("plat") then
        -- TODO
        return true
    end
    opt = opt or {}
    opt.configs = table.join(self:fetchdeps(), opt.configs)
    return sandbox_module.import("lib.detect.check_csnippets", {anonymous = true})(snippets, opt)
end

-- check the given c++ snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options, e.g. { includes = ""}
--
-- @return          true or false
--
function _instance:check_cxxsnippets(snippets, opt)
    if self:plat() ~= config.get("plat") then
        -- TODO
        return true
    end
    opt = opt or {}
    opt.configs = table.join(self:fetchdeps(), opt.configs)
    return sandbox_module.import("lib.detect.check_cxxsnippets", {anonymous = true})(snippets, opt)
end

-- the current mode is belong to the given modes?
function package._api_is_mode(interp, ...)
    return config.is_mode(...)
end

-- the current platform is belong to the given platforms?
function package._api_is_plat(interp, ...)
    return config.is_plat(...)
end

-- the current platform is belong to the given architectures?
function package._api_is_arch(interp, ...)
    return config.is_arch(...)
end

-- the current host is belong to the given hosts?
function package._api_is_host(interp, ...)
    return os.is_host(...)
end

-- the interpreter
function package._interpreter()

    -- the interpreter has been initialized? return it directly
    if package._INTERPRETER then
        return package._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)

    -- define apis
    interp:api_define(package.apis())

    -- define apis for language
    interp:api_define(language.apis())

    -- save interpreter
    package._INTERPRETER = interp

    -- ok?
    return interp
end

-- get package apis
function package.apis()

    return
    {
        values =
        {
            -- package.set_xxx
            "package.set_urls"
        ,   "package.set_kind"
        ,   "package.set_license"
        ,   "package.set_homepage"
        ,   "package.set_description"
        ,   "package.set_parallelize"
            -- package.add_xxx
        ,   "package.add_deps"
        ,   "package.add_urls"
        ,   "package.add_imports"
        ,   "package.add_configs"
        }
    ,   script =
        {
            -- package.on_xxx
            "package.on_load"
        ,   "package.on_install"
        ,   "package.on_test"

            -- package.before_xxx
        ,   "package.before_install"
        ,   "package.before_test"

            -- package.before_xxx
        ,   "package.after_install"
        ,   "package.after_test"
        }
    ,   keyvalues =
        {
            -- package.add_xxx
            "package.add_patches"
        ,   "package.add_resources"
        }
    ,   dictionary =
        {
            -- package.add_xxx
            "package.add_versions"
        }
    ,   custom =
        {
            -- is_xxx
            { "is_host", package._api_is_host }
        ,   { "is_mode", package._api_is_mode }
        ,   { "is_plat", package._api_is_plat }
        ,   { "is_arch", package._api_is_arch }
        }
    }
end

-- the cache directory
function package.cachedir()
    return path.join(global.directory(), "cache", "packages", os.date("%y%m"))
end

-- the install directory
function package.installdir()
    return global.get("pkg_installdir") or path.join(global.directory(), "packages")
end

-- the search directories
function package.searchdirs()
    local searchdirs = global.get("pkg_searchdirs")
    if searchdirs then
        return path.splitenv(searchdirs)
    end
end

-- load the package from the system directories
function package.load_from_system(packagename)

    -- get it directly from cache first
    package._PACKAGES = package._PACKAGES or {}
    if package._PACKAGES[packagename] then
        return package._PACKAGES[packagename]
    end

    -- get package info
    local packageinfo = {}
    local is3rd = false
    if packagename:find("::", 1, true) then

        -- get interpreter
        local interp = package._interpreter()

        -- on install script
        local on_install = function (pkg)
            local opt = table.copy(pkg:configs())
            opt.mode      = pkg:debug() and "debug" or "release"
            opt.plat      = pkg:plat()
            opt.arch      = pkg:arch()
            opt.version   = pkg:version_str()
            opt.buildhash = pkg:buildhash()
            import("package.manager.install_package")(pkg:name(), opt)
        end

        -- make sandbox instance with the given script
        local instance, errors = sandbox.new(on_install, interp:filter())
        if not instance then
            return nil, errors
        end

        -- save the install script
        packageinfo.install = instance:script()

        -- is third-party package?
        if not packagename:startswith("xmake::") then
            is3rd = true
        end
    end

    -- new an instance
    local instance = _instance.new(packagename, scopeinfo.new("package", packageinfo))

    -- mark as system or 3rd package
    instance._isSys = true
    instance._is3rd = is3rd

    if is3rd then
        -- add configurations for the 3rd package
        local install_package = sandbox_module.import("package.manager." .. packagename:split("::")[1]:lower() .. ".install_package", {try = true, anonymous = true})
        if install_package and install_package.configurations then
            for name, conf in pairs(install_package.configurations()) do
                instance:add("configs", name, conf)
            end
        end

        -- disable parallelize for installation
        instance:set("parallelize", false)
    end

    -- save instance to the cache
    package._PACKAGES[packagename] = instance

    -- ok
    return instance
end

-- load the package from the project file
function package.load_from_project(packagename, project)

    -- get it directly from cache first
    package._PACKAGES = package._PACKAGES or {}
    if package._PACKAGES[packagename] then
        return package._PACKAGES[packagename]
    end

    -- load packages (with cache)
    local packages, errors = project.packages()
    if not packages then
        return nil, errors
    end

    -- strip trailng ~tag, e.g. zlib~debug
    local realname = packagename
    if realname:find('~', 1, true) then
        realname = realname:gsub("~.+$", "")
    end

    -- not found?
    local packageinfo = packages[realname]
    if not packageinfo then
        return
    end

    -- new an instance
    local instance = _instance.new(packagename, packageinfo)
    package._PACKAGES[packagename] = instance
    return instance
end

-- load the package from the package directory or package description file
function package.load_from_repository(packagename, repo, packagedir, packagefile)

    -- get it directly from cache first
    package._PACKAGES = package._PACKAGES or {}
    if package._PACKAGES[packagename] then
        return package._PACKAGES[packagename]
    end

    -- load repository first for checking the xmake minimal version
    if repo then
        repo:load()
    end

    -- find the package script path
    local scriptpath = packagefile
    if not packagefile and packagedir then
        scriptpath = path.join(packagedir, "xmake.lua")
    end
    if not scriptpath or not os.isfile(scriptpath) then
        return nil, string.format("the package %s not found!", packagename)
    end

    -- get interpreter
    local interp = package._interpreter()

    -- load script
    local ok, errors = interp:load(scriptpath)
    if not ok then
        return nil, errors
    end

    -- load package and disable filter, we will process filter after a while
    local results, errors = interp:make("package", true, false)
    if not results then
        return nil, errors
    end

    -- get the package info
    local packageinfo = nil
    for _, info in pairs(results) do
        -- @note we cannot use the name of package(), because we need support `xxx~tag` for add_requires("zlib~xxx")
        -- so we use `xxx~tag` as the real package
        packageinfo = info
        break
    end

    -- check this package
    if not packageinfo then
        return nil, string.format("%s: the package %s not found!", scriptpath, packagename)
    end

    -- new an instance
    local instance = _instance.new(packagename, packageinfo, path.directory(scriptpath))

    -- save repository
    instance._REPO = repo

    -- save instance to the cache
    package._PACKAGES[packagename] = instance
    return instance
end

-- return module
return package
