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
import("core.base.hashset")
import("utils.progress")
import("core.cache.memcache")
import("core.project.project")
import("core.project.config")
import("core.tool.toolchain")
import("core.platform.platform")
import("core.package.package", {alias = "core_package"})
import("devel.git")
import("private.action.require.impl.repository")
import("private.action.require.impl.search_packages")
import("private.action.require.impl.utils.requirekey", {alias = "_get_requirekey"})

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
-- {build = true}: always build packages, we do not use the precompiled artifacts
--
-- simply configs as string:
--   add_requires("boost[iostreams,system,thread,key=value] >=1.78.0")
--   add_requires("boost[iostreams,thread=n] >=1.78.0")
--   add_requires("libplist[shared,debug,codecs=[foo,bar,zoo]]")
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
function _load_require(require_str, requires_extra, opt)
    opt = opt or {}

    -- parse require
    local packagename, version, reponame = _parse_require(require_str)

    -- get require extra
    local require_extra = {}
    if requires_extra then
        require_extra = requires_extra[require_str] or {}
    end

    -- parse configs from package name, and we need to ignore 3rd package name, e.g. vcpkg::boost[core], ...
    -- @see https://github.com/xmake-io/xmake/issues/5727#issuecomment-2421040107
    --
    -- e.g.
    --   add_requires("boost[iostreams,system,thread,key=value] >=1.78.0")
    --   add_requires("libplist[shared,debug,codecs=[foo,bar,zoo]]")
    --
    local packagename_raw, configs_str = packagename:match("(.-)%[(.*)%]")
    if packagename_raw and configs_str and not packagename:find("::", 1, true) then
        configs_str = configs_str:gsub("%[(.*)%]", function (w)
            return w:replace(",", ":")
        end)
        packagename = packagename_raw
        local splitinfo = configs_str:split(",", {plain = true})
        for _, v in ipairs(splitinfo) do
            local parts = v:split("=", {plain = true})
            local k = parts[1]
            v = parts[2]
            require_extra.configs = require_extra.configs or {}
            local configs = require_extra.configs
            if v then
                if v:find(":", 1 ,true) then
                    configs[k] = v:split(":", {plain = true})
                else
                    configs[k] = option.boolean(v)
                end
            else
                configs[k] = true
            end
        end
    end

    -- resolve require info
    local resolvedinfo = opt.resolvedinfo
    local requirepath = opt.requirepath
    if requirepath then
        requirepath = requirepath .. "." .. packagename
    else
        requirepath = packagename
    end
    resolvedinfo = resolvedinfo and resolvedinfo[requirepath]
    if resolvedinfo then
        -- resolve the conflict package version
        if resolvedinfo.version then
            version = resolvedinfo.version
        end
        -- resolve the conflict package configs
        if resolvedinfo.configs then
            require_extra.configs = resolvedinfo.configs
        end
    end

    -- get required building configurations
    -- we need to clone a new configs object, because the whole requireinfo will be modified later.
    -- @see https://github.com/xmake-io/xmake-repo/pull/2067
    local require_build_configs = table.clone(require_extra.configs or require_extra.config)
    if require_extra.debug then
        require_build_configs = require_build_configs or {}
        require_build_configs.debug = true
    end

    -- vs_runtime is deprecated, we should use runtimes
    if require_build_configs and require_build_configs.vs_runtime then
        require_build_configs.runtimes = require_build_configs.vs_runtime
        require_build_configs.vs_runtime = nil
        wprint("add_requires(%s): vs_runtime is deprecated, please use runtimes!", require_str)
    end

    -- check require options
    local extra_options = hashset.of("plat", "arch", "kind", "host", "targetos",
    "alias", "group", "system", "option", "default", "optional", "debug",
    "verify", "external", "private", "build", "configs", "version")
    for name, value in pairs(require_extra) do
        if not extra_options:has(name) then
            wprint("add_requires(\"%s\") has unknown option: {%s=%s}!", require_str, name, tostring(value))
        end
    end

    -- we always use xmake package, `add_requires("xmake::zlib")`,
    -- it is equivalent to `add_requires("zlib", {system = false})`
    if packagename:startswith("xmake::") then
        packagename = packagename:sub(8)
        require_extra.system = false
    end

    -- init required item
    local required = {}
    local parentinfo = opt.parentinfo
    parentinfo = parentinfo or {}
    required.packagename = packagename
    required.requireinfo =
    {
        originstr        = require_str,
        reponame         = reponame,
        version          = require_extra.version or version,
        host             = require_extra.host,      -- this package is only for host machine
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
        private          = require_extra.private,   -- default: false, private package, only for installation, do not export any links/includes and environments
        build            = require_extra.build,     -- default: false, always build packages, we do not use the precompiled artifacts
        resolvedinfo     = resolvedinfo             -- the resolved info for the conflict version/configs
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
function _load_package_from_repository(packagename, opt)
    opt = opt or {}
    local packagedir, repo = repository.packagedir(packagename, opt)
    if packagedir then
        return core_package.load_from_repository(packagename, packagedir, {plat = opt.plat, arch = opt.arch, repo = repo})
    end
end

-- load package package from base
function _load_package_from_base(package, basename, opt)
    local package_base = _load_package_from_project(basename)
    if not package_base then
        package_base = _load_package_from_repository(basename, opt)
    end
    if package_base then
        package._BASE = package_base
    end
end

-- has locked requires?
function _has_locked_requires(opt)
    opt = opt or {}
    if not option.get("upgrade") or opt.force then
        return project.policy("package.requires_lock") and os.isfile(project.requireslock())
    end
end

-- get locked requires
function _get_locked_requires(requirekey, opt)
    opt = opt or {}
    local requireslock = _memcache():get("requireslock")
    if requireslock == nil or opt.force then
        if _has_locked_requires(opt) then
            requireslock = io.load(project.requireslock())
        end
        _memcache():set("requireslock", requireslock or false)
    end
    if requireslock then
        local plat = config.plat() or os.subhost()
        local arch = config.arch() or os.subarch()
        local key = plat .. "|" .. arch
        if requireslock[key] then
            return requireslock[key][requirekey], requireslock.__meta__.version
        end
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
function _sort_packagedeps(package)
    -- we must use native deps list instead of package:deps() to generate correct librarydeps
    local orderdeps = {}
    for _, dep in ipairs(package:plaindeps()) do
        if dep then
            table.join2(orderdeps, _sort_packagedeps(dep))
            table.insert(orderdeps, dep)
        end
    end
    return orderdeps
end

-- sort library deps and generate correct link order
--
-- e.g.
--
-- a.deps = b
-- b.deps = c
--
-- orderdeps: a -> b -> c
--
function _sort_librarydeps(package, opt)
    -- we must use native deps list instead of package:deps() to generate correct link order
    local orderdeps = {}
    for _, dep in ipairs(package:plaindeps()) do
        if dep and dep:is_library() and (opt and opt.private or not dep:is_private()) then
            table.insert(orderdeps, dep)
            table.join2(orderdeps, _sort_librarydeps(dep, opt))
        end
    end
    return orderdeps
end

-- get builtin configuration default values
function _get_default_config_value_of(name)
    local defaults = {
        debug = false,
        shared = false,
        pic = true,
        lto = false,
        asan = false
    }
    return defaults[name]
end

-- add some builtin configurations to package
function _add_package_configurations(package)
    -- we can define configs to override it and it's default value in package()
    if package:extraconf("configs", "debug", "default") == nil then
        local default = _get_default_config_value_of("debug")
        package:add("configs", "debug", {builtin = true, description = "Enable debug symbols.", default = default, type = "boolean"})
    end
    if package:extraconf("configs", "shared", "default") == nil then
        -- we always use static library if it's for wasm platform
        local readonly
        if package:is_plat("wasm") then
            readonly = true
        end
        local default = _get_default_config_value_of("shared")
        package:add("configs", "shared", {builtin = true, description = "Build shared library.", default = default, readonly = readonly, type = "boolean"})
    end
    if package:extraconf("configs", "pic", "default") == nil then
        local default = _get_default_config_value_of("pic")
        package:add("configs", "pic", {builtin = true, description = "Enable the position independent code.", default = default, type = "boolean"})
    end
    if package:extraconf("configs", "lto", "default") == nil then
        package:add("configs", "lto", {builtin = true, description = "Enable the link-time build optimization.", type = "boolean"})
    end
    if package:extraconf("configs", "asan", "default") == nil then
        package:add("configs", "asan", {builtin = true, description = "Enable the address sanitizer.", type = "boolean"})
    end
    if package:extraconf("configs", "runtimes", "default") == nil then
        local values = {"MT", "MTd", "MD", "MDd",
                        "c++_static", "c++_shared", "stdc++_static", "stdc++_shared"}
        package:add("configs", "runtimes", {builtin = true, description = "Set the compiler runtimes.", type = "string", values = values, restrict = function (value)
            local values_set = hashset.from(values)
            if type(value) ~= "string" then
                return false
            end
            if value then
                for _, item in ipairs(value:split(",", {plain = true})) do
                    if not values_set:has(item) then
                        return false
                    end
                end
            end
            return true
        end})
    end
    -- deprecated, please use runtimes
    if package:extraconf("configs", "vs_runtime", "default") == nil then
        package:add("configs", "vs_runtime", {builtin = true, description = "Set vs compiler runtime.", values = {"MT", "MTd", "MD", "MDd"}})
    end
    if package:extraconf("configs", "toolchains", "default") == nil then
        package:add("configs", "toolchains", {builtin = true, description = "Set package toolchains only for cross-compilation."})
    end
    package:add("configs", "cflags", {builtin = true, description = "Set the C compiler flags."})
    package:add("configs", "cxflags", {builtin = true, description = "Set the C/C++ compiler flags."})
    package:add("configs", "cxxflags", {builtin = true, description = "Set the C++ compiler flags."})
    package:add("configs", "asflags", {builtin = true, description = "Set the assembler flags."})
    package:add("configs", "ldflags", {builtin = true, description = "Set the binary linker flags."})
    package:add("configs", "shflags", {builtin = true, description = "Set the shared library linker flags."})
end

-- select package version
function _select_package_version(package, requireinfo, locked_requireinfo)

    -- get it from the locked requireinfo
    if locked_requireinfo then
        local version = locked_requireinfo.version
        local source = "version"
        if locked_requireinfo.branch then
            source = "branch"
        elseif locked_requireinfo.tag then
            source = "tag"
        end
        return version, source
    end

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
    local is_system = requireinfo.system
    local has_versionlist = package:get("versions") or package:get("versionfiles")
    if (not has_versionlist or require_verify == false)
        and (semver.is_valid(require_version) or semver.is_valid_range(require_version)) then
        -- no version list in package() or need not verify sha256sum? try selecting this version directly
        -- @see
        -- https://github.com/xmake-io/xmake/issues/930
        -- https://github.com/xmake-io/xmake/issues/1009
        -- https://github.com/xmake-io/xmake/issues/3551
        version = require_version
        source = "version"
    elseif #package:versions() > 0 then -- select version?
        version, source = try { function () return semver.select(require_version, package:versions()) end }
    end
    if not version and has_giturl then -- select branch?
        if require_version and #require_version == 40 and require_version:match("%w+") then
            version, source = require_version, "commit"
        else
            version, source = require_version ~= "latest" and require_version or "@default", "branch"
        end
    end
    -- local source package? we use a phony version
    if not version and require_version == "latest" and #package:urls() == 0 then
        version = "latest"
        source = "version"
    end
    if not version and not package:is_thirdparty() and is_system ~= true then
        raise("package(%s): version(%s) not found!", package:name(), require_version)
    end
    return version, source
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
            if conf.restrict then
                if not conf.restrict(value) then
                    raise("package(%s %s): invalid value(%s) for config(%s)!", package:displayname(), package:version_str(), string.serialize(value, {indent = false}), name)
                end
            elseif conf.values then
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
        else
            raise("package(%s %s): invalid config(%s), please run `xmake require --info %s` to get all configurations!", package:displayname(), package:version_str(), name, package:name())
        end
    end
end

-- check package toolchains
function _check_package_toolchains(package)
    if package:toolchains() then
        for _, toolchain_inst in pairs(package:toolchains()) do
            if not toolchain_inst:check() then
                raise("toolchain(\"%s\"): not found!", toolchain_inst:name())
            end
        end
    else
        -- maybe this package is host package, it's platform and toolchain has been not checked yet.
        local platform_inst = platform.load(package:plat(), package:arch(), {host = package:is_host()})
        if not platform_inst:check() then
            raise("no any matched platform for this package(%s)!", package:name())
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
    -- pass root configs to top library package
    requireinfo.configs = requireinfo.configs or {}
    if opt.is_toplevel then
        requireinfo.is_toplevel = true

        -- we always pass some configurations from toplevel even it's headeronly, because it's library deps need inherit them
        -- @see https://github.com/xmake-io/xmake/issues/2688
        if package:is_library() then
            requireinfo.configs.toolchains = requireinfo.configs.toolchains or project.get("target.toolchains")
            if project.policy("package.inherit_external_configs") then
                requireinfo.configs.toolchains = requireinfo.configs.toolchains or get_config("toolchain")
            end
        end
        requireinfo.configs.runtimes = requireinfo.configs.runtimes or project.get("target.runtimes")
        if project.policy("package.inherit_external_configs") then
            requireinfo.configs.runtimes = requireinfo.configs.runtimes or get_config("runtimes") or get_config("vs_runtime")
        end
        if type(requireinfo.configs.runtimes) == "table" then
            requireinfo.configs.runtimes = table.concat(requireinfo.configs.runtimes, ",")
        end
        if requireinfo.configs.lto == nil then
            requireinfo.configs.lto = project.policy("build.optimization.lto")
        end
        if requireinfo.configs.asan == nil then
            requireinfo.configs.asan = project.policy("build.sanitizer.address")
        end
    end
    -- but we will ignore some configs for buildhash in the headeronly, moduleonly and host/binary package
    -- @note on_test still need these configs, @see https://github.com/xmake-io/xmake/issues/4124
    if package:is_headeronly() or package:is_moduleonly() or (package:is_binary() and not package:is_cross()) then
        requireinfo.ignored_configs_for_buildhash = {"runtimes", "toolchains", "lto", "asan", "pic"}
    end
end

-- finish requireinfo
function _finish_requireinfo(requireinfo, package)
    requireinfo.configs = requireinfo.configs or {}
    if package:is_plat("windows") then
        -- @see https://github.com/xmake-io/xmake/issues/4477#issuecomment-1913249489
        -- @note its buildhash will be ignored for headeronly
        local runtimes = requireinfo.configs.runtimes
        if runtimes then
            runtimes = runtimes:split(",")
        else
            runtimes = {}
        end
        if not table.contains(runtimes, "MT", "MD", "MTd", "MDd") then
            local vs_runtime_default = project.policy("build.c++.msvc.runtime")
            if vs_runtime_default and is_mode("debug") then
                vs_runtime_default = vs_runtime_default .. "d"
            end
            table.insert(runtimes, vs_runtime_default or "MT")
        end
        requireinfo.configs.runtimes = table.concat(runtimes, ",")
    end
    -- we need to ensure readonly configs
    for _, name in ipairs(table.keys(requireinfo.configs)) do
        local current = requireinfo.configs[name]
        local default = package:extraconf("configs", name, "default")
        local readonly = package:extraconf("configs", name, "readonly")
        if name == "runtimes" then
            -- vs_runtime is deprecated, but we need also support it now.
            if default == nil then
                default = package:extraconf("configs", "vs_runtime", "default")
            end
            if readonly == nil then
                readonly = package:extraconf("configs", "vs_runtime", "readonly")
            end
            if default ~= nil or readonly ~= nil then
                wprint("please use add_configs(\"runtimes\") instead of add_configs(\"vs_runtime\").")
            end
        end
        if readonly and current ~= default then
            wprint("configs.%s is readonly in package(%s), it's always %s", name, package:name(), default)
            -- package:config() will use default value after loading package
            requireinfo.configs[name] = nil
        end
    end
    -- sync default value to prevent cache mismatch (buildhash)
    -- @see https://github.com/xmake-io/xmake/pull/4324
    for k, v in pairs(requireinfo.configs) do
        local default = _get_default_config_value_of(k)
        if v == default then
            requireinfo.configs[k] = nil
        end
    end

    -- all binary packages are host package
    -- we need to synchronize the setup to requireinfo so that all its dependent packages inherit from it.
    if package:is_binary() then
        requireinfo.host = true
    end
end

-- merge requireinfo from `add_requireconfs()`
--
-- add_requireconfs("*",                         {system = false, configs = {runtimes = "MD"}})
-- add_requireconfs("lib*",                      {system = false, configs = {runtimes = "MD"}})
-- add_requireconfs("libwebp",                   {system = false, configs = {runtimes = "MD"}})
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

    -- Append requireconf_extra into requireinfo
    -- and the configs of add_requires have a higher priority than add_requireconfs.
    --
    -- e.g.
    -- add_requireconfs("*", {configs = {debug = false}})
    -- add_requires("foo", "bar", {configs = {debug = true}})
    --
    -- foo and bar will be debug mode
    --
    -- We can also override the configs of add_requires
    --
    -- e.g.
    -- add_requires("zlib 1.2.11")
    -- add_requireconfs("zlib", {override = true, version = "1.2.10"})
    --
    -- We override the version of zlib to 1.2.10
    --
    -- If the same dependency is matched to multiple configurations,
    -- the configurations are merged by default,
    -- and if override is set, then it rewrites the previous configurations.
    --
    for _, item in ipairs(requireconf_result) do
        local requireconf_extra = item.requireconf_extra
        if requireconf_extra then
            -- preprocess requireconf_extra, (debug, override ..)
            local override = requireconf_extra.override
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
    end
end

-- get package key
function _get_packagekey(packagename, requireinfo, version)
    return _get_requirekey(requireinfo, {name = packagename,
                                         host = requireinfo.host,
                                         plat = requireinfo.plat,
                                         arch = requireinfo.arch,
                                         kind = requireinfo.kind,
                                         version = version or requireinfo.version})
end

-- get locked package key
function _get_packagelock_key(requireinfo)
    local requirestr  = requireinfo.originstr
    local key         = _get_requirekey(requireinfo, {hash = true})
    return string.format("%s#%s", requirestr, key)
end

-- inherit some builtin configs of parent package if these config values are not default value
-- e.g. add_requires("libpng", {configs = {runtimes = "MD", pic = false}})
--
function _inherit_parent_configs(requireinfo, package, parentinfo)
    if package:is_library() then
        local requireinfo_configs = requireinfo.configs or {}
        local parentinfo_configs  = parentinfo.configs or {}
        if not requireinfo_configs.shared then
            if requireinfo_configs.runtimes == nil then
                requireinfo_configs.runtimes = parentinfo_configs.runtimes
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
        if parentinfo.host then
            requireinfo.host = parentinfo.host
        end
        requireinfo_configs.toolchains = requireinfo_configs.toolchains or parentinfo_configs.toolchains
        requireinfo_configs.runtimes = requireinfo_configs.runtimes or parentinfo_configs.runtimes
        requireinfo_configs.lto = requireinfo_configs.lto or parentinfo_configs.lto
        requireinfo_configs.asan = requireinfo_configs.asan or parentinfo_configs.asan
        requireinfo.configs = requireinfo_configs
    end
end

-- select artifacts for msvc
function _select_artifacts_for_msvc(package, artifacts_manifest)
    local msvc
    for _, instance in ipairs(package:toolchains()) do
        if instance:name() == "msvc" then
            msvc = instance
            break
        end
    end
    if not msvc then
        msvc = toolchain.load("msvc", {plat = package:plat(), arch = package:arch()})
    end
    local vcvars = msvc:config("vcvars")
    if vcvars then
        local vs_toolset = vcvars.VCToolsVersion
        if vs_toolset and semver.is_valid(vs_toolset) then
            local artifacts_infos = {}
            for key, artifacts_info in pairs(artifacts_manifest) do
                if key:startswith(package:plat() .. "-" .. package:arch() .. "-vc") and key:endswith("-" .. package:buildhash()) then
                    table.insert(artifacts_infos, artifacts_info)
                end
            end
            -- we sort them to select a newest toolset to get better optimzed performance
            table.sort(artifacts_infos, function (a, b)
                if a.toolset and b.toolset then
                    return semver.compare(a.toolset, b.toolset) > 0
                else
                    return false
                end
            end)
            if package:config("shared") or package:is_binary() then
                -- executable programs and dynamic libraries only need to select the latest toolset
                return artifacts_infos[1]
            else
                -- static libraries need to consider toolset compatibility
                for _, artifacts_info in ipairs(artifacts_infos) do
                    -- toolset is backwards compatible
                    --
                    -- @see https://github.com/xmake-io/xmake/issues/1513
                    -- https://docs.microsoft.com/en-us/cpp/porting/binary-compat-2015-2017?view=msvc-160
                    if artifacts_info.toolset and semver.compare(vs_toolset, artifacts_info.toolset) >= 0 then
                        return artifacts_info
                    end
                end
            end
        end
    end
end

-- select artifacts for generic
function _select_artifacts_for_generic(package, artifacts_manifest)
    local buildid = package:plat() .. "-" .. package:arch() .. "-" .. package:buildhash()
    return artifacts_manifest[buildid]
end

-- select to use precompiled artifacts?
function _select_artifacts(package, artifacts_manifest)
    -- the precompile policy is disabled in package?
    if package:policy("package.precompiled") == false then
        return
    end
    -- the precompile policy is disabled in project?
    if os.isfile(os.projectfile()) and project.policy("package.precompiled") == false then
        return
    end
    local artifacts_info
    if package:is_plat("windows") then -- for msvc
        artifacts_info = _select_artifacts_for_msvc(package, artifacts_manifest)
    else
        artifacts_info = _select_artifacts_for_generic(package, artifacts_manifest)
    end
    if artifacts_info then
        package:artifacts_set(artifacts_info)
    end
end

-- select package runtimes
function _select_package_runtimes(package)
    local runtimes = package:config("runtimes")
    if runtimes then
        local runtimes_supported = hashset.new()
        local toolchains = package:toolchains() or platform.load(package:plat(), package:arch()):toolchains()
        if toolchains then
            for _, toolchain_inst in ipairs(toolchains) do
                if toolchain_inst:is_standalone() and toolchain_inst:get("runtimes") then
                    for _, runtime in ipairs(table.wrap(toolchain_inst:get("runtimes"))) do
                        runtimes_supported:insert(runtime)
                    end
                end
            end
        end
        local runtimes_current = {}
        for _, runtime in ipairs(table.wrap(runtimes:split(",", {plain = true}))) do
            if runtimes_supported:has(runtime) then
                table.insert(runtimes_current, runtime)
            end
        end
        -- we need update runtimes for buildhash, configs ...
        --
        -- we use configs_overrided to override configs in configs and buildhash,
        -- but we shouldn't modify requireinfo.configs directly as it affects the package cache key
        --
        -- @see https://github.com/xmake-io/xmake/issues/4477#issuecomment-1913185727
        local requireinfo = package:requireinfo()
        if requireinfo then
            requireinfo.configs_overrided = requireinfo.configs_overrided or {}
            requireinfo.configs_overrided.runtimes = #runtimes_current > 0 and table.concat(runtimes_current, ",") or nil
            package:_invalidate_configs()
        end
    end
end

-- load required packages
function _load_package(packagename, requireinfo, opt)

    -- check circular dependency
    opt = opt or {}
    if opt.requirepath then
        local splitinfo = opt.requirepath:split(".", {plain = true})
        if #splitinfo > 3 and
            splitinfo[1] == splitinfo[#splitinfo - 1] and
            splitinfo[2] == splitinfo[#splitinfo] then
            raise("circular dependency(%s) detected in package(%s)!", opt.requirepath, splitinfo[1])
        end
    end

    -- strip trailng ~tag, e.g. zlib~debug
    local displayname
    if packagename:find('~', 1, true) then
        displayname = packagename
        local splitinfo = packagename:split('~', {plain = true, limit = 2})
        packagename = splitinfo[1]
        requireinfo.alias = requireinfo.alias or displayname
        requireinfo.label = splitinfo[2]
    end

    -- save requirekey
    local requirekey = _get_packagelock_key(requireinfo)
    requireinfo.requirekey = requirekey

    -- get locked requireinfo
    local locked_requireinfo = get_locked_requireinfo(requireinfo)

    -- load package from project first
    local package
    if os.isfile(os.projectfile()) then
        package = _load_package_from_project(packagename)
        if package and package:namespace() then
            packagename = package:namespace() .. "::" .. packagename
            if displayname then
                displayname = package:namespace() .. "::" .. displayname
            end
        end
    end

    -- load package from repositories
    local from_repo = false
    if not package then
        package = _load_package_from_repository(packagename, {
            plat = requireinfo.plat,
            arch = requireinfo.arch,
            name = requireinfo.reponame,
            locked_repo = locked_requireinfo and locked_requireinfo.repo})
        if package then
            from_repo = true
        end
    end

    -- load base package
    if package and package:get("base") then
        _load_package_from_base(package, package:get("base", {
            name = requireinfo.reponame, locked_repo = locked_requireinfo and locked_requireinfo.repo}))
    end

    -- load package from system
    local system = requireinfo.system
    if system == nil then
        system = opt.system
    end
    if not package and (system ~= false or packagename:find("::", 1, true)) then
        package = _load_package_from_system(packagename)
    end

    -- check unknown package
    if not package then
        cprint("${bright color.warning}note: ${clear}the following packages were not found in any repository (check if they are spelled correctly):")
        local tips
        local possible_package = get_possible_package(packagename)
        if possible_package then
            tips = string.format(", maybe ${bright}%s %s${clear} in %s", possible_package.name, possible_package.version, possible_package.reponame)
        end
        cprint("  -> %s%s", packagename, tips or "")
        raise("package(%s) not found!", packagename)
    end

    -- init requireinfo
    _init_requireinfo(requireinfo, package, {is_toplevel = not opt.parentinfo})

    -- merge requireinfo from `add_requireconfs()`
    _merge_requireinfo(requireinfo, opt.requirepath)

    -- inherit some builtin configs of parent package, e.g. runtimes, pic
    if opt.parentinfo then
        _inherit_parent_configs(requireinfo, package, opt.parentinfo)
    end

    -- finish requireinfo
    _finish_requireinfo(requireinfo, package)

    -- save require info
    package:requireinfo_set(requireinfo)

    -- only load toolchain package and its deps
    if opt.toolchain then
        if package:is_toplevel() and not package:is_toolchain()then
            return
        end
    end

    -- init urls source
    package:_init_source()

    -- select package version
    local version, source = _select_package_version(package, requireinfo, locked_requireinfo)
    if version then
        package:version_set(version, source)
        package:data_set("__locked_requireinfo", locked_requireinfo)
    end

    -- get package key
    local packagekey = _get_packagekey(packagename, requireinfo, version)

    -- get package from cache first
    local package_cached = _memcache():get2("packages", packagekey)
    if package_cached then
        -- since toplevel is not part of packagekey, we need to ensure it's part of the cached package table too
        if requireinfo.is_toplevel and not package_cached:is_toplevel() then
            package_cached:requireinfo().is_toplevel = true
        end
        -- mark this cached package.requireinfo as override
        -- @see https://github.com/xmake-io/xmake/issues/4078
        if requireinfo.override then
            package_cached:requireinfo().override = true
        end
        return package_cached
    end

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

    -- we need to check package toolchains before on_load and select runtimes,
    -- because we will call compiler-specific apis in on_load/on_fetch/find_package ..
    --
    -- @see https://github.com/xmake-io/xmake/pull/5466
    -- https://github.com/xmake-io/xmake/issues/4596#issuecomment-2014528801
    _check_package_toolchains(package)

    -- we need to select package runtimes before computing buildhash
    -- @see https://github.com/xmake-io/xmake/pull/4630#issuecomment-1910216561
    _select_package_runtimes(package)

    -- pre-compute the package buildhash
    package:_compute_buildhash()

    -- save artifacts info, we need to add it at last before buildhash need depend on package configurations
    -- it will switch to install precompiled binary package from xmake-mirror/build-artifacts
    if from_repo and not option.get("build") and not requireinfo.build and requireinfo.system ~= true then
        local artifacts_manifest = repository.artifacts_manifest(packagename, version)
        if artifacts_manifest then
            _select_artifacts(package, artifacts_manifest)
        end
    end

    -- we need to check package toolchains before on_load,
    -- because we will call compiler-specific apis in on_load/on_fetch/find_package ..
    --
    -- @see https://github.com/xmake-io/xmake/pull/5466
    -- https://github.com/xmake-io/xmake/issues/4596#issuecomment-2014528801
    _check_package_toolchains(package)

    -- do load
    package:_load()

    -- load all components
    for _, component in pairs(package:components()) do
        component:_load()
    end

    -- load environments from the manifest to enable the environments of on_install()
    package:envs_load()

    -- save this package package to cache
    _memcache():set2("packages", packagekey, package)

    -- load ok
    package:_mark_as_loaded()
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
        local package = _load_package(requireitem.name, requireinfo, table.join(opt, {requirepath = requirepath}))

        -- maybe package not found and optional
        if package then

            -- load dependent packages and save them first of this package
            if not package._DEPS then
                if package:get("deps") and opt.nodeps ~= true then

                    -- load dependent packages and do not load system/3rd packages for package/deps()
                    local _, plaindeps = _load_packages(package:get("deps"), {requirepath = requirepath,
                                                        requires_extra = package:extraconf("deps") or {},
                                                        parentinfo = requireinfo,
                                                        nodeps = opt.nodeps,
                                                        resolvedinfo = opt.resolvedinfo,
                                                        system = false})
                    for _, dep in ipairs(plaindeps) do
                        dep:parents_add(package)
                    end
                    package._PLAINDEPS = plaindeps
                    package._ORDERDEPS = table.unique(_sort_packagedeps(package))
                    package._LIBRARYDEPS = table.reverse_unique(_sort_librarydeps(package))
                    package._LIBRARYDEPS_WITH_PRIVATE = table.reverse_unique(_sort_librarydeps(package, {private = true}))
                    -- we always need load dependencies everytime
                    -- @see https://github.com/xmake-io/xmake/issues/4522
                    local packagedeps = {}
                    for _, dep in ipairs(package._ORDERDEPS) do
                        table.insert(packages, dep)
                        packagedeps[dep:name()] = dep
                    end
                    package._DEPS = packagedeps
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
        for _, parent in ipairs(parents) do
            table.insert(parentnames, parent:displayname())
        end
        if #parentnames == 0 then
            return
        end
        return table.concat(parentnames, ",")
    end
end

-- get require paths
function _get_requirepaths(package)
    local requirepaths = {}
    local parents = package:parents()
    if parents and #parents > 0 then
        for _, parent in ipairs(parents) do
            for _, requirepath in ipairs(_get_requirepaths(parent)) do
                table.insert(requirepaths, requirepath .. "." .. package:name())
            end
        end
        -- we also need to resolve requires conflict in toplevel, if `package.sync_requires_to_deps` policy is enabled.
        -- @see https://github.com/xmake-io/xmake/issues/5745#issuecomment-2513951471
        if project.policy("package.sync_requires_to_deps") then
            table.insert(requirepaths, package:name())
        end
    else
        table.insert(requirepaths, package:name())
    end
    return requirepaths
end

-- get compatibility key
function _get_package_compatkey(dep)
    local key = dep:plat() .. "/" .. dep:arch() .. "/" .. (dep:kind() or "")
    if dep:is_system() then
        key = key .. "/system"
    end
    local resolve_depconflict = project.policy("package.resolve_depconflict")
    if resolve_depconflict == nil then
        resolve_depconflict = dep:policy("package.resolve_depconflict")
    end
    if resolve_depconflict == false then
        if dep:version_str() then
            key = key .. "/" .. dep:version_str()
        end
        local configs = dep:requireinfo().configs
        if configs then
            local configs_order = {}
            for k, v in pairs(configs) do
                if type(v) == "table" then
                    v = string.serialize(v, {strip = true, indent = false, orderkeys = true})
                end
                table.insert(configs_order, k .. "=" .. tostring(v))
            end
            table.sort(configs_order)
            key = key .. ":" .. string.serialize(configs_order, true)
        end

    end
    return key
end

-- get package compatibility info
function _get_package_compatinfo(package)
    local compatinfo = {name = package:name()}
    if package:data("__locked_requireinfo") then
        compatinfo.locked = true
        compatinfo.versions = hashset.from(table.wrap(package:version_str()))
        return compatinfo
    end

    -- get compatible version range
    local requireinfo = package:requireinfo()
    local require_version = requireinfo.version
    if require_version then
        compatinfo.require_version = require_version
        if semver.is_valid(require_version) or semver.is_valid_range(require_version) then
            local versions = hashset.new()
            for _, version in ipairs(package:versions()) do
                if semver.satisfies(version, require_version) then
                    versions:insert(version)
                end
            end
            compatinfo.versions = versions
        elseif require_version == "latest" then
            compatinfo.versions = hashset.from(table.wrap(package:versions()))
        else
            compatinfo.versions = hashset.from(table.wrap(require_version))
        end
    else
        compatinfo.versions = hashset.from(table.wrap(package:versions()))
    end
    return compatinfo
end

-- check and resolve package conflicts
function _check_and_resolve_package_depconflicts_impl(package, name, deps, resolvedinfo)

    -- check version compatibility
    local versions
    for _, dep in ipairs(deps) do
        local compatinfo = _get_package_compatinfo(dep)
        assert(compatinfo.versions)

        if versions then
            for version in versions:items() do
                if not compatinfo.versions:has(version) then
                    versions:remove(version)
                end
            end
        else
            versions = compatinfo.versions
        end
    end

    if not versions or versions:empty() then
        print("package(%s): add_deps(%s, ...)", package:name(), name)
        for idx, dep in ipairs(deps) do
            cprint("  ${color.warning}->${clear} %s %s ${dim}%s",
                dep:displayname(), dep:version_str() or "", get_configs_str(dep))
        end
        print("we can use add_requireconfs(\"**.%s\", {override = true, version = \"x.x.x\"}) to override version.", name)
        raise("package(%s): conflict version dependencies!", name)
    end

    -- check configs compatibility
    local prevkey
    local configs
    local configs_conflict = false
    for _, dep in ipairs(deps) do
        local key = _get_package_compatkey(dep)
        if prevkey then
            if prevkey ~= key then
                configs_conflict = true
                break
            end
        else
            prevkey = key
        end
        local depconfigs = dep:requireinfo().configs
        if configs and depconfigs then
            for k, v in pairs(depconfigs) do
                local oldv = configs[k]
                if oldv ~= nil then
                    local v_key = tostring(v)
                    local oldv_key = tostring(oldv)
                    if type(v) == "table" then
                        v_key = string.serialize(v, {strip = true, indent = false, orderkeys = true})
                    end
                    if type(oldv) == "table" then
                        oldv_key = string.serialize(oldv, {strip = true, indent = false, orderkeys = true})
                    end
                    if v_key ~= oldv_key then
                        configs_conflict = true
                        break
                    end
                else
                    configs[k] = v
                end
            end
        else
            configs = depconfigs
        end
    end
    if configs_conflict then
        print("package(%s): add_deps(%s, ...)", package:name(), name)
        for idx, dep in ipairs(deps) do
            cprint("  ${color.warning}->${clear} %s %s ${dim}%s",
                dep:displayname(), dep:version_str() or "", get_configs_str(dep))
        end
        print("we can use add_requireconfs(\"**.%s\", {override = true, configs = {}}) to override configs.", name)
        raise("package(%s): conflict configs dependencies!", name)
    end

    -- resolve compatible version for all deps
    if versions and not versions:empty() then
        local version_best
        for version in versions:items() do
            if version_best == nil or semver.compare(version, version_best) > 0 then
                version_best = version
            end
        end
        if version_best then
            for _, dep in ipairs(deps) do
                for _, requirepath in ipairs(_get_requirepaths(dep)) do
                    resolvedinfo[requirepath] = {version = version_best}
                end
            end
        end
    end

    -- resolve configs
    if configs then
        for _, dep in ipairs(deps) do
            for _, requirepath in ipairs(_get_requirepaths(dep)) do
                resolvedinfo[requirepath] = resolvedinfo[requirepath] or {}
                resolvedinfo[requirepath].configs = configs
            end
        end
    end
end

-- check and resolve dependencies conflicts
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
function _check_and_resolve_package_depconflicts(package, resolvedinfo)
    local some_packagedeps = {}
    for _, dep in ipairs(package:librarydeps()) do
        local deps = some_packagedeps[dep:name()]
        if deps == nil then
            deps = {}
            some_packagedeps[dep:name()] = deps
        end
        table.insert(deps, dep)
    end
    for name, deps in pairs(some_packagedeps) do
        if #deps > 1 then
            _check_and_resolve_package_depconflicts_impl(package, name, deps, resolvedinfo)
        end
    end
end

-- must depend on the given package?
function _must_depend_on(package, dep)
    local manifest = package:manifest_load()
    if manifest and manifest.librarydeps then
        local librarydeps = hashset.from(manifest.librarydeps)
        return librarydeps:has(dep:name())
    end
    -- If we mark it as public, even if binary package is already installed,
    -- we need also to install it's public dep and export the it's envs.
    --
    -- @see https://github.com/xmake-io/xmake-repo/pull/6207
    -- https://github.com/xmake-io/xmake/pull/6101
    if package:is_binary() and package:extraconf("deps", dep:name(), "public") then
        return true
    end
end

-- compatible with all previous link dependencies?
-- @see https://github.com/xmake-io/xmake/issues/2719
function _compatible_with_previous_librarydeps(package, opt)

    -- skip to check compatibility if installation has been finished
    opt = opt or {}
    if opt.install_finished then
        return true
    end

    -- check strict compatibility for librarydeps?
    local strict_compatibility = project.policy("package.librarydeps.strict_compatibility")
    if strict_compatibility == nil then
        strict_compatibility = package:policy("package.librarydeps.strict_compatibility")
    end
    -- and we can disable it manually, @see https://github.com/xmake-io/xmake/pull/3738
    if strict_compatibility == false then
       return true
    end

    -- compute the buildhash for current librarydeps
    local depnames = hashset.new()
    local depinfos_curr = {}
    for _, dep in ipairs(package:librarydeps()) do
        if strict_compatibility or dep:policy("package.strict_compatibility") then
            depinfos_curr[dep:name()] = {
                version = dep:version_str(),
                buildhash = dep:buildhash()
            }
            depnames:insert(dep:name())
        end
    end

    -- compute the buildhash for previous librarydeps
    local depinfos_prev = {}
    local manifest = package:manifest_load()
    if manifest and manifest.librarydeps then
        local deps = manifest.deps or {}
        for _, depname in ipairs(manifest.librarydeps) do
            if strict_compatibility or (package:dep(depname) and package:dep(depname):policy("package.strict_compatibility")) or depinfos_curr[depname] then
                local depinfo = deps[depname]
                if depinfo and depinfo.buildhash then
                    depinfos_prev[depname] = depinfo
                    depnames:insert(depname)
                end
            end
        end
    end

    -- no any dependencies
    if depnames:empty() then
        return true
    end

    -- is compatible?
    local is_compatible = true
    local compatible_tips = {}
    for _, depname in depnames:keys() do
        local depinfo_prev = depinfos_prev[depname]
        local depinfo_curr = depinfos_curr[depname]
        if depinfo_prev and depinfo_curr then
            if depinfo_prev.buildhash ~= depinfo_curr.buildhash then
                is_compatible = false
                table.insert(compatible_tips, ("*%s"):format(depname))
            end
        elseif depinfo_prev then
            is_compatible = false
            table.insert(compatible_tips, ("-%s"):format(depname))
        elseif depinfo_curr then
            is_compatible = false
            table.insert(compatible_tips, ("+%s"):format(depname))
        end
    end
    if not is_compatible and #compatible_tips > 0 then
        package:data_set("librarydeps.compatible_tips", compatible_tips)
    end
    if not is_compatible then
        package:data_set("force_reinstall", true)
    end
    return is_compatible
end

-- get possible package
function get_possible_package(packagename)
    local packages_possible = search_packages("*", {description = false})
    if packages_possible then
        packages_possible = packages_possible["*"]
    end
    local result
    local distance_min
    for name, info in pairs(packages_possible) do
        local distance = packagename:levenshtein(info.name)
        if (distance_min == nil or distance < distance_min) and distance < 5 then
            distance_min = distance
            result = info
        end
    end
    return result
end

-- the cache directory
function cachedir()
    return path.join(global.directory(), "cache", "packages")
end

-- this package should be install?
function should_install(package, opt)
    opt = opt or {}
    if package:is_template() then
        return false
    end
    if not opt.install_finished and package:policy("package.install_always") then
        return true
    end
    if package:exists() and _compatible_with_previous_librarydeps(package, opt) then
        return false
    end
    -- we don't need to install it if this package only need to be fetched
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
        for _, parent in ipairs(package:parents()) do
            if should_install(parent, opt) and not parent:exists() then
                return true
            end

            -- if the existing parent package is already using it,
            -- then even if it is an optional package, you must make sure to install it
            --
            -- @see https://github.com/xmake-io/xmake/issues/1460
            --
            if parent:exists() and not option.get("force") and _must_depend_on(parent, package) then
                -- mark this package as non-optional because parent package need it
                local requireinfo = package:requireinfo()
                if requireinfo.optional then
                    requireinfo.optional = nil
                end
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
    if package:is_host() then
        table.insert(configs, "host")
    end
    local requireinfo = package:requireinfo()
    if requireinfo then
        if requireinfo.plat then
            table.insert(configs, requireinfo.plat)
        end
        if requireinfo.arch then
            table.insert(configs, requireinfo.arch)
        end
        if requireinfo.kind then
            table.insert(configs, requireinfo.kind)
        end
        local ignored_configs_for_buildhash = hashset.from(requireinfo.ignored_configs_for_buildhash or {})
        local configs_overrided = requireinfo.configs_overrided or {}
        for k, v in pairs(requireinfo.configs) do
            if not ignored_configs_for_buildhash:has(k) then
                v = configs_overrided[k] or v
                if type(v) == "boolean" then
                    table.insert(configs, k .. ":" .. (v and "y" or "n"))
                else
                    table.insert(configs, k .. ":" .. string.serialize(v, {strip = true, indent = false}))
                end
            end
        end
    end
    local compatible_tips = package:data("librarydeps.compatible_tips")
    if compatible_tips then
        table.insert(configs, "deps:" .. table.concat(compatible_tips, ","))
    end
    local parents_str = _get_parents_str(package)
    if parents_str then
        table.insert(configs, "from:" .. parents_str)
    end
    local license = package:get("license")
    if license then
        table.insert(configs, "license:" .. license)
    end
    local configs_str = #configs > 0 and "[" .. table.concat(configs, ", ") .. "]" or ""
    local limitwidth = math.floor(os.getwinsize().width * 2 / 3)
    if #configs_str > limitwidth then
        configs_str = configs_str:sub(1, limitwidth) .. " ..)"
    end
    local resolvedinfo = requireinfo.resolvedinfo
    if resolvedinfo then
        configs_str = configs_str .. " " .. "${color.warning}(conflict resolved)${clear}"
    end
    return configs_str
end

-- get locked requireinfo
function get_locked_requireinfo(requireinfo, opt)
    local requirekey = requireinfo.requirekey
    local locked_requireinfo, requireslock_version
    if _has_locked_requires(opt) and requirekey then
        locked_requireinfo, requireslock_version = _get_locked_requires(requirekey, opt)
        if requireslock_version and semver.compare(project.requireslock_version(), requireslock_version) < 0 then
            locked_requireinfo = nil
        end
    end
    return locked_requireinfo, requireslock_version
end

-- load requires
function load_requires(requires, requires_extra, opt)
    opt = opt or {}
    local requireitems = {}
    for _, require_str in ipairs(requires) do
        local packagename, requireinfo = _load_require(require_str, requires_extra, opt)
        table.insert(requireitems, {name = packagename, info = requireinfo})
    end
    return requireitems
end

-- load all required packages
function load_packages(requires, opt)
    opt = opt or {}
    local unique = {}
    local packages = {}
    local resolvedinfo = {}
    for _, package in ipairs((_load_packages(requires, table.clone(opt)))) do
        if package:is_toplevel() then
            _check_and_resolve_package_depconflicts(package, resolvedinfo)
        end
        local key = _get_packagekey(package:name(), package:requireinfo())
        if not unique[key] then
            table.insert(packages, package)
            unique[key] = true
        end
    end

    -- we need to reload packages with new resolved deps if there are some dep conflicts
    if not table.empty(resolvedinfo) then
        for _, package in ipairs(packages) do
            local installdir = package:installdir({readonly = true})
            if os.isdir(installdir) and os.emptydir(installdir) then
                os.tryrm(installdir, {emptydirs = true})
            end
        end
        unique = {}
        packages = {}
        _memcache():clear()
        opt = table.join(opt, {resolvedinfo = resolvedinfo})
        for _, package in ipairs((_load_packages(requires, opt))) do
            local key = _get_packagekey(package:name(), package:requireinfo())
            if not unique[key] then
                table.insert(packages, package)
                unique[key] = true
            end
        end
    end
    return packages
end

