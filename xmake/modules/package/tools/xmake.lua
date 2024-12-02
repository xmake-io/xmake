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
-- @file        xmake.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.tool.toolchain")
import("core.project.project")
import("core.package.repository")
import("private.action.require.impl.package", {alias = "require_package"})
import("private.utils.toolchain", {alias = "toolchain_utils"})

-- get config from toolchains
function _get_config_from_toolchains(package, name)
    for _, toolchain_inst in ipairs(package:toolchains()) do
        local value = toolchain_inst:config(name)
        if value ~= nil then
            return value
        end
    end
end

-- is the toolchain compatible with the host?
function _is_toolchain_compatible_with_host(package)
    for _, name in ipairs(package:config("toolchains")) do
        if toolchain_utils.is_compatible_with_host(name) then
            return true
        end
    end
end

-- get configs for qt
function _get_configs_for_qt(package, configs, opt)
    local names = {"qt", "qt_sdkver"}
    for _, name in ipairs(names) do
        local value = get_config(name)
        if value ~= nil then
            table.insert(configs, "--" .. name .. "=" .. tostring(value))
        end
    end
end

-- get configs for vcpkg
function _get_configs_for_vcpkg(package, configs, opt)
    local names = {"vcpkg"}
    for _, name in ipairs(names) do
        local value = get_config(name)
        if value ~= nil then
            table.insert(configs, "--" .. name .. "=" .. tostring(value))
        end
    end
end

-- get configs for windows
function _get_configs_for_windows(package, configs, opt)
    local names = {"vs", "vs_toolset"}
    for _, name in ipairs(names) do
        local value = get_config(name)
        if value ~= nil then
            table.insert(configs, "--" .. name .. "=" .. tostring(value))
        end
    end
    -- pass runtimes from package configs
    local runtimes = package:config("runtimes")
    if runtimes then
        table.insert(configs, "--runtimes=" .. runtimes)
    end
    _get_configs_for_qt(package, configs, opt)
    _get_configs_for_vcpkg(package, configs, opt)

    -- we can switch some toolchains, e.g. llvm/clang
    if package:config("toolchains") and _is_toolchain_compatible_with_host(package) then
        _get_configs_for_host_toolchain(package, configs, opt)
    end

    if not is_host("windows") then
        local sdkdir = _get_config_from_toolchains(package, "sdkdir") or get_config("sdk")
        if sdkdir and #sdkdir > 0 then
            table.insert(configs, "--sdk=" .. sdkdir)
        end
    end
end

-- get configs for appleos
function _get_configs_for_appleos(package, configs, opt)
    local xcode = get_config("xcode")
    if xcode then
        table.insert(configs, "--xcode=" .. xcode)
    end
    local xcode_sdkver = get_config("xcode_sdkver")
    if xcode_sdkver then
        table.insert(configs, "--xcode_sdkver=" .. xcode_sdkver)
    end
    local target_minver = get_config("target_minver")
    if target_minver then
        table.insert(configs, "--target_minver=" .. target_minver)
    end
    local appledev = get_config("appledev")
    if appledev then
        table.insert(configs, "--appledev=" .. appledev)
    end
    local runtimes = package:config("runtimes")
    if runtimes then
        table.insert(configs, "--runtimes=" .. runtimes)
    end
    _get_configs_for_qt(package, configs, opt)
    _get_configs_for_vcpkg(package, configs, opt)
end

-- get configs for android
function _get_configs_for_android(package, configs, opt)
    local names = {"ndk", "ndk_sdkver", "ndk_stdcxx", "ndk_cxxstl"}
    for _, name in ipairs(names) do
        local value = get_config(name)
        if value ~= nil then
            table.insert(configs, "--" .. name .. "=" .. tostring(value))
        end
    end
    _get_configs_for_qt(package, configs, opt)
    _get_configs_for_vcpkg(package, configs, opt)
end

