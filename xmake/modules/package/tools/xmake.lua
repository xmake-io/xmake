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

-- get config from toolchains
function _get_config_from_toolchains(package, name)
    for _, toolchain_inst in ipairs(package:toolchains()) do
        local value = toolchain_inst:config(name)
        if value ~= nil then
            return value
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
    table.insert(configs, "--plat=" .. package:plat())
    table.insert(configs, "--arch=" .. package:arch())
    if configs.mode == nil then
        table.insert(configs, "--mode=" .. (package:is_debug() and "debug" or "release"))
    end
    if configs.kind == nil then
        table.insert(configs, "--kind=" .. (package:config("shared") and "shared" or "static"))
    end
    if package:is_plat("windows") then
        local vs_runtime = package:config("vs_runtime")
        if vs_runtime then
            table.insert(configs, "--vs_runtime=" .. vs_runtime)
        end
    elseif package:is_plat("iphoneos", "watchos", "appletvos") then
        local appledev = package:config("appledev")
        if appledev then
            table.insert(configs, "--appledev=" .. appledev)
        end
        local target_minver = get_config("target_minver")
        if target_minver then
            table.insert(configs, "--target_minver=" .. target_minver)
        end
    elseif package:is_plat("cross") then
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
        -- we can only modify toolchain for cross-compilation
        --
        -- e.g. xrepo install -p cross --toolchain=muslcc meson,
        -- we cannot pass muslcc toolchain to it's deps(zlib, ..), because meson is always host binary and zlib is host library.
        local toolchain_name = get_config("toolchain")
        if toolchain_name then
            table.insert(configs, "--toolchain=" .. toolchain_name)
        end
        local names = {"ld", "sh", "ar", "cc", "cxx"}
        for _, name in ipairs(names) do
            local value = get_config(name)
            if value ~= nil then
                table.insert(configs, "--" .. name .. "=" .. tostring(value))
            end
        end
    else
        local names = {"ndk", "ndk_sdkver", "vs", "vs_toolset", "mingw", "ld", "sh", "ar", "cc", "cxx", "mm", "mxx"}
        for _, name in ipairs(names) do
            local value = get_config(name)
            if value ~= nil then
                table.insert(configs, "--" .. name .. "=" .. tostring(value))
            end
        end
    end
    local policies = get_config("policies")
    if package:config("lto") and (not policies or not policies:find("build.optimization.lto", 1, true)) then
        if policies then
            policies = policies .. ",build.optimization.lto"
        else
            policies = "build.optimization.lto"
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
    local buildir = opt.buildir or package:buildir()
    if buildir then
        table.insert(configs, "--buildir=" .. buildir)
    end
    return configs
end

-- set some builtin global options from the parent xmake
function _set_builtin_argv(package, argv)
    -- if the package cache directory is modified,
    -- we need to force the project directory to be specified to avoid interference by the upper level xmake.lua.
    -- and we also need to put `-P` in the first argument to avoid option.parse() parsing errors
    local maybe_in_project = os.getenv("XMAKE_PKG_CACHEDIR") or global.get("pkg_cachedir") or package:sourcedir()
    if maybe_in_project then
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
function _get_package_toolchains_envs(package, opt)
    opt = opt or {}
    local envs = {}
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
        envs.XMAKE_RCFILES = {}
        table.insert(envs.XMAKE_RCFILES, rcfile_path)
        table.join2(envs.XMAKE_RCFILES, os.getenv("XMAKE_RCFILES"))

        -- pass custom toolchains definition in project
        for _, toolchain_inst in ipairs(toolchains_custom) do
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
    return envs
end

-- get the build environments
function buildenvs(package, opt)
    local envs = _get_package_toolchains_envs(package, opt)
    -- we should avoid using $XMAKE_CONFIGDIR outside to cause conflicts
    envs.XMAKE_CONFIGDIR = os.curdir()
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
        os.vrunv("xmake", repo_argv, {envs = envs})
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
    os.vrunv("xmake", argv, {envs = envs})

    -- do build
    argv = {"build"}
    _set_builtin_argv(package, argv)
    if opt.target then
        table.insert(argv, opt.target)
    end
    os.vrunv("xmake", argv, {envs = envs})

    -- do install
    argv = {"install", "-y", "-o", package:installdir()}
    _set_builtin_argv(package, argv)
    if opt.target then
        table.insert(argv, opt.target)
    end
    os.vrunv("xmake", argv, {envs = envs})
end
