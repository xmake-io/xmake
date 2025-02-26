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

-- define module
local package   = {}
local _instance = {}

-- load modules
local os             = require("base/os")
local io             = require("base/io")
local path           = require("base/path")
local utils          = require("base/utils")
local table          = require("base/table")
local global         = require("base/global")
local semver         = require("base/semver")
local option         = require("base/option")
local hashset        = require("base/hashset")
local scopeinfo      = require("base/scopeinfo")
local interpreter    = require("base/interpreter")
local select_script  = require("base/private/select_script")
local is_cross       = require("base/private/is_cross")
local memcache       = require("cache/memcache")
local toolchain      = require("tool/toolchain")
local compiler       = require("tool/compiler")
local linker         = require("tool/linker")
local sandbox        = require("sandbox/sandbox")
local config         = require("project/config")
local policy         = require("project/policy")
local platform       = require("platform/platform")
local platform_menu  = require("platform/menu")
local component      = require("package/component")
local language       = require("language/language")
local language_menu  = require("language/menu")
local sandbox        = require("sandbox/sandbox")
local sandbox_os     = require("sandbox/modules/os")
local sandbox_module = require("sandbox/modules/import/core/sandbox/module")

-- new an instance
function _instance.new(name, info, opt)
    opt = opt or {}
    local instance = table.inherit(_instance)
    if name then
        local parts = name:split("::", {plain = true})
        local managers = package._memcache():get("managers")
        if managers == nil and #parts == 2 then
            managers = hashset.new()
            for _, dir in ipairs(os.dirs(path.join(os.programdir(), "modules/package/manager/*"))) do
                managers:insert(path.filename(dir))
            end
            package._memcache():set("managers", managers)
        end
        if #parts == 2 and managers and managers:has(parts[1]) then
            instance._NAME = name
        else
            instance._NAME = parts[#parts]
            table.remove(parts)
            if #parts > 0 then
                instance._NAMESPACE = table.concat(parts, "::")
            end
        end
    end
    instance._INFO      = info
    instance._REPO      = opt.repo
    instance._SCRIPTDIR = opt.scriptdir and path.absolute(opt.scriptdir)
    return instance
end

-- get memcache
function _instance:_memcache()
    local cache = self._MEMCACHE
    if not cache then
        cache = memcache.cache("core.package.package." .. tostring(self))
        self._MEMCACHE = cache
    end
    return cache
end

-- get the package name without namespace
function _instance:name()
    return self._NAME
end

-- get the namespace
function _instance:namespace()
    return self._NAMESPACE
end

-- get the full name (with namespace)
function _instance:fullname()
    local namespace = self:namespace()
    return namespace and namespace .. "::" .. self:name() or self:name()
end

-- get the display name (with namespace and ~label)
function _instance:displayname()
    return self._DISPLAYNAME
end

-- set the display name
function _instance:displayname_set(displayname)
    self._DISPLAYNAME = displayname
end

-- get the type: package
function _instance:type()
    return "package"
end

-- get the base package
function _instance:base()
    return self._BASE
end

-- get the package configuration
function _instance:get(name)
    local value = self._INFO:get(name)
    if name == "configs" then
        -- we need to merge it, because current builtin configs always exists
        if self:base() then
            local configs_base = self:base():get("configs")
            if configs_base then
                value = table.unique(table.join(value or {}, configs_base))
            end
        end
    elseif value == nil and self:base() then
        value = self:base():get(name)
    end
    if value ~= nil then
        return value
    end
end

-- set the value to the package info
function _instance:set(name, ...)
    if self._SOURCE_INITED then
        -- we can use set/add to modify urls, .. in on_load() if urls have been inited.
        -- but we cannot init urls, ... in on_load() if it has been not inited
        --
        -- @see https://github.com/xmake-io/xmake/issues/5148
        -- https://github.com/xmake-io/xmake-repo/pull/4204
        if self:_sourceset():has(name) and self:get(name) == nil then
            os.raise("'%s' can only be initied in on_source() or the description scope.", name)
        end
    end
    self._INFO:apival_set(name, ...)
end

-- add the value to the package info
function _instance:add(name, ...)
    if self._SOURCE_INITED then
        if self:_sourceset():has(name) and self:get(name) == nil then
            os.raise("'%s' can only be initied in on_source() or the description scope.", name)
        end
    end
    self._INFO:apival_add(name, ...)
end

-- get the extra configuration
function _instance:extraconf(name, item, key)
    local conf = self._INFO:extraconf(name, item, key)
    if conf == nil and self:base() then
        conf = self:base():extraconf(name, item, key)
    end
    return conf
end

-- set the extra configuration
function _instance:extraconf_set(name, item, key, value)
    return self._INFO:extraconf_set(name, item, key, value)
end

-- get configuration source information of the given api item
function _instance:sourceinfo(name, item)
    return self._INFO:sourceinfo(name, item)
end

-- get the package license
function _instance:license()
    return self:get("license")
end

-- get the package description
function _instance:description()
    return self:get("description")
end

-- get the platform of package
function _instance:plat()
    if self._PLAT then
        return self._PLAT
    end
    if self:is_host() then
        return os.subhost()
    end
    local requireinfo = self:requireinfo()
    if requireinfo and requireinfo.plat then
        return requireinfo.plat
    end
    return package.targetplat()
end

-- get the architecture of package
function _instance:arch()
    if self._ARCH then
        return self._ARCH
    end
    if self:is_host() then
        return os.subarch()
    end
    return self:targetarch()
end

-- set the package platform
function _instance:plat_set(plat)
    self._PLAT = plat
end

-- set the package architecture
function _instance:arch_set(arch)
    self._ARCH = arch
end

-- get the target os
function _instance:targetos()
    local requireinfo = self:requireinfo()
    if requireinfo and requireinfo.targetos then
        return requireinfo.targetos
    end
    return config.get("target_os") or platform.os()
end

-- get the target architecture
function _instance:targetarch()
    local requireinfo = self:requireinfo()
    if requireinfo and requireinfo.arch then
        return requireinfo.arch
    end
    return package.targetarch()
end

-- get the build mode
function _instance:mode()
    return self:is_debug() and "debug" or "release"
end

-- get the repository of this package
function _instance:repo()
    return self._REPO
end

-- the current platform is belong to the given platforms?
function _instance:is_plat(...)
    local plat = self:plat()
    for _, v in ipairs(table.pack(...)) do
        if v and plat == v then
            return true
        end
    end
end

-- the current architecture is belong to the given architectures?
function _instance:is_arch(...)
    local arch = self:arch()
    for _, v in ipairs(table.pack(...)) do
        if v and arch:find("^" .. v:gsub("%-", "%%-") .. "$") then
            return true
        end
    end
end

-- is 64bits architecture?
function _instance:is_arch64()
    return self:is_arch(".+64.*")
end

-- the current platform is belong to the given target os?
function _instance:is_targetos(...)
    local targetos = self:targetos()
    for _, v in ipairs(table.join(...)) do
        if v and targetos == v then
            return true
        end
    end
end

-- the current architecture is belong to the given target architectures?
function _instance:is_targetarch(...)
    local targetarch = self:targetarch()
    for _, v in ipairs(table.pack(...)) do
        if v and targetarch:find("^" .. v:gsub("%-", "%%-") .. "$") then
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

-- get external package sources, e.g. pkgconfig::xxx, system::xxx, conan::xxx
-- we can use it to improve self:fetch() for find_package
function _instance:extsources()
    return self:get("extsources")
end

-- get urls
function _instance:urls()
    local urls = self._URLS
    if urls == nil then
        urls = table.wrap(self:get("urls"))
        if #urls == 1 and urls[1] == "" then
            urls = {}
        end
    end
    return urls
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

-- get the excludes paths of url
-- @note it supports the path pattern, but it only supports for archiver.
function _instance:url_excludes(url)
    return self:extraconf("urls", url, "excludes")
end

-- get the includes paths of url
-- @note it does not support the path pattern, and it only supports for git url now.
-- @see https://github.com/xmake-io/xmake/issues/6071
function _instance:url_includes(url)
    return self:extraconf("urls", url, "includes")
end

-- get the http headers of url, @note need raw url
function _instance:url_http_headers(url)
    return self:extraconf("urls", url, "http_headers")
end

-- set artifacts info
function _instance:artifacts_set(artifacts_info)
    local versions = self:_versions_list()
    if versions then
        -- backup previous package configuration
        self._ARTIFACTS_BACKUP = {
            urls = table.copy(self:urls()),
            versions = table.copy(versions),
            install = self:script("install")} -- self:get() will get a table, it will be broken when call self:set()

        -- we switch to urls of the precompiled artifacts
        self:urls_set(table.wrap(artifacts_info.urls))
        versions[self:version_str()] = artifacts_info.sha256
        self:set("install", function (package)
            sandbox_module.import("lib.detect.find_path")
            local rootdir = find_path("manifest.txt", path.join(os.curdir(), "*", "*", "*"))
            if not rootdir then
                os.raise("package(%s): manifest.txt not found when installing artifacts!", package:displayname())
            end
            os.cp(path.join(rootdir, "*"), package:installdir(), {symlink = true})
            local manifest = package:manifest_load()
            if not manifest then
                os.raise("package(%s): load manifest.txt failed when installing artifacts!", package:displayname())
            end
            if manifest.vars then
                for k, v in pairs(manifest.vars) do
                    package:set(k, v)
                end
            end
            if manifest.components then
                local vars = manifest.components.vars
                if vars then
                    for component_name, component_vars in pairs(vars) do
                        local comp = package:component(component_name)
                        if comp then
                            for k, v in pairs(component_vars) do
                                comp:set(k, v)
                            end
                        end
                    end
                end
            end
            if manifest.envs then
                local envs = self:_rawenvs()
                for k, v in pairs(manifest.envs) do
                    envs[k] = v
                end
            end
            -- save the remote install directory to fix the install path in .cmake/.pc files for precompiled artifacts
            --
            -- @see https://github.com/xmake-io/xmake/issues/2210
            --
            manifest.artifacts = manifest.artifacts or {}
            manifest.artifacts.remotedir = manifest.artifacts.installdir
        end)
        self._IS_PRECOMPILED = true
    end
end

-- is this package built?
function _instance:is_built()
    return not self:is_precompiled()
end

-- is this package precompiled?
function _instance:is_precompiled()
    return self._IS_PRECOMPILED
end

-- fallback to source code build
function _instance:fallback_build()
    if self:is_precompiled() then
        local artifacts_backup = self._ARTIFACTS_BACKUP
        if artifacts_backup then
            if artifacts_backup.urls then
                self:urls_set(artifacts_backup.urls)
            end
            if artifacts_backup.versions then
                self._INFO:apival_set("versions", artifacts_backup.versions)
            end
            if artifacts_backup.install then
                self._INFO:apival_set("install", artifacts_backup.install)
            end
            self._MANIFEST = nil
        end
        self._IS_PRECOMPILED = false
    end
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

-- get plain deps
function _instance:plaindeps()
    return self._PLAINDEPS
end

-- get library dep
function _instance:librarydep(name, opt)
    local key = "librarydeps_map_" .. ((opt and opt.private) and "private" or "")
    local librarydeps_map = self:_memcache():get(key)
    if not librarydeps_map then
        librarydeps_map = {}
        for _, dep in ipairs(self:librarydeps()) do
            librarydeps_map[dep:name()] = dep
        end
        self:_memcache():set(key, librarydeps_map)
    end
    return librarydeps_map[name]
end

-- get library deps with correct link order
function _instance:librarydeps(opt)
    if opt and opt.private then
        return self._LIBRARYDEPS_WITH_PRIVATE
    else
        return self._LIBRARYDEPS
    end
end

-- get parents
function _instance:parents(packagename)
    local parents = self._PARENTS
    if parents then
        if packagename then
            return parents[packagename]
        else
            local results = self._PARENTS_PLAIN
            if not results then
                results = {}
                for _, parentpkgs in pairs(parents) do
                    table.join2(results, parentpkgs)
                end
                results = table.unique(results)
                self._PARENTS_PLAIN = results
            end
            if #results > 0 then
                return results
            end
        end
    end
end

-- add parents
function _instance:parents_add(...)
    self._PARENTS = self._PARENTS or {}
    for _, parent in ipairs({...}) do
        -- maybe multiple parents will depend on it
        -- @see https://github.com/xmake-io/xmake/issues/3065
        local parentpkgs = self._PARENTS[parent:name()]
        if not parentpkgs then
            parentpkgs = {}
            self._PARENTS[parent:name()] = parentpkgs
        end
        table.insert(parentpkgs, parent)
        self._PARENTS_PLAIN = nil
    end
end

-- get hash of the source package for the url_alias@version_str
function _instance:sourcehash(url_alias)
    local versions    = self:_versions_list()
    local version_str = self:version_str()
    if versions and version_str then
        local sourcehash = nil
        if url_alias then
            sourcehash = versions[url_alias .. ":" ..version_str]
        end
        if not sourcehash then
            sourcehash = versions[version_str]
        end
        if sourcehash and #sourcehash == 40 then
            sourcehash = sourcehash:lower()
        end
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

-- get the package policy
function _instance:policy(name)
    local policies = self._POLICIES
    if not policies then
        policies = self:get("policy")
        self._POLICIES = policies
        if policies then
            local defined_policies = policy.policies()
            for name, _ in pairs(policies) do
                if not defined_policies[name] then
                    utils.warning("unknown policy(%s), please run `xmake l core.project.policy.policies` if you want to all policies", name)
                end
            end
        end
    end
    return policy.check(name, policies and policies[name])
end

-- get the package kind
--
-- - binary
-- - toolchain (is also binary)
-- - library(default)
--
function _instance:kind()
    local kind
    local requireinfo = self:requireinfo()
    if requireinfo then
        kind = requireinfo.kind
    end
    if not kind then
        kind = self:get("kind")
    end
    return kind
end

-- is binary package?
function _instance:is_binary()
    return self:kind() == "binary" or self:kind() == "toolchain"
end

-- is toolchain package?
function _instance:is_toolchain()
    return self:kind() == "toolchain"
end

-- is library package?
function _instance:is_library()
    return self:kind() == nil or self:kind() == "library"
end

-- is template package?
function _instance:is_template()
    return self:kind() == "template"
end

-- is header only?
function _instance:is_headeronly()
    return self:is_library() and self:extraconf("kind", "library", "headeronly")
end

-- is module only?
function _instance:is_moduleonly()
    return self:is_library() and self:extraconf("kind", "library", "moduleonly")
end

-- is top level? user top requires in xmake.lua
function _instance:is_toplevel()
    local requireinfo = self:requireinfo()
    return requireinfo and requireinfo.is_toplevel
end

-- is the system package?
function _instance:is_system()
    return self._is_system
end

-- is the third-party package? e.g. brew::pcre2/libpcre2-8, conan::OpenSSL/1.0.2n@conan/stable
-- we need to install and find package by third-party package manager directly
--
function _instance:is_thirdparty()
    return self._is_thirdparty
end

-- is fetch only?
function _instance:is_fetchonly()
    local project = package._project()
    if project and project.policy("package.fetch_only") then
        return true
    end
    -- only fetch script
    if self:get("fetch") and not self:get("install") then
        return true
    end
    -- only from system
    local requireinfo = self:requireinfo()
    if requireinfo and requireinfo.system then
        return true
    end
    return false
end

-- is optional package?
function _instance:is_optional()
    local requireinfo = self:requireinfo()
    return requireinfo and requireinfo.optional or false
end

-- is private package?
function _instance:is_private()
    local requireinfo = self:requireinfo()
    return requireinfo and requireinfo.private or false
end

-- verify sha256sum and versions?
function _instance:is_verify()
    local requireinfo = self:requireinfo()
    local verify = requireinfo and requireinfo.verify
    if verify == nil then
        verify = true
    end
    return verify
end

-- is debug package?
function _instance:is_debug()
    return self:config("debug") or self:config("asan")
end

-- is the supported package?
function _instance:is_supported()
    -- attempt to get the install script with the current plat/arch
    return self:script("install") ~= nil
end

-- support parallelize for installation?
function _instance:is_parallelize()
    return self:get("parallelize") ~= false
end

-- is local embed source code package?
-- we install directly from the local source code instead of downloading it remotely
function _instance:is_source_embed()
    return self:get("sourcedir") and #self:urls() == 0 and self:script("install")
end

-- is local embed binary package? it's come from `xmake package`
function _instance:is_binary_embed()
    return self:get("installdir") and #self:urls() == 0 and not self:script("install") and self:script("fetch")
end

-- is local package?
-- we will use local installdir and cachedir in current project
function _instance:is_local()
    return self._IS_LOCAL or self:is_source_embed() or self:is_binary_embed() or self:is_thirdparty()
end

-- is debug package? (deprecated)
function _instance:debug()
    return self:is_debug()
end

-- is host package?
--
-- @note It is different from not is_cross() in that users do not use host packages directly,
-- they are usually used to build library packages.
function _instance:is_host()
    local requireinfo = self:requireinfo()
    if requireinfo and requireinfo.host then
        return true
    end
    return self:is_binary()
end

-- is cross-compilation?
function _instance:is_cross()
    if self:is_host() then
        return false
    end
    return is_cross(self:plat(), self:arch())
end

-- mark it as local package
function _instance:_mark_as_local(is_local)
    if self:is_local() ~= is_local then
        self._INSTALLDIR = nil
        self._IS_LOCAL = is_local
    end
end

-- use external includes?
function _instance:use_external_includes()
    local external = self:requireinfo().external
    if external == nil then
        local project = package._project()
        if project then
            external = project.policy("package.include_external_headers")
        end
    end
    if external == nil then
        external = self:policy("package.include_external_headers")
    end
    -- disable -Isystem for external packages as it seems to break. e.g. assimp
    -- @see https://github.com/msys2/MINGW-packages/issues/10761
    if external == nil and self:is_plat("mingw") and os.is_subhost("msys") then
        external = false
    end
    if external == nil then
        external = true
    end
    return external
end

-- get the filelock of the whole package directory
function _instance:filelock()
    local filelock = self._FILELOCK
    if filelock == nil then
        filelock = io.openlock(path.join(self:cachedir(), "package.lock"))
        if not filelock then
            os.raise("cannot create filelock for package(%s)!", self:name())
        end
        self._FILELOCK = filelock
    end
    return filelock
end

-- lock the whole package
function _instance:lock(opt)
    if self:filelock():trylock(opt) then
        return true
    else
        utils.cprint("${color.warning}package(%s) is being accessed by other processes, please wait!", self:name())
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

-- get the source directory
function _instance:sourcedir()
    return self:get("sourcedir")
end

-- get the build directory
function _instance:buildir()
    local buildir = self._BUILDIR
    if not buildir then
        if self:is_local() then
            local name = self:name():lower():gsub("::", "_")
            local rootdir = path.join(config.buildir({absolute = true}), ".packages", name:sub(1, 1):lower(), name, self:version_str())
            buildir = path.join(rootdir, "cache", "build_" .. self:buildhash():sub(1, 8))
        else
            buildir = "build_" .. self:buildhash():sub(1, 8)
        end
        self._BUILDIR = buildir
    end
    return buildir
end

-- get the cached directory of this package
function _instance:cachedir()
    local cachedir = self._CACHEDIR
    if not cachedir then
        cachedir = self:get("cachedir")
        if not cachedir then
            -- we need to use displayname (with package id) to avoid
            -- multiple processes accessing it at the same time.
            --
            -- @see https://github.com/libbpf/libbpf-bootstrap/pull/259#issuecomment-1994914188
            --
            -- e.g.
            --
            -- lock elfutils#1 /home/runner/.xmake/cache/packages/2403/e/elfutils/0.189
            -- lock elfutils /home/runner/.xmake/cache/packages/2403/e/elfutils/0.189
            -- package(elfutils) is being accessed by other processes, please wait!
            --
            local name = self:displayname():lower():gsub("::", "_"):gsub("#", "_")
            local version_str = self:version_str()
            -- strip invalid characters on windows, e.g. `>= <=`
            if version_str and os.is_host("windows") then
                version_str = version_str:gsub("[>=<|%*]", "")
            end
            if self:is_local() then
                cachedir = path.join(config.buildir({absolute = true}), ".packages", name:sub(1, 1):lower(), name, version_str, "cache")
            else
                cachedir = path.join(package.cachedir(), name:sub(1, 1):lower(), name, version_str)
            end
        end
        self._CACHEDIR = cachedir
    end
    return cachedir
end

-- get the installed directory of this package
function _instance:installdir(...)
    local installdir = self._INSTALLDIR
    if not installdir then
        installdir = self:get("installdir")
        if not installdir then
            local name = self:name():lower():gsub("::", "_")
            if self:is_local() then
                installdir = path.join(config.buildir({absolute = true}), ".packages", name:sub(1, 1):lower(), name)
            else
                installdir = path.join(package.installdir(), name:sub(1, 1):lower(), name)
            end
            local version_str = self:version_str()
            if version_str then
                -- strip invalid characters on windows, e.g. `>= <=`
                if os.is_host("windows") then
                    version_str = version_str:gsub("[>=<|%*]", "")
                end
                installdir = path.join(installdir, version_str)
            end
            installdir = path.join(installdir, self:buildhash())
        end
        self._INSTALLDIR = installdir
    end
    local dirs = table.pack(...)
    local opt = dirs[dirs.n]
    if table.is_dictionary(opt) then
        table.remove(dirs)
    else
        opt = nil
    end
    local dir = path.join(installdir, table.unpack(dirs))
    if opt and opt.readonly then
        return dir
    end
    if not os.isdir(dir)then
        os.mkdir(dir)
    end
    return dir
end

-- get the script directory
function _instance:scriptdir()
    return self._SCRIPTDIR
end

-- get the rules directory
function _instance:rulesdir()
    local rulesdir = self._RULESDIR
    if rulesdir == nil then
        rulesdir = path.join(self:scriptdir(), "rules")
        if not os.isdir(rulesdir) and self:base() then
            rulesdir = self:base():rulesdir()
        end
        if rulesdir == nil or not os.isdir(rulesdir) then
            rulesdir = false
        end
        self._RULESDIR = rulesdir
    end
    return rulesdir or nil
end

-- get the references info of this package
function _instance:references()
    local references_file = path.join(self:installdir({readonly = true}), "references.txt")
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
    return path.join(self:installdir({readonly = true}), "manifest.txt")
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
    manifest.license     = self:license()
    manifest.description = self:description()
    manifest.version     = self:version_str()
    manifest.kind        = self:kind()
    manifest.plat        = self:plat()
    manifest.arch        = self:arch()
    manifest.mode        = self:mode()
    manifest.configs     = self:configs()
    manifest.envs        = self:_rawenvs()
    manifest.pathenvs    = self:_pathenvs():to_array()

    -- save enabled library deps
    if self:librarydeps() then
        manifest.librarydeps = {}
        for _, dep in ipairs(self:librarydeps()) do
            if dep:exists() then
                table.insert(manifest.librarydeps, dep:name())
            end
        end
    end

    -- save deps
    if self:librarydeps() then
        manifest.deps = {}
        for _, dep in ipairs(self:librarydeps()) do
            manifest.deps[dep:name()] = {
                version = dep:version_str(),
                buildhash = dep:buildhash()
            }
        end
    end

    -- save global variables and component variables
    local vars
    local extras
    local components
    local apis = language.apis()
    for _, apiname in ipairs(table.join(apis.values, apis.paths, apis.groups)) do
        if apiname:startswith("package.add_") or apiname:startswith("package.set_")  then
            local name = apiname:sub(13)
            local values = self:get(name)
            if values ~= nil then
                vars = vars or {}
                vars[name] = values
                local extra = self:extraconf(name)
                if extra then
                    extras = extras or {}
                    extras[name] = extra
                end
            end
            for _, component_name in ipairs(table.wrap(self:get("components"))) do
                local comp = self:component(component_name)
                if comp then
                    local component_values = comp:get(name)
                    if component_values ~= nil then
                        components = components or {}
                        components.vars = components.vars or {}
                        components.vars[component_name] = components.vars[component_name] or {}
                        components.vars[component_name][name] = component_values
                    end
                end
            end
        end
    end
    manifest.vars = vars
    manifest.extras = extras
    manifest.components = components

    -- save repository
    local repo = self:repo()
    if repo then
        manifest.repo        = {}
        manifest.repo.name   = repo:name()
        manifest.repo.url    = repo:url()
        manifest.repo.branch = repo:branch()
        manifest.repo.commit = repo:commit()
    end

    -- save artifacts information to fix the install path in .cmake/.pc files for precompiled artifacts
    --
    -- @see https://github.com/xmake-io/xmake/issues/2210
    --
    manifest.artifacts = {}
    manifest.artifacts.installdir = self:installdir()
    local current_manifest = self:manifest_load()
    if current_manifest and current_manifest.artifacts then
        manifest.artifacts.remotedir = current_manifest.artifacts.remotedir
    end

    -- save manifest
    local ok, errors = io.save(self:manifest_file(), manifest, { orderkeys = true })
    if not ok then
        os.raise(errors)
    end
end

-- get the source configuration set
function _instance:_sourceset()
    local sourceset = self._SOURCESET
    if sourceset == nil then
        sourceset = hashset.of("urls", "versions", "versionfiles", "configs")
        self._SOURCESET = sourceset
    end
    return sourceset
end

-- init package source
function _instance:_init_source()
    local inited = self._SOURCE_INITED
    if not inited then
        local on_source = self:script("source")
        if on_source then
            on_source(self)
        end
    end
end

-- load package
function _instance:_load()
    self._SOURCE_INITED = true
    local loaded = self._LOADED
    if not loaded then
        local on_load = self:script("load")
        if on_load then
            on_load(self)
        end
    end
end

-- mark as loaded package
function _instance:_mark_as_loaded()
    self._LOADED = true
end

-- get the raw environments
function _instance:_rawenvs()
    local envs = self._RAWENVS
    if not envs then
        envs = {}

        -- add bin PATH
        local bindirs = self:get("bindirs")
        if bindirs then
            envs.PATH = table.wrap(bindirs)
        elseif self:is_binary() then
            envs.PATH = {"bin"}
        elseif os.host() == "windows" and self:is_plat("windows", "mingw") and not self:is_cross() and self:config("shared") then
            -- bin/*.dll for windows
            envs.PATH = {"bin"}
        end

        -- add LD_LIBRARY_PATH to load *.so directory
        if os.host() ~= "windows" and self:is_plat(os.host()) and not self:is_cross() and self:config("shared") then
            envs.LD_LIBRARY_PATH = {"lib"}
            if os.host() == "macosx" then
                envs.DYLD_LIBRARY_PATH = {"lib"}
            end
        end
        self._RAWENVS = envs
    end
    return envs
end

-- get path environment keys
function _instance:_pathenvs()
    local pathenvs = self._PATHENVS
    if pathenvs == nil then
        pathenvs = hashset.from {
            "PATH",
            "LD_LIBRARY_PATH",
            "DYLD_LIBRARY_PATH",
            "PKG_CONFIG_PATH",
            "ACLOCAL_PATH",
            "CMAKE_PREFIX_PATH",
            "PYTHONPATH"
        }
        self._PATHENVS = pathenvs
    end
    return pathenvs
end

-- mark as path environments
function _instance:mark_as_pathenv(name)
    self:_pathenvs():insert(name)
end

-- get the exported environments
function _instance:envs()
    local envs = {}
    for name, values in pairs(self:_rawenvs()) do
        if self:_pathenvs():has(name) then
            local newvalues = {}
            for _, value in ipairs(values) do
                if path.is_absolute(value) then
                    table.insert(newvalues, value)
                else
                    table.insert(newvalues, path.normalize(path.join(self:installdir({readonly = true}), value)))
                end
            end
            values = newvalues
        end
        envs[name] = values
    end
    return envs
end

-- load the package environments from the manifest
function _instance:envs_load()
    local manifest = self:manifest_load()
    if manifest then
        local envs = self:_rawenvs()
        for name, values in pairs(manifest.envs) do
            envs[name] = values
        end
    end
end

-- enter the package environments
function _instance:envs_enter()
    local installdir = self:installdir({readonly = true})
    for name, values in pairs(self:envs()) do
        os.addenv(name, table.unpack(table.wrap(values)))
    end
end

-- get the given environment variable
function _instance:getenv(name)
    return self:_rawenvs()[name]
end

-- set the given environment variable
function _instance:setenv(name, ...)
    self:_rawenvs()[name] = {...}
end

-- add the given environment variable
function _instance:addenv(name, ...)
    self:_rawenvs()[name] = table.join(self:_rawenvs()[name] or {}, ...)
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
                value = self:tool(key)
            end
            value = table.unique(table.join(table.wrap(value), table.wrap(self:config(key)), self:toolconfig(key)))
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
                -- we only need to index it to force load it's value
                local value = build_envs[optname]
            end
        end
    end
    return build_envs
end

-- get runtimes
function _instance:runtimes()
    local runtimes = self:_memcache():get("runtimes")
    if runtimes == nil then
        runtimes = self:config("runtimes")
        if runtimes then
            local runtimes_current = runtimes:split(",", {plain = true})
            runtimes = table.unwrap(runtimes_current)
        end
        runtimes = runtimes or false
        self:_memcache():set("runtimes", runtimes)
    end
    return runtimes or nil
end

-- has the given runtime for the current toolchains?
function _instance:has_runtime(...)
    local runtimes_set = self:_memcache():get("runtimes_set")
    if runtimes_set == nil then
        runtimes_set = hashset.from(table.wrap(self:runtimes()))
        self:_memcache():set("runtimes_set", runtimes_set)
    end
    for _, v in ipairs(table.pack(...)) do
        if runtimes_set:has(v) then
            return true
        end
    end
end

-- get the given toolchain
function _instance:toolchain(name)
    local toolchains_map = self:_memcache():get("toolchains_map")
    if toolchains_map == nil then
        toolchains_map = {}
        local toolchains = self:toolchains()
        if toolchains then
            for _, toolchain_inst in ipairs(toolchains) do
                toolchains_map[toolchain_inst:name()] = toolchain_inst
            end
        end
        self:_memcache():set("toolchains_map", toolchains_map)
    end
    if not toolchains_map[name] then
        toolchains_map[name] = toolchain.load(name, {plat = self:plat(), arch = self:arch()})
    end
    return toolchains_map[name]
end

-- get toolchains
function _instance:toolchains()
    local toolchains = self._TOOLCHAINS
    if toolchains == nil then
        local project = package._project()
        for _, name in ipairs(table.wrap(self:config("toolchains"))) do
            local toolchain_opt = project and project.extraconf("target.toolchains", name) or {}
            toolchain_opt.plat = self:plat()
            toolchain_opt.arch = self:arch()
            toolchain_opt.namespace = self:namespace()
            local toolchain_inst, errors = toolchain.load(name, toolchain_opt)
            if not toolchain_inst and project then
                toolchain_inst = project.toolchain(name, toolchain_opt)
            end
            if not toolchain_inst then
                os.raise(errors)
            end
            toolchains = toolchains or {}
            table.insert(toolchains, toolchain_inst)
        end
        self._TOOLCHAINS = toolchains or false
    end
    return toolchains or nil
end

-- get the program and name of the given tool kind
function _instance:tool(toolkind)
    if self:toolchains() then
        local cachekey = "package_" .. tostring(self)
        return toolchain.tool(self:toolchains(), toolkind, {cachekey = cachekey, plat = self:plat(), arch = self:arch()})
    else
        return platform.tool(toolkind, self:plat(), self:arch(), {host = self:is_host()})
    end
end

-- get tool configuration from the toolchains
function _instance:toolconfig(name)
    if self:toolchains() then
        local cachekey = "package_" .. tostring(self)
        return toolchain.toolconfig(self:toolchains(), name, {cachekey = cachekey, plat = self:plat(), arch = self:arch()})
    else
        return platform.toolconfig(name, self:plat(), self:arch(), {host = self:is_host()})
    end
end

-- get the package compiler
function _instance:compiler(sourcekind)
    local compilerinst = self:_memcache():get2("compiler", sourcekind)
    if not compilerinst then
        if not sourcekind then
            os.raise("please pass sourcekind to the first argument of package:compiler(), e.g. cc, cxx, as")
        end
        local instance, errors = compiler.load(sourcekind, self)
        if not instance then
            os.raise(errors)
        end
        compilerinst = instance
        self:_memcache():set2("compiler", sourcekind, compilerinst)
    end
    return compilerinst
end

-- get the package linker
function _instance:linker(targetkind, sourcekinds)
    local linkerinst = self:_memcache():get3("linker", targetkind, sourcekinds)
    if not linkerinst then
        if not sourcekinds then
            os.raise("please pass sourcekinds to the second argument of package:linker(), e.g. cc, cxx, as")
        end
        local instance, errors = linker.load(targetkind, sourcekinds, self)
        if not instance then
            os.raise(errors)
        end
        linkerinst = instance
        self:_memcache():set3("linker", targetkind, sourcekinds, linkerinst)
    end
    return linkerinst
end

-- has the given tool for the current package?
--
-- e.g.
--
-- if package:has_tool("cc", "clang", "gcc") then
--    ...
-- end
function _instance:has_tool(toolkind, ...)
    local _, toolname = self:tool(toolkind)
    if toolname then
        for _, v in ipairs(table.join(...)) do
            if v and toolname:find("^" .. v:gsub("%-", "%%-") .. "$") then
                return true
            end
        end
    end
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

-- get versions list
function _instance:_versions_list()
    if self._VERSIONS_LIST == nil then
        local versions = table.wrap(self:get("versions"))
        local versionfiles = self:get("versionfiles")
        if versionfiles then
            for _, versionfile in ipairs(table.wrap(versionfiles)) do
                if not path.is_absolute(versionfile) then
                    local subpath = versionfile
                    versionfile = path.join(self:scriptdir(), subpath)
                    if not os.isfile(versionfile) then
                        versionfile = path.join(self:base():scriptdir(), subpath)
                    end
                end
                if os.isfile(versionfile) then
                    local list = io.readfile(versionfile)
                    for _, line in ipairs(list:split("\n")) do
                        local splitinfo = line:split("%s+")
                        if #splitinfo == 2 then
                            local version = splitinfo[1]
                            local shasum = splitinfo[2]
                            versions[version] = shasum
                        end
                    end
                end
            end
        end
        self._VERSIONS_LIST = versions
    end
    return self._VERSIONS_LIST
end

-- get versions
function _instance:versions()
    if self._VERSIONS == nil then
        local versions = {}
        for version, _ in pairs(self:_versions_list()) do
            -- remove the url alias prefix if exists
            local pos = version:find(':', 1, true)
            if pos then
                version = version:sub(pos + 1, -1)
            end
            table.insert(versions, version)
        end
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
    if self:is_thirdparty() then
        local requireinfo = self:requireinfo()
        if requireinfo then
            return requireinfo.version
        end
    end
    return self._VERSION_STR
end

-- set the version, source: branch, tag, version
function _instance:version_set(version, source)

    -- save the semver version
    local sv = semver.new(version)
    if sv then
        self._VERSION = sv
    end

    -- save branch and tag
    if source == "branch" then
        self._BRANCH = version
    elseif source == "tag" then
        self._TAG = version
    elseif source == "commit" then
        self._COMMIT = version
    end

    -- save version string
    if source == "commit" then
        -- we strip it to avoid long paths
        self._VERSION_STR = version:sub(1, 8)
    else
        self._VERSION_STR = version
    end
end

-- get branch version
function _instance:branch()
    return self._BRANCH
end

-- get tag version
function _instance:tag()
    return self._TAG
end

-- get commit version
function _instance:commit()
    return self._COMMIT
end

-- is git ref?
function _instance:gitref()
    return self:branch() or self:tag() or self:commit()
end

-- get the require info
function _instance:requireinfo()
    return self._REQUIREINFO
end

-- set the require info
function _instance:requireinfo_set(requireinfo)
    self._REQUIREINFO = requireinfo
end

-- get label
function _instance:label()
    local requireinfo = self:requireinfo()
    return requireinfo and requireinfo.label
end

-- invalidate configs
function _instance:_invalidate_configs()
    self._CONFIGS = nil
    self._CONFIGS_FOR_BUILDHASH = nil
end

-- get the given configuration value of package
function _instance:config(name)
    local value
    local configs = self:configs()
    if configs then
        value = configs[name]
        -- vs_runtime is deprecated now
        if name == "vs_runtime" then
            local runtimes = configs.runtimes
            if runtimes then
                for _, item in ipairs(runtimes:split(",")) do
                    if item:startswith("MT") or item:startswith("MD") then
                        value = item
                        break
                    end
                end
            end
            utils.warning("please use package:runtimes() or package:has_runtime() instead of package:config(\"vs_runtime\")")
        end
    end
    return value
end

-- set configuration value
function _instance:config_set(name, value)
    local configs = self:configs()
    if configs then
        configs[name] = value
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
            local configs_overrided = requireinfo and requireinfo.configs_overrided or {}
            for _, name in ipairs(table.wrap(configs_defined)) do
                local value = configs_overrided[name] or configs_required[name]
                if value == nil then
                    value = self:extraconf("configs", name, "default")
                    -- support for the deprecated vs_runtime in add_configs
                    if name == "runtimes" and value == nil then
                        value = self:extraconf("configs", "vs_runtime", "default")
                    end
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

-- get the given configuration value of package for buildhash
function _instance:_config_for_buildhash(name)
    local value
    local configs = self:_configs_for_buildhash()
    if configs then
        value = configs[name]
    end
    return value
end

-- get the configurations of package for buildhash
-- @note on_test still need these configs
function _instance:_configs_for_buildhash()
    local configs = self._CONFIGS_FOR_BUILDHASH
    if configs == nil then
        local configs_defined = self:get("configs")
        if configs_defined then
            configs = {}
            local requireinfo = self:requireinfo()
            local configs_required = requireinfo and requireinfo.configs or {}
            local configs_overrided = requireinfo and requireinfo.configs_overrided or {}
            local ignored_configs_for_buildhash = hashset.from(requireinfo and requireinfo.ignored_configs_for_buildhash or {})
            for _, name in ipairs(table.wrap(configs_defined)) do
                if not ignored_configs_for_buildhash:has(name) then
                    local value = configs_overrided[name] or configs_required[name]
                    if value == nil then
                        value = self:extraconf("configs", name, "default")
                        -- support for the deprecated vs_runtime in add_configs
                        if name == "runtimes" and value == nil then
                            value = self:extraconf("configs", "vs_runtime", "default")
                        end
                    end
                    configs[name] = value
                end
            end
        else
            configs = false
        end
        self._CONFIGS_FOR_BUILDHASH = configs
    end
    return configs and configs or nil
end

-- compute the build hash
function _instance:_compute_buildhash()
    self._BUILDHASH_PREPRARED = true
    self:buildhash()
end

-- get the build hash
function _instance:buildhash()
    local buildhash = self._BUILDHASH
    if buildhash == nil then
        if not self._BUILDHASH_PREPRARED then
            os.raise("package:buildhash() must be called after loading package")
        end
        local function _get_buildhash(configs, opt)
            opt = opt or {}
            local str = self:plat() .. self:arch()
            local label = self:label()
            if label then
                str = str .. label
            end
            if configs then

                -- with old vs_runtime configs
                -- https://github.com/xmake-io/xmake/issues/4477
                if opt.vs_runtime then
                    configs = table.clone(configs)
                    configs.vs_runtime = configs.runtimes
                    configs.runtimes = nil
                end

                -- since luajit v2.1, the key order of the table is random and undefined.
                -- We cannot directly deserialize the table, so the result may be different each time
                local configs_order = {}
                for k, v in pairs(table.wrap(configs)) do
                    if type(v) == "table" then
                        v = string.serialize(v, {strip = true, indent = false, orderkeys = true})
                    end
                    table.insert(configs_order, k .. "=" .. tostring(v))
                end
                table.sort(configs_order)

                -- we need to be compatible with the hash value string for the previous luajit version
                local configs_str = string.serialize(configs_order, true)
                configs_str = configs_str:gsub("\"", "")
                str = str .. configs_str
            end
            if opt.sourcehash ~= false then
                local sourcehashs = hashset.new()
                for _, url in ipairs(self:urls()) do
                    local url_alias = self:url_alias(url)
                    local sourcehash = self:sourcehash(url_alias)
                    if sourcehash then
                        sourcehashs:insert(sourcehash)
                    end
                end
                if not sourcehashs:empty() then
                    local hashs = sourcehashs:to_array()
                    table.sort(hashs)
                    str = str .. "_" .. table.concat(hashs, "_")
                end
            end
            local toolchains = self:_config_for_buildhash("toolchains")
            if opt.toolchains ~= false and toolchains then
                toolchains = table.copy(table.wrap(toolchains))
                table.sort(toolchains)
                str = str .. "_" .. table.concat(toolchains, "_")
            end
            return hash.strhash128(str)
        end
        local function _get_installdir(...)
            local name = self:name():lower():gsub("::", "_")
            local dir = path.join(package.installdir(), name:sub(1, 1):lower(), name)
            if self:version_str() then
                dir = path.join(dir, self:version_str())
            end
            return path.join(dir, ...)
        end

        -- we need to be compatible with the hash value string for the previous xmake version
        -- without builtin pic configuration (< 2.5.1).
        if self:_config_for_buildhash("pic") then
            local configs = table.copy(self:_configs_for_buildhash())
            configs.pic = nil
            buildhash = _get_buildhash(configs, {sourcehash = false, toolchains = false})
            if not os.isdir(_get_installdir(buildhash)) then
                buildhash = nil
            end
        end

        -- we need to be compatible with the hash value string for the previous xmake version
        -- without sourcehash (< 2.5.2)
        if not buildhash then
            buildhash = _get_buildhash(self:_configs_for_buildhash(), {sourcehash = false, toolchains = false})
            if not os.isdir(_get_installdir(buildhash)) then
                buildhash = nil
            end
        end

        -- we need to be compatible with the previous xmake version
        -- without toolchains (< 2.6.4)
        if not buildhash then
            buildhash = _get_buildhash(self:_configs_for_buildhash(), {toolchains = false})
            if not os.isdir(_get_installdir(buildhash)) then
                buildhash = nil
            end
        end

        -- we need to be compatible with the previous xmake version
        -- with deprecated vs_runtime (< 2.8.7)
        -- @see https://github.com/xmake-io/xmake/issues/4477
        if not buildhash then
            buildhash = _get_buildhash(self:_configs_for_buildhash(), {vs_runtime = true})
            if not os.isdir(_get_installdir(buildhash)) then
                buildhash = nil
            end
        end

        -- get build hash for current version
        if not buildhash then
            buildhash = _get_buildhash(self:_configs_for_buildhash())
        end
        self._BUILDHASH = buildhash
    end
    return buildhash
end

-- get the group name
function _instance:group()
    local requireinfo = self:requireinfo()
    if requireinfo then
        return requireinfo.group
    end
end

-- get xxx_script
function _instance:script(name, generic)

    -- get script
    local script = self:get(name)
    local result = select_script(script, {plat = self:plat(), arch = self:arch()}) or generic

    -- imports some modules first
    if result and result ~= generic then
        local scope = getfenv(result)
        if scope then
            for _, modulename in ipairs(table.wrap(self:get("imports"))) do
                scope[sandbox_module.name(modulename)] = sandbox_module.import(modulename, {anonymous = true})
            end
        end
    end
    return result
end

-- do fetch tool
function _instance:_fetch_tool(opt)
    opt = opt or {}
    local fetchinfo
    local on_fetch = self:script("fetch")
    if on_fetch then
        fetchinfo = on_fetch(self, {force = opt.force,
                                    system = opt.system,
                                    require_version = opt.require_version})
        if fetchinfo and opt.require_version and opt.require_version:find(".", 1, true) then
            local version = type(fetchinfo) == "table" and fetchinfo.version
            if not (version and (version == opt.require_version or semver.satisfies(version, opt.require_version))) then
                fetchinfo = nil
            end
        end
    end
    -- we can disable to fallback fetch if on_fetch return false
    if fetchinfo == nil then
        self._find_tool = self._find_tool or sandbox_module.import("lib.detect.find_tool", {anonymous = true})
        if opt.system then
            local fetchnames = {}
            if not self:is_thirdparty() then
                table.join2(fetchnames, self:extsources())
            end
            table.insert(fetchnames, self:name())
            for _, fetchname in ipairs(fetchnames) do
                fetchinfo = self:find_tool(fetchname, opt)
                if fetchinfo then
                    break
                end
            end
        else
            fetchinfo = self:find_tool(self:name(), {require_version = opt.require_version,
                                                     cachekey = "fetch_package_xmake",
                                                     norun = true, -- we don't need to run it to check for xmake/packages, @see https://github.com/xmake-io/xmake-repo/issues/66
                                                     system = false, -- we only find it from xmake/packages, @see https://github.com/xmake-io/xmake-repo/pull/2085
                                                     force = opt.force})

            -- may be toolset, not single tool
            if not fetchinfo then
                fetchinfo = self:manifest_load()
            end
        end
    end
    return fetchinfo or nil
end

-- do fetch library
--
-- @param opt   the options, e.g. {force, system, external, require_version}
--
function _instance:_fetch_library(opt)
    opt = opt or {}
    local fetchinfo
    local on_fetch = self:script("fetch")
    if on_fetch then
        -- we cannot fetch it from system if it's cross-compilation package
        if not opt.system or (opt.system and not self:is_cross()) then
            fetchinfo = on_fetch(self, {force = opt.force,
                                        system = opt.system,
                                        external = opt.external,
                                        require_version = opt.require_version})
        end
        if fetchinfo and opt.require_version and opt.require_version:find(".", 1, true) then
            local version = fetchinfo.version
            if not (version and (version == opt.require_version or semver.satisfies(version, opt.require_version))) then
                fetchinfo = nil
            end
        end
        if fetchinfo then
            local components_base = fetchinfo.components and fetchinfo.components.__base
            if opt.external then
                fetchinfo.sysincludedirs = fetchinfo.sysincludedirs or fetchinfo.includedirs
                fetchinfo.includedirs = nil
                if components_base then
                    components_base.sysincludedirs = components_base.sysincludedirs or components_base.includedirs
                    components_base.includedirs = nil
                end
            else
                fetchinfo.includedirs = fetchinfo.includedirs or fetchinfo.sysincludedirs
                fetchinfo.sysincludedirs = nil
                if components_base then
                    components_base.includedirs = components_base.includedirs or components_base.sysincludedirs
                    components_base.sysincludedirs = nil
                end
            end
            local package_utils = sandbox_module.import("private.utils.package", {anonymous = true})
            package_utils.fetchinfo_set_concat(fetchinfo)
        end
        if fetchinfo and option.get("verbose") then
            local reponame = self:repo() and self:repo():name() or ""
            utils.cprint("checking for %s::%s ... ${color.success}%s %s", reponame, self:name(), self:name(), fetchinfo.version and fetchinfo.version or "")
        end
    end
    if fetchinfo == nil then
        if opt.system then
            local fetchnames = {}
            if not self:is_thirdparty() then
                table.join2(fetchnames, self:extsources())
            end
            table.insert(fetchnames, self:name())
            for _, fetchname in ipairs(fetchnames) do
                local components_extsources = {}
                for name, comp in pairs(self:components()) do
                    for _, extsource in ipairs(table.wrap(comp:get("extsources"))) do
                        local extsource_info = extsource:split("::")
                        if fetchname:split("::")[1] == extsource_info[1] then
                            components_extsources[name] = extsource_info[2]
                            break
                        end
                    end
                end
                fetchinfo = self:find_package(fetchname, table.join(opt, {components_extsources = components_extsources}))
                if fetchinfo then
                    break
                end
            end
        else
            fetchinfo = self:find_package("xmake::" .. self:name(), {
                                           require_version = opt.require_version,
                                           cachekey = "fetch_package_xmake",
                                           external = opt.external,
                                           force = opt.force})
        end
    end
    return fetchinfo or nil
end

-- find tool
function _instance:find_tool(name, opt)
    opt = opt or {}
    self._find_tool = self._find_tool or sandbox_module.import("lib.detect.find_tool", {anonymous = true})
    return self._find_tool(name, {cachekey = opt.cachekey or "fetch_package_system",
                                  installdir = self:installdir({readonly = true}),
                                  bindirs = self:get("bindirs"),
                                  version = true, -- we alway check version
                                  require_version = opt.require_version,
                                  check = opt.check,
                                  command = opt.command,
                                  parse = opt.parse,
                                  norun = opt.norun,
                                  system = opt.system,
                                  force = opt.force})
end

-- find package
function _instance:find_package(name, opt)
    opt = opt or {}
    self._find_package = self._find_package or sandbox_module.import("lib.detect.find_package", {anonymous = true})
    local system = opt.system
    if system == nil and not name:startswith("xmake::") then
        system = true -- find system package by default
    end
    local configs = table.clone(self:configs()) or {}
    if opt.configs then
        table.join2(configs, opt.configs)
    end
    if configs.runtimes then
        configs.runtimes = self:runtimes()
    end
    return self._find_package(name, {
                              force = opt.force,
                              installdir = self:installdir({readonly = true}),
                              bindirs = self:get("bindirs"),
                              version = true, -- we alway check version
                              require_version = opt.require_version,
                              mode = self:mode(),
                              plat = self:plat(),
                              arch = self:arch(),
                              configs = configs,
                              components = self:components_orderlist(),
                              components_extsources = opt.components_extsources,
                              buildhash = self:buildhash(), -- for xmake package or 3rd package manager, e.g. go:: ..
                              cachekey = opt.cachekey or "fetch_package_system",
                              external = opt.external,
                              system = system,
                              -- the following options is only for system::find_package
                              sourcekind = opt.sourcekind,
                              package = self,
                              funcs = opt.funcs,
                              snippets = opt.snippets,
                              includes = opt.includes})
end

-- fetch the local package info
--
-- @param opt   the fetch option, e.g. {force = true, external = false, system = true}
--
-- @return {packageinfo}, fetchfrom (e.g. xmake/system)
--
function _instance:fetch(opt)

    -- init options
    opt = opt or {}

    -- attempt to get it from cache
    local fetchinfo = self._FETCHINFO
    local usecache = opt.external == nil and opt.system == nil
    if not opt.force and usecache and fetchinfo then
        return fetchinfo
    end

    -- fetch the require version
    local require_ver = opt.version or self:requireinfo().version
    if not self:is_thirdparty() and not require_ver:find('.', 1, true) then
        -- strip branch version only system package
        require_ver = nil
    end

    -- nil: find xmake or system packages
    -- true: only find system package
    -- false: only find xmake packages
    local system = opt.system
    if system == nil then
        system = self:requireinfo().system
    end
    if self:is_thirdparty() then
        -- we need ignore `{system = true/false}` argument if be 3rd package
        -- @see https://github.com/xmake-io/xmake/issues/726
        system = nil
    end

    -- install only?
    local project = package._project()
    if project and project.policy("package.install_only") then
        system = false
    end

    -- use sysincludedirs/-isystem instead of -I?
    local external
    if opt.external ~= nil then
        external = opt.external
    else
        external = self:use_external_includes()
    end

    -- always install to the local project directory?
    -- @see https://github.com/xmake-io/xmake/pull/4376
    local install_locally
    if project and project.policy("package.install_locally") then
        install_locally = true
    end
    if install_locally == nil and self:policy("package.install_locally") then
        install_locally = true
    end
    if not self:is_local() and install_locally and system ~= true then
        local has_global = os.isfile(self:manifest_file())
        self:_mark_as_local(true)
        if has_global and not os.isfile(self:manifest_file()) then
            self:_mark_as_local(false)
        end
    end

    -- fetch binary tool?
    fetchinfo = nil
    local is_system = nil
    if self:is_binary() then

        -- only fetch it from the xmake repository first
        if not fetchinfo and system ~= true and not self:is_thirdparty() then
            fetchinfo = self:_fetch_tool({require_version = self:version_str(), force = opt.force})
            if fetchinfo then
                is_system = self._is_system
            end
        end

        -- fetch it from the system directories (disabled for cross-compilation)
        if not fetchinfo and system ~= false and not self:is_cross() then
            fetchinfo = self:_fetch_tool({system = true, require_version = require_ver, force = opt.force})
            if fetchinfo then
                is_system = true
            end
        end
    else

        -- only fetch it from the xmake repository first
        if not fetchinfo and system ~= true and not self:is_thirdparty() then
            fetchinfo = self:_fetch_library({require_version = self:version_str(), external = external, force = opt.force})
            if fetchinfo then
                is_system = self._is_system
            end
        end

        -- fetch it from the system and external package sources
        if not fetchinfo and system ~= false then
            fetchinfo = self:_fetch_library({system = true, require_version = require_ver, external = external, force = opt.force})
            if fetchinfo then
                is_system = true
            end
        end
    end

    -- save to cache
    if usecache then
        self._FETCHINFO = fetchinfo
    end

    -- we need to update the real version if it's system package
    -- @see https://github.com/xmake-io/xmake/issues/3333
    if is_system and fetchinfo and fetchinfo.version then
        local fetch_version = semver.new(fetchinfo.version)
        if fetch_version then
            self._VERSION = fetch_version
            self._VERSION_STR = fetchinfo.version
        end
    end

    -- mark as system package?
    if is_system ~= nil then
        self._is_system = is_system
    end
    return fetchinfo
end

-- exists this package?
function _instance:exists()
    return self._FETCHINFO ~= nil
end

-- fetch library dependencies
function _instance:fetch_librarydeps()
    local fetchinfo = self:fetch()
    if not fetchinfo then
        return
    end
    fetchinfo = table.copy(fetchinfo) -- avoid the cached fetchinfo be modified
    local librarydeps = self:librarydeps()
    if librarydeps then
        for _, dep in ipairs(librarydeps) do
            local depinfo = dep:fetch()
            if depinfo then
                for name, values in pairs(depinfo) do
                    if name ~= "license" and name ~= "version" then
                        fetchinfo[name] = table.wrap(fetchinfo[name])
                        table.join2(fetchinfo[name], values)
                    end
                end
            end
        end
    end
    if fetchinfo then
        for name, values in pairs(fetchinfo) do
            if name == "links" or name == "syslinks" or name == "frameworks" then
                fetchinfo[name] = table.unwrap(table.reverse_unique(table.wrap(values)))
            else
                fetchinfo[name] = table.unwrap(table.unique(table.wrap(values)))
            end
        end
    end
    return fetchinfo
end

-- get the patches of the current version
--
-- @code
-- add_patches("6.7.6", "https://cdn.kernel.org/pub/linux/kernel/v6.x/patch-6.7.6.xz",
--    "a394326aa325f8a930a4ce33c69ba7b8b454aef1107a4d3c2a8ae12908615fc4", {reverse = true})
-- @endcode
--
function _instance:patches()
    local patches = self._PATCHES
    if patches == nil then
        local patchinfos = self:get("patches")
        if patchinfos then
            local version_str = self:version_str()
            local patchinfo = patchinfos[version_str]
            if patchinfo then
                patches = {}
                patchinfo = table.wrap(patchinfo)
                for idx = 1, #patchinfo, 2 do
                    local extra = self:extraconf("patches." .. version_str, patchinfo[idx])
                    table.insert(patches , {url = patchinfo[idx], sha256 = patchinfo[idx + 1], extra = extra})
                end
            else
                -- match semver, e.g add_patches(">=1.0.0", url, sha256)
                for range, patchinfo in pairs(patchinfos) do
                    if semver.satisfies(version_str, range) then
                        patches = patches or {}
                        patchinfo = table.wrap(patchinfo)
                        for idx = 1, #patchinfo, 2 do
                            local extra = self:extraconf("patches." .. range, patchinfo[idx])
                            table.insert(patches , {url = patchinfo[idx], sha256 = patchinfo[idx + 1], extra = extra})
                        end
                    end
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
            local resourceinfo = resourceinfos[version_str]
            if resourceinfo then
                resources = {}
                resourceinfo = table.wrap(resourceinfo)
                for idx = 1, #resourceinfo, 3 do
                    local name = resourceinfo[idx]
                    resources[name] = {url = resourceinfo[idx + 1], sha256 = resourceinfo[idx + 2]}
                end
            else
                -- match semver, e.g add_resources(">=1.0.0", name, url, sha256)
                for range, resourceinfo in pairs(resourceinfos) do
                    if semver.satisfies(version_str, range) then
                        resources = resources or {}
                        resourceinfo = table.wrap(resourceinfo)
                        for idx = 1, #resourceinfo, 3 do
                            local name = resourceinfo[idx]
                            resources[name] = {url = resourceinfo[idx + 1], sha256 = resourceinfo[idx + 2]}
                        end
                    end
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

-- get the given package component
function _instance:component(name)
    return self:components()[name]
end

-- get package components
--
-- .e.g. add_components("graphics", "windows")
--
function _instance:components()
    local components = self._COMPONENTS
    if not components then
        components = {}
        for _, name in ipairs(table.wrap(self:get("components"))) do
            components[name] = component.new(name, {package = self})
        end
        self._COMPONENTS = components
    end
    return components
end

-- get package dependencies of components
--
-- @see https://github.com/xmake-io/xmake/issues/2636#issuecomment-1284787681
--
-- @code
-- add_components("graphics", {deps = "window"})
-- @endcode
--
-- or
--
-- @code
-- on_component(function (package, component))
--     component:add("deps", "window")
-- end)
-- @endcode
--
function _instance:components_deps()
    local components_deps = self._COMPONENTS_DEPS
    if not components_deps then
        components_deps = {}
        for _, name in ipairs(table.wrap(self:get("components"))) do
            components_deps[name] = self:extraconf("components", name, "deps") or self:component(name):get("deps")
        end
        self._COMPONENTS_DEPS = component_deps
    end
    return components_deps
end

-- get default components
--
-- @see https://github.com/xmake-io/xmake/issues/3164
--
-- @code
-- add_components("graphics", {default = true})
-- @endcode
--
-- or
--
-- @code
-- on_component(function (package, component))
--     component:set("default", true)
-- end)
-- @endcode
--
function _instance:components_default()
    local components_default = self._COMPONENTS_DEFAULT
    if not components_default then
        for _, name in ipairs(table.wrap(self:get("components"))) do
            if self:extraconf("components", name, "default") or self:component(name):get("default") then
                components_default = components_default or {}
                table.insert(components_default, name)
            end
        end
        self._COMPONENTS_DEFAULT = components_default or false
    end
    return components_default or nil
end

-- get package components list with dependencies order
function _instance:components_orderlist()
    local components_orderlist = self._COMPONENTS_ORDERLIST
    if not components_orderlist then
        components_orderlist = {}
        for _, name in ipairs(table.wrap(self:get("components"))) do
            table.insert(components_orderlist, name)
            table.join2(components_orderlist, self:_sort_componentdeps(name))
        end
        components_orderlist = table.reverse_unique(components_orderlist)
        self._COMPONENTS_ORDERLIST = components_orderlist
    end
    return components_orderlist
end

-- sort component deps
function _instance:_sort_componentdeps(name)
    local orderdeps = {}
    local plaindeps = self:components_deps() and self:components_deps()[name]
    for _, dep in ipairs(table.wrap(plaindeps)) do
        table.insert(orderdeps, dep)
        table.join2(orderdeps, self:_sort_componentdeps(dep))
    end
    return orderdeps
end

-- generate lto configs
function _instance:_generate_lto_configs(sourcekind)

    -- add cflags
    local configs = {}
    if sourcekind then
        local _, cc = self:tool(sourcekind)
        local cflag = sourcekind == "cxx" and "cxxflags" or "cflags"
        if cc == "cl" then
            configs[cflag] = "-GL"
        elseif cc == "clang" or cc == "clangxx" or cc == "clang_cl" then
            configs[cflag] = "-flto=thin"
        elseif cc == "gcc" or cc == "gxx" then
            configs[cflag] = "-flto"
        end
    end

    -- add ldflags and shflags
    local _, ld = self:tool("ld")
    if ld == "link" then
        configs.ldflags = "-LTCG"
        configs.shflags = "-LTCG"
    elseif ld == "clang" or ld == "clangxx" then
        configs.ldflags = "-flto=thin"
        configs.shflags = "-flto=thin"
    elseif ld == "gcc" or ld == "gxx" then
        configs.ldflags = "-flto"
        configs.shflags = "-flto"
    end
    return configs
end

-- generate sanitizer configs
function _instance:_generate_sanitizer_configs(checkmode, sourcekind)

    -- add cflags
    local configs = {}
    if sourcekind and self:has_tool(sourcekind, "cl", "clang", "clangxx", "gcc", "gxx") then
        local cflag = sourcekind == "cxx" and "cxxflags" or "cflags"
        configs[cflag] = "-fsanitize=" .. checkmode
    end

    -- add ldflags and shflags
    if self:has_tool("ld", "link", "clang", "clangxx", "gcc", "gxx") then
        configs.ldflags = "-fsanitize=" .. checkmode
        configs.shflags = "-fsanitize=" .. checkmode
    end
    return configs
end

-- generate building configs for has_xxx/check_xxx
function _instance:_generate_build_configs(configs, opt)
    opt = opt or {}
    configs = table.join(self:fetch_librarydeps() or {}, configs)
    -- since we are ignoring the runtimes of the headeronly library,
    -- we can only get the runtimes from the dependency library to detect the link.
    local runtimes = self:runtimes()
    if self:is_headeronly() and not runtimes and self:librarydeps() then
        for _, dep in ipairs(self:librarydeps()) do
            if dep:is_plat("windows") and dep:runtimes() then
                runtimes = dep:runtimes()
                break
            end
        end
    end
    if runtimes then
        -- @note we need to patch package:sourcekinds(), because it wiil be called nf_runtime for gcc/clang
        local sourcekind = opt.sourcekind or "cxx"
        self.sourcekinds = function (self)
            return sourcekind
        end
        local compiler = self:compiler(sourcekind)
        local cxflags = compiler:map_flags("runtime", runtimes, {target = self})
        configs.cxflags = table.wrap(configs.cxflags)
        table.insert(configs.cxflags, cxflags)

        local ldflags = self:linker("binary", sourcekind):map_flags("runtime", runtimes, {target = self})
        configs.ldflags = table.wrap(configs.ldflags)
        table.insert(configs.ldflags, ldflags)

        local shflags = self:linker("shared", sourcekind):map_flags("runtime", runtimes, {target = self})
        configs.shflags = table.wrap(configs.shflags)
        table.insert(configs.shflags, shflags)
        self.sourcekinds = nil
    end
    if self:config("lto") then
        local configs_lto = self:_generate_lto_configs(opt.sourcekind or "cxx")
        if configs_lto then
            for k, v in pairs(configs_lto) do
                configs[k] = table.wrap(configs[k] or {})
                table.join2(configs[k], v)
            end
        end
    end
    if self:config("asan") then
        local configs_asan = self:_generate_sanitizer_configs("address", opt.sourcekind or "cxx")
        if configs_asan then
            for k, v in pairs(configs_asan) do
                configs[k] = table.wrap(configs[k] or {})
                table.join2(configs[k], v)
            end
        end
    end
    -- enable exceptions for msvc by default
    if opt.sourcekind == "cxx" and configs.exceptions == nil and self:has_tool("cxx", "cl") then
        configs.exceptions = "cxx"
    end

    -- pass user flags to on_test, because some flags need be passed to ldflags in on_test
    -- e.g. add_requireconfs("**", {configs = {cxflags = "/fsanitize=address", ldflags = "/fsanitize=address"}})
    --
    -- @see https://github.com/xmake-io/xmake/issues/4046
    --
    for name, flags in pairs(self:configs()) do
        if name:endswith("flags") and self:extraconf("configs", name, "builtin") then
            configs[name] = table.wrap(configs[name] or {})
            table.join2(configs[name], flags)
        end
    end

    if configs and (configs.ldflags or configs.shflags) then
        configs.force = {ldflags = configs.ldflags, shflags = configs.shflags}
        configs.ldflags = nil
        configs.shflags = nil
    end

    -- check links for library
    if self:is_library() and not self:is_headeronly() and not self:is_moduleonly()
        and self:exists() then -- we need to skip it if it's in on_check, @see https://github.com/xmake-io/xmake-repo/pull/4834
        local links = table.wrap(configs.links)
        local ldflags = table.wrap(configs.ldflags)
        local frameworks = table.wrap(configs.frameworks)
        if #links == 0 and #ldflags == 0 and #frameworks == 0 then
            os.raise("package(%s): links not found!", self:name())
        end
    end
    return configs
end

-- has the given c funcs?
--
-- @param funcs     the funcs
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:has_cfuncs(funcs, opt)
    opt = opt or {}
    opt.target = self
    opt.configs = self:_generate_build_configs(opt.configs, {sourcekind = "cc"})
    return sandbox_module.import("lib.detect.has_cfuncs", {anonymous = true})(funcs, opt)
end

-- has the given c++ funcs?
--
-- @param funcs     the funcs
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:has_cxxfuncs(funcs, opt)
    opt = opt or {}
    opt.target = self
    opt.configs = self:_generate_build_configs(opt.configs, {sourcekind = "cxx"})
    return sandbox_module.import("lib.detect.has_cxxfuncs", {anonymous = true})(funcs, opt)
end

-- has the given c types?
--
-- @param types     the types
-- @param opt       the argument options, e.g. {configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:has_ctypes(types, opt)
    opt = opt or {}
    opt.target = self
    opt.configs = self:_generate_build_configs(opt.configs, {sourcekind = "cc"})
    return sandbox_module.import("lib.detect.has_ctypes", {anonymous = true})(types, opt)
end

-- has the given c++ types?
--
-- @param types     the types
-- @param opt       the argument options, e.g. {configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:has_cxxtypes(types, opt)
    opt = opt or {}
    opt.target = self
    opt.configs = self:_generate_build_configs(opt.configs, {sourcekind = "cxx"})
    return sandbox_module.import("lib.detect.has_cxxtypes", {anonymous = true})(types, opt)
end

-- has the given c includes?
--
-- @param includes  the includes
-- @param opt       the argument options, e.g. {configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:has_cincludes(includes, opt)
    opt = opt or {}
    opt.target = self
    opt.configs = self:_generate_build_configs(opt.configs, {sourcekind = "cc"})
    return sandbox_module.import("lib.detect.has_cincludes", {anonymous = true})(includes, opt)
end

-- has the given c++ includes?
--
-- @param includes  the includes
-- @param opt       the argument options, e.g. {configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:has_cxxincludes(includes, opt)
    opt = opt or {}
    opt.target = self
    opt.configs = self:_generate_build_configs(opt.configs, {sourcekind = "cxx"})
    return sandbox_module.import("lib.detect.has_cxxincludes", {anonymous = true})(includes, opt)
end

-- has the given c flags?
--
-- @param flags     the flags
-- @param opt       the argument options, e.g. { flagskey = "xxx" }
--
-- @return          true or false, errors
--
function _instance:has_cflags(flags, opt)
    local compinst = self:compiler("cc")
    return compinst:has_flags(flags, "cflags", opt)
end

-- has the given c++ flags?
--
-- @param flags     the flags
-- @param opt       the argument options, e.g. { flagskey = "xxx" }
--
-- @return          true or false, errors
--
function _instance:has_cxxflags(flags, opt)
    local compinst = self:compiler("cxx")
    return compinst:has_flags(flags, "cxxflags", opt)
end

-- has the given features?
--
-- @param features  the features, e.g. {"c_static_assert", "cxx_constexpr"}
-- @param opt       the argument options, e.g. {flags = ""}
--
-- @return          true or false, errors
--
function _instance:has_features(features, opt)
    opt = opt or {}
    opt.target = self
    return sandbox_module.import("core.tool.compiler", {anonymous = true}).has_features(features, opt)
end

-- check the size of type
--
-- @param typename  the typename
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          the type size
--
function _instance:check_sizeof(typename, opt)
    opt = opt or {}
    opt.target = self
    return sandbox_module.import("lib.detect.check_sizeof", {anonymous = true})(typename, opt)
end

-- check the given c snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:check_csnippets(snippets, opt)
    opt = opt or {}
    opt.target = self
    opt.configs = self:_generate_build_configs(opt.configs, {sourcekind = "cc"})
    return sandbox_module.import("lib.detect.check_csnippets", {anonymous = true})(snippets, opt)
end

-- check the given c++ snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:check_cxxsnippets(snippets, opt)
    opt = opt or {}
    opt.target = self
    opt.configs = self:_generate_build_configs(opt.configs, {sourcekind = "cxx"})
    return sandbox_module.import("lib.detect.check_cxxsnippets", {anonymous = true})(snippets, opt)
end

-- check the given objc snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:check_msnippets(snippets, opt)
    opt = opt or {}
    opt.target = self
    opt.configs = self:_generate_build_configs(opt.configs, {sourcekind = "mm"})
    return sandbox_module.import("lib.detect.check_msnippets", {anonymous = true})(snippets, opt)
end

-- check the given objc++ snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:check_mxxsnippets(snippets, opt)
    opt = opt or {}
    opt.target = self
    opt.configs = self:_generate_build_configs(opt.configs, {sourcekind = "mxx"})
    return sandbox_module.import("lib.detect.check_mxxsnippets", {anonymous = true})(snippets, opt)
end

-- check the given fortran snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options, e.g. {configs = {defines = ""}, linkerkind = "fc", "cxx" ...}
--
-- @return          true or false, errors
--
function _instance:check_fcsnippets(snippets, opt)
    opt = opt or {}
    opt.target = self
    opt.configs = self:_generate_build_configs(opt.configs, {sourcekind = "fc"})
    return sandbox_module.import("lib.detect.check_fcsnippets", {anonymous = true})(snippets, opt)
end

-- check the given importfiles?
--
-- @param names     the import filenames (without .pc/.cmake extension), e.g. pkgconfig::libxml-2.0, cmake::CURL
-- @param opt       the argument options
--
-- @return          true or false, errors
--
function _instance:check_importfiles(names, opt)
    opt = opt or {}
    if opt.PKG_CONFIG_PATH == nil then
        local PKG_CONFIG_PATH = {}
        local linkdirs = table.wrap(self:get("linkdirs") or "lib")
        local installdir = self:installdir()
        for _, linkdir in ipairs(linkdirs) do
            table.insert(PKG_CONFIG_PATH, path.join(installdir, linkdir, "pkgconfig"))
        end
        opt.PKG_CONFIG_PATH = PKG_CONFIG_PATH
    end
    if opt.CMAKE_PREFIX_PATH == nil then
        opt.CMAKE_PREFIX_PATH = self:installdir()
    end
    return sandbox_module.import("lib.detect.check_importfiles", {anonymous = true})(names or ("pkgconfig::" .. self:name()), opt)
end

-- the current mode is belong to the given modes?
function package._api_is_mode(interp, ...)
    return config.is_mode(...)
end

-- the current platform is belong to the given platforms?
function package._api_is_plat(interp, ...)
    local plat = package.targetplat()
    for _, v in ipairs(table.join(...)) do
        if v and plat == v then
            return true
        end
    end
end

-- the current platform is belong to the given architectures?
function package._api_is_arch(interp, ...)
    local arch = package.targetarch()
    for _, v in ipairs(table.join(...)) do
        if v and arch:find("^" .. v:gsub("%-", "%%-") .. "$") then
            return true
        end
    end
end

-- the current host is belong to the given hosts?
function package._api_is_host(interp, ...)
    return os.is_host(...)
end

-- the interpreter
function package._interpreter()
    local interp = package._INTERPRETER
    if not interp then
        interp = interpreter.new()
        interp:api_define(package.apis())
        interp:api_define(language.apis())
        package._INTERPRETER = interp
    end
    return interp
end

-- get package memcache
function package._memcache()
    return memcache.cache("core.base.package")
end

-- get project
function package._project()
    local project = package._PROJECT
    if not project then
        if os.isfile(os.projectfile()) then
            project = require("project/project")
        end
    end
    return project
end

-- get global target platform of package
function package.targetplat()
    local plat = package._memcache():get("target_plat")
    if plat == nil then
        if not plat and package._project() then
            local targetplat_root = package._project().get("target.plat")
            if targetplat_root then
                plat = targetplat_root
            end
        end
        if not plat then
            plat = config.get("plat") or os.subhost()
        end
        package._memcache():set("target_plat", plat)
    end
    return plat
end

-- get global target architecture of pacakge
function package.targetarch()
    local arch = package._memcache():get("target_arch")
    if arch == nil then
        if not arch and package._project() then
            local targetarch_root = package._project().get("target.arch")
            if targetarch_root then
                arch = targetarch_root
            end
        end
        if not arch then
            arch = config.get("arch") or os.subarch()
        end
        package._memcache():set("target_arch", arch)
    end
    return arch
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
        ,   "package.set_plat" -- deprecated
        ,   "package.set_arch" -- deprecated
        ,   "package.set_base"
        ,   "package.set_license"
        ,   "package.set_installtips"
        ,   "package.set_homepage"
        ,   "package.set_description"
        ,   "package.set_parallelize"
        ,   "package.set_sourcedir"
        ,   "package.set_cachedir"
        ,   "package.set_installdir"
        ,   "package.add_bindirs"
            -- package.add_xxx
        ,   "package.add_deps"
        ,   "package.add_urls"
        ,   "package.add_imports"
        ,   "package.add_configs"
        ,   "package.add_extsources"
        ,   "package.add_components"
        }
    ,   script =
        {
            -- package.on_xxx
            "package.on_source"
        ,   "package.on_load"
        ,   "package.on_fetch"
        ,   "package.on_check"
        ,   "package.on_download"
        ,   "package.on_install"
        ,   "package.on_test"
        ,   "package.on_component"
        }
    ,   keyvalues =
        {
            -- package.set_xxx
            "package.set_policy"
            -- package.add_xxx
        ,   "package.add_patches"
        ,   "package.add_resources"
        }
    ,   paths =
        {
            -- package.add_xxx
            "package.add_versionfiles"
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
function package.cachedir(opt)
    opt = opt or {}
    local cachedir = package._CACHEDIR
    if not cachedir then
        cachedir = os.getenv("XMAKE_PKG_CACHEDIR") or global.get("pkg_cachedir") or path.join(global.cachedir(), "packages")
        package._CACHEDIR = cachedir
    end
    if opt.rootonly then
        return cachedir
    end
    return path.join(cachedir, os.date("%y%m"))
end

-- the install directory
function package.installdir()
    local installdir = package._INSTALLDIR
    if not installdir then
        installdir = os.getenv("XMAKE_PKG_INSTALLDIR") or global.get("pkg_installdir") or path.join(global.directory(), "packages")
        package._INSTALLDIR = installdir
    end
    return installdir
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
    local instance = package._memcache():get2("packages", packagename)
    if instance then
        return instance
    end

    -- get package info
    local packageinfo = {}
    local is_thirdparty = false
    if packagename:find("::", 1, true) then

        -- get interpreter
        local interp = package._interpreter()

        -- on install script
        local on_install = function (pkg)
            local opt = {}
            local configs       = table.clone(pkg:configs()) or {}
            opt.configs         = configs
            opt.mode            = pkg:is_debug() and "debug" or "release"
            opt.plat            = pkg:plat()
            opt.arch            = pkg:arch()
            opt.require_version = pkg:version_str()
            opt.buildhash       = pkg:buildhash()
            opt.cachedir        = pkg:cachedir()
            opt.installdir      = pkg:installdir()
            if configs.runtimes then
                configs.runtimes = pkg:runtimes()
            end
            import("package.manager.install_package")(pkg:name(), opt)
        end

        -- make sandbox instance with the given script
        instance, errors = sandbox.new(on_install, {filter = interp:filter(), namespace = interp:namespace()})
        if not instance then
            return nil, errors
        end

        -- save the install script
        packageinfo.install = instance:script()

        -- is third-party package?
        if not packagename:startswith("xmake::") then
            is_thirdparty = true
        end
    end

    -- new an instance
    instance = _instance.new(packagename, scopeinfo.new("package", packageinfo))

    -- mark as system or 3rd package
    instance._is_system = true
    instance._is_thirdparty = is_thirdparty

    if is_thirdparty then
        -- add configurations for the 3rd package
        local configurations = sandbox_module.import("package.manager." .. packagename:split("::")[1]:lower() .. ".configurations", {try = true, anonymous = true})
        if configurations then
            for name, conf in pairs(configurations()) do
                instance:add("configs", name, conf)
            end
        end

        -- disable parallelize for installation
        instance:set("parallelize", false)
    end

    -- save instance to the cache
    package._memcache():set2("packages", instance)
    return instance
end

-- load the package from the project file
function package.load_from_project(packagename, project)

    -- get it directly from cache first
    local instance = package._memcache():get2("packages", packagename)
    if instance then
        return instance
    end

    -- load packages (with cache)
    local packages, errors = project.packages()
    if not packages then
        return nil, errors
    end

    -- get package info
    local packageinfo = packages[packagename]
    if packageinfo == nil and project.namespaces() then
        for _, namespace in ipairs(project.namespaces()) do
            packageinfo = packages[namespace .. "::" .. packagename]
            if packageinfo then
                packagename = namespace .. "::" .. packagename
                break
            end
        end
    end
    if packageinfo == nil then
        return
    end

    -- new an instance
    instance = _instance.new(packagename, packageinfo)
    package._memcache():set2("packages", instance)
    return instance
end

-- load the package from the package directory or package description file
function package.load_from_repository(packagename, packagedir, opt)

    -- get it directly from cache first
    opt = opt or {}
    local instance = package._memcache():get2("packages", packagename)
    if instance then
        return instance
    end

    -- load repository first for checking the xmake minimal version (deprecated)
    local repo = opt.repo
    if repo then
        repo:load()
    end

    -- find the package script path
    local scriptpath = opt.packagefile
    if not opt.packagefile and packagedir then
        scriptpath = path.join(packagedir, "xmake.lua")
    end
    if not scriptpath or not os.isfile(scriptpath) then
        return nil, string.format("package %s not found!", packagename)
    end

    -- get interpreter
    local interp = package._interpreter()

    -- we need to modify plat/arch in description scope at same time
    -- if plat/arch are passed to add_requires.
    --
    -- @see https://github.com/orgs/xmake-io/discussions/3439
    --
    -- e.g. add_requires("zlib~mingw", {plat = "mingw", arch = "x86_64"})
    --
    if opt.plat then
        package._memcache():set("target_plat", opt.plat)
    end
    if opt.arch then
        package._memcache():set("target_arch", opt.arch)
    end

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

    -- get package info
    local packageinfo = results[packagename]
    if not packageinfo then
        return nil, string.format("%s: package(%s) not found!", scriptpath, packagename)
    end

    -- new an instance
    instance = _instance.new(packagename, packageinfo, {scriptdir = path.directory(scriptpath), repo = repo})

    -- reset plat/arch
    if opt.plat then
        package._memcache():set("target_plat", nil)
    end
    if opt.arch then
        package._memcache():set("target_arch", nil)
    end

    -- save instance to the cache
    package._memcache():set2("packages", instance)
    return instance
end

-- new a package instance
function package.new(...)
    return _instance.new(...)
end


-- return module
return package