-- get configs for mingw
function _get_configs_for_mingw(package, configs, opt)
    local names = {"mingw", "sdk", "ld", "sh", "ar", "cc", "cxx", "mm", "mxx"}
    for _, name in ipairs(names) do
        local value = get_config(name)
        if value ~= nil then
            table.insert(configs, "--" .. name .. "=" .. tostring(value))
        end
    end
    local runtimes = package:config("runtimes")
    if runtimes then
        table.insert(configs, "--runtimes=" .. runtimes)
    end
    _get_configs_for_qt(package, configs, opt)
    _get_configs_for_vcpkg(package, configs, opt)
end

-- get configs for generic, e.g. linux, macosx, bsd host platforms
function _get_configs_for_generic(package, configs, opt)
    local names = {"ld", "sh", "ar", "cc", "cxx", "mm", "mxx"}
    if package:is_plat("macosx") then
        table.join2(names, "xcode", "xcode_sdkver", "target_minver", "appledev")
    end
    for _, name in ipairs(names) do
        local value = get_config(name)
        if value ~= nil then
            table.insert(configs, "--" .. name .. "=" .. tostring(value))
        end
    end
    local runtimes = package:config("runtimes")
    if runtimes then
        table.insert(configs, "--runtimes=" .. runtimes)
    end
    _get_configs_for_qt(package, configs, opt)
    _get_configs_for_vcpkg(package, configs, opt)
end

-- get configs for host toolchain
function _get_configs_for_host_toolchain(package, configs, opt)
    local bindir = _get_config_from_toolchains(package, "bindir") or get_config("bin")
    if bindir then
        table.insert(configs, "--bin=" .. bindir)
    end
    local sdkdir = _get_config_from_toolchains(package, "sdkdir") or get_config("sdk")
    if sdkdir then
        table.insert(configs, "--sdk=" .. sdkdir)
    end
    local runtimes = package:config("runtimes")
    if runtimes then
        table.insert(configs, "--runtimes=" .. runtimes)
    end
    local toolchain_name = get_config("toolchain")
    if toolchain_name then
        table.insert(configs, "--toolchain=" .. toolchain_name)
    end
    _get_configs_for_qt(package, configs, opt)
    _get_configs_for_vcpkg(package, configs, opt)
end

-- get configs for cross
function _get_configs_for_cross(package, configs, opt)
    local cross = _get_config_from_toolchains(package, "cross") or get_config("cross")
    if cross then
        table.insert(configs, "--cross=" .. cross)
    end
    local bindir = _get_config_from_toolchains(package, "bindir") or get_config("bin")
    if bindir then
        table.insert(configs, "--bin=" .. bindir)
    end
    local sdkdir = _get_config_from_toolchains(package, "sdkdir") or get_config("sdk")
    if sdkdir then
        table.insert(configs, "--sdk=" .. sdkdir)
    end
    local runtimes = package:config("runtimes")
    if runtimes then
        table.insert(configs, "--runtimes=" .. runtimes)
    end
    local toolchain_name = get_config("toolchain")
    if toolchain_name then
        table.insert(configs, "--toolchain=" .. toolchain_name)
    end
    local names = {"ld", "sh", "ar", "cc", "cxx", "mm", "mxx"}
    for _, name in ipairs(names) do
        local value = get_config(name)
        if value ~= nil then
            table.insert(configs, "--" .. name .. "=" .. tostring(value))
        end
    end
end

-- get configs
function _get_configs(package, configs, opt)
    opt = opt or {}
    local configs  = configs or {}
    local cflags   = table.join(table.wrap(package:config("cflags")),   get_config("cflags"))
    local cxflags  = table.join(table.wrap(package:config("cxflags")),  get_config("cxflags"))
    local cxxflags = table.join(table.wrap(package:config("cxxflags")), get_config("cxxflags"))
    local asflags  = table.join(table.wrap(package:config("asflags")),  get_config("asflags"))
    local ldflags  = table.join(table.wrap(package:config("ldflags")),  get_config("ldflags"))
    local shflags  = table.join(table.wrap(package:config("shflags")),  get_config("shflags"))
    table.insert(configs, "--plat=" .. package:plat())
    table.insert(configs, "--arch=" .. package:arch())
    if configs.mode == nil then
        table.insert(configs, "--mode=" .. (package:is_debug() and "debug" or "release"))
    end
    if configs.kind == nil then
        table.insert(configs, "--kind=" .. (package:config("shared") and "shared" or "static"))
    end
    if package:is_plat("windows") then
        _get_configs_for_windows(package, configs, opt)
    elseif package:is_plat("android") then
        _get_configs_for_android(package, configs, opt)
    elseif package:is_plat("iphoneos", "watchos", "appletvos") or
        -- for cross-compilation on macOS, @see https://github.com/xmake-io/xmake/issues/2804
        (package:is_plat("macosx") and (get_config("appledev") or not package:is_arch(os.subarch()))) then
        _get_configs_for_appleos(package, configs, opt)
    elseif package:is_plat("mingw") then
        _get_configs_for_mingw(package, configs, opt)
    elseif package:is_cross() then
        _get_configs_for_cross(package, configs, opt)
    elseif package:config("toolchains") then
        -- we still need find system libraries,
        -- it just pass toolchain environments if the toolchain is compatible with host
        if _is_toolchain_compatible_with_host(package) then
            _get_configs_for_host_toolchain(package, configs, opt)
        else
            _get_configs_for_cross(package, configs, opt)
        end
    else
        _get_configs_for_generic(package, configs, opt)
    end

    local policies = get_config("policies")
    if package:config("lto") and (not policies or not policies:find("build.optimization.lto", 1, true)) then
        if policies then
            policies = policies .. ",build.optimization.lto"
        else
            policies = "build.optimization.lto"
        end
    end
    if package:config("asan") and (not policies or not policies:find("build.sanitizer.address", 1, true)) then
        if policies then
            policies = policies .. ",build.sanitizer.address"
        else
            policies = "build.sanitizer.address"
        end
    end
    if not package:use_external_includes() and (not policies or not policies:find("package.include_external_headers", 1, true)) then
        if policies then
            policies = policies .. ",package.include_external_headers:n"
        else
            policies = "package.include_external_headers:n"
        end
    end
    if policies then
        table.insert(configs, "--policies=" .. policies)
    end
    if not package:is_plat("windows", "mingw") and package:config("pic") ~= false then
        table.insert(cxflags, "-fPIC")
    end
    if cflags and #cflags > 0 then
        table.insert(configs, "--cflags=" .. table.concat(cflags, ' '))
    end
    if cxflags and #cxflags > 0 then
        table.insert(configs, "--cxflags=" .. table.concat(cxflags, ' '))
    end
    if cxxflags and #cxxflags > 0 then
        table.insert(configs, "--cxxflags=" .. table.concat(cxxflags, ' '))
    end
    if asflags and #asflags > 0 then
        table.insert(configs, "--asflags=" .. table.concat(asflags, ' '))
    end
    if ldflags and #ldflags > 0 then
        table.insert(configs, "--ldflags=" .. table.concat(ldflags, ' '))
    end
    if shflags and #shflags > 0 then
        table.insert(configs, "--shflags=" .. table.concat(shflags, ' '))
    end
    local buildir = opt.buildir or package:buildir()
    if buildir then
        table.insert(configs, "--buildir=" .. buildir)
    end
    return configs
end

-- maybe in project?
-- @see https://github.com/xmake-io/xmake/issues/3720
function _maybe_in_project(package)
    local dir = package:sourcedir() or package:cachedir()
    local parentdir = path.directory(dir)
    while parentdir and os.isdir(parentdir) do
        if os.isfile(path.join(parentdir, "xmake.lua")) then
            return true
        end
        parentdir = path.directory(parentdir)
    end
end

-- set some builtin global options from the parent xmake
function _set_builtin_argv(package, argv)
    -- if the package cache directory is modified,
    -- we need to force the project directory to be specified to avoid interference by the upper level xmake.lua.
    -- and we also need to put `-P` in the first argument to avoid option.parse() parsing errors
    if _maybe_in_project(package) then
        table.insert(argv, "-P")
        table.insert(argv, os.curdir())
    end
    for _, name in ipairs({"diagnosis", "verbose", "quiet", "yes", "confirm", "root"}) do
        local value = option.get(name)
        if type(value) == "boolean" then
            table.insert(argv, "--" .. name)
        elseif value ~= nil then
            table.insert(argv, "--" .. name .. "=" .. value)
        end
    end
end

-- get require info of package
function _get_package_requireinfo(packagename)
    if os.isfile(os.projectfile()) then
        local requires_str, requires_extra = project.requires_str()
        local requireitems = require_package.load_requires(requires_str, requires_extra)
        for _, requireitem in ipairs(requireitems) do
            local requireinfo = requireitem.info or {}
            local requirename = requireinfo.alias or requireitem.name
            if requirename == packagename then
                return requireinfo
            end
        end
    end
end

-- get package toolchains envs
function _get_package_toolchains_envs(envs, package, opt)
    opt = opt or {}
    local toolchains = package:config("toolchains")
    if toolchains then

        -- pass toolchains name and their package configurations
        local toolchain_packages = {}
        local toolchains_custom = {}
        for _, name in ipairs(toolchains) do
            local toolchain_inst = toolchain.load(name, {plat = package:plat(), arch = package:arch()})
            if toolchain_inst then
                table.join2(toolchain_packages, toolchain_inst:config("packages"))
                if not toolchain_inst:is_builtin() then
                    table.insert(toolchains_custom, toolchain_inst)
                end
            end
        end
        local rcfile_path = os.tmpfile() .. ".lua"
        local rcfile = io.open(rcfile_path, 'w')
        if #toolchain_packages > 0 then
            for _, packagename in ipairs(toolchain_packages) do
                local requireinfo = _get_package_requireinfo(packagename)
                if requireinfo then
                    requireinfo.originstr = nil
                    rcfile:print("add_requires(\"%s\", %s)", packagename, string.serialize(requireinfo, {strip = true, indent = false}))
                else
                    rcfile:print("add_requires(\"%s\")", packagename)
                end
            end
        end
        rcfile:print("add_toolchains(\"%s\")", table.concat(table.wrap(toolchains), '", "'))
        rcfile:close()
        table.insert(envs.XMAKE_RCFILES, rcfile_path)

        -- pass custom toolchains definition in project
        for _, toolchain_inst in ipairs(toolchains_custom) do
            -- we must load it first
            -- @see https://github.com/xmake-io/xmake/issues/3774
            if toolchain_inst:check() then
                toolchain_inst:load()
                local toolchains_file = os.tmpfile()
                dprint("passing toolchain(%s) to %s", toolchain_inst:name(), toolchains_file)
                local ok, errors = toolchain_inst:savefile(toolchains_file)
                if not ok then
                    raise("save toolchain failed, %s", errors or "unknown")
                end
                envs.XMAKE_TOOLCHAIN_DATAFILES = envs.XMAKE_TOOLCHAIN_DATAFILES or {}
                table.insert(envs.XMAKE_TOOLCHAIN_DATAFILES, toolchains_file)
            end
        end
    end
end

-- get require paths
function _get_package_requirepaths(requirepaths, package, dep, rootpath)
    for _, plaindep in ipairs(package:plaindeps()) do
        local subpath = table.join(rootpath, plaindep:name())
        if plaindep == dep then
            table.insert(requirepaths, table.concat(subpath, "."))
        else
            _get_package_requirepaths(requirepaths, plaindep, dep, subpath)
        end
    end
end

-- get package depconfs envs
-- @see https://github.com/xmake-io/xmake/issues/3952
function _get_package_depconfs_envs(envs, package, opt)
    local policy = package:policy("package.xmake.pass_depconfs")
    if policy == nil then
        policy = project.policy("package.xmake.pass_depconfs")
    end
    if policy == false then
        return
    end
    local requireconfs = {}
    for _, dep in ipairs(package:librarydeps()) do
        local requireinfo = dep:requireinfo()
        if requireinfo and (requireinfo.override or (requireinfo.configs and not table.empty(requireinfo.configs))) then
            local requirepaths = {}
            _get_package_requirepaths(requirepaths, package, dep, {})
            if #requirepaths > 0 then
                table.insert(requireconfs, {requirepaths = requirepaths, requireinfo = requireinfo})
            end
        end
    end
    if #requireconfs > 0 then
        local rcfile_path = os.tmpfile() .. ".lua"
        local rcfile = io.open(rcfile_path, 'w')
        for _, requireconf in ipairs(requireconfs) do
            for _, requirepath in ipairs(requireconf.requirepaths) do
                rcfile:print("add_requireconfs(\"%s\", %s)", requirepath, string.serialize(requireconf.requireinfo, {strip = true, indent = false}))
            end
        end
        rcfile:close()
        table.insert(envs.XMAKE_RCFILES, rcfile_path)
    end
end

-- get the build environments
function buildenvs(package, opt)
    local envs = {XMAKE_RCFILES = {}}
    table.join2(envs.XMAKE_RCFILES, os.getenv("XMAKE_RCFILES"))
    _get_package_toolchains_envs(envs, package, opt)
    _get_package_depconfs_envs(envs, package, opt)
    -- we should avoid using $XMAKE_CONFIGDIR outside to cause conflicts
    envs.XMAKE_CONFIGDIR = os.curdir()
    envs.XMAKE_IN_XREPO  = "1"
    envs.XMAKE_IN_PROJECT_GENERATOR = ""
    return envs
end

-- install package
function install(package, configs, opt)

    -- get build environments
    opt = opt or {}
    local envs = opt.envs or buildenvs(package)

    -- pass local repositories
    for _, repo in ipairs(repository.repositories()) do
        local repo_argv = {"repo"}
        _set_builtin_argv(package, repo_argv)
        table.join2(repo_argv, {"--add", repo:name(), repo:directory()})
        os.vrunv(os.programfile(), repo_argv, {envs = envs})
    end

    -- pass configurations
    -- we need to put `-P` in the first argument of _set_builtin_argv() to avoid option.parse() parsing errors
    local argv = {"f"}
    _set_builtin_argv(package, argv)
    table.insert(argv, "-y")
    table.insert(argv, "-c")
    for name, value in pairs(_get_configs(package, configs, opt)) do
        value = tostring(value):trim()
        if type(name) == "number" then
            if value ~= "" then
                table.insert(argv, value)
            end
        else
            table.insert(argv, "--" .. name .. "=" .. value)
        end
    end

    -- do configure
    os.vrunv(os.programfile(), argv, {envs = envs})

    -- do build
    argv = {"build"}
    _set_builtin_argv(package, argv)
    local njob = opt.jobs or option.get("jobs")
    if njob then
        table.insert(argv, "--jobs=" .. njob)
    end
    local target = table.wrap(opt.target)
    if #target ~= 0 then
        table.join2(argv, target)
    end
    os.vrunv(os.programfile(), argv, {envs = envs})

    -- do install
    argv = {"install", "-y", "--nopkgs", "-o", package:installdir()}
    _set_builtin_argv(package, argv)
    local targets = table.wrap(opt.target)
    if #targets ~= 0 then
        table.join2(argv, targets)
    end
    os.vrunv(os.programfile(), argv, {envs = envs})
end
