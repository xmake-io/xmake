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
-- @file        vs201x.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("core.tool.compiler")
import("core.tool.linker")
import("core.tool.toolchain")
import("vs201x_solution")
import("vs201x_vcxproj")
import("vs201x_vcxproj_filters")
import("core.cache.memcache")
import("core.cache.localcache")
import("private.action.require.install", {alias = "install_requires"})
import("actions.config.configfiles", {alias = "generate_configfiles", rootdir = os.programdir()})
import("actions.config.configheader", {alias = "generate_configheader", rootdir = os.programdir()})

-- clear cache configuration
function _clear_cacheconf()
    config.clear()
    config.save()
    localcache.clear("config")
    localcache.clear("detect")
    localcache.clear("option")
    localcache.clear("package")
    localcache.clear("toolchain")
    localcache.save()
end

-- make target info
function _make_targetinfo(mode, arch, target)

    -- init target info
    local targetinfo = { mode = mode, arch = (arch == "x86" and "Win32" or "x64") }

    -- get sdk version
    local msvc = toolchain.load("msvc")
    if msvc then
        local vcvars = msvc:config("vcvars")
        if vcvars then
            targetinfo.sdkver = vcvars.WindowsSDKVersion
        end
    end

    -- save c/c++ precompiled output file (.pch)
    targetinfo.pcoutputfile = target:pcoutputfile("c")
    targetinfo.pcxxoutputfile = target:pcoutputfile("cxx")
    target:set("pcheader", nil)
    target:set("pcxxheader", nil)

    -- save symbols
    targetinfo.symbols = target:get("symbols")

    -- save target kind
    targetinfo.targetkind = target:kind()

    -- save target file
    targetinfo.targetfile = target:targetfile()

    -- save symbol file
    targetinfo.symbolfile = target:symbolfile()

    -- save sourcebatches
    targetinfo.sourcebatches = target:sourcebatches()

    -- save target dir
    targetinfo.targetdir = target:targetdir()

    -- save object dir
    targetinfo.objectdir = target:objectdir()

    -- save compiler flags and cmds
    local firstcompflags = nil
    targetinfo.compflags = {}
    targetinfo.compargvs = {}
    for _, sourcebatch in pairs(target:sourcebatches()) do
        local sourcekind = sourcebatch.sourcekind
        if sourcekind then
            for idx, sourcefile in ipairs(sourcebatch.sourcefiles) do
                local compflags = compiler.compflags(sourcefile, {target = target})
                if not firstcompflags and (sourcekind == "cc" or sourcekind == "cxx") then
                    firstcompflags = compflags
                end
                targetinfo.compflags[sourcefile] = compflags
                targetinfo.compargvs[sourcefile] = table.join(compiler.compargv("__sourcefile__", "__objectfile__", {sourcekind = sourcekind, target = target}))
            end
        end
    end

    -- save linker flags
    local linkflags = linker.linkflags(target:kind(), target:sourcekinds(), {target = target})
    targetinfo.linkflags = linkflags

    -- use mfc? save the mfc runtime kind
    if target:rule("win.sdk.mfc.shared_app") or target:rule("win.sdk.mfc.shared") then
        targetinfo.usemfc = "Dynamic"
    elseif target:rule("win.sdk.mfc.static_app") or target:rule("win.sdk.mfc.static") then
        targetinfo.usemfc = "Static"
    end

    -- set unicode
    for _, flag in ipairs(firstcompflags) do
        if flag:find("[%-|/]DUNICODE") then
            targetinfo.unicode = true
            break
        end
    end

    -- ok
    return targetinfo
end

-- make target headers
function _make_targetheaders(mode, arch, target, last)

    -- only for static and shared target
    local kind = target:kind()
    if kind == "static" or kind == "shared" then

        -- TODO make headers, (deprecated)
        local srcheaders, dstheaders = target:headers()
        if srcheaders and dstheaders then
            local i = 1
            for _, srcheader in ipairs(srcheaders) do
                local dstheader = dstheaders[i]
                if dstheader then
                    os.cp(srcheader, dstheader)
                end
                i = i + 1
            end
        end

        -- make config header
        local configheader_raw = target:configheader()
        if configheader_raw and os.isfile(configheader_raw) then

            -- init the config header path for each mode and arch
            local configheader_mode_arch = path.join(path.directory(configheader_raw), mode .. "." .. arch .. "." .. path.filename(configheader_raw))

            -- init the temporary config header path
            local configheader_tmp = path.join(path.directory(configheader_raw), "tmp." .. path.filename(configheader_raw))

            -- copy the original config header first
            os.cp(configheader_raw, configheader_mode_arch)

            -- append the current config header
            local file = io.open(configheader_tmp, "a+")
            if file then
                file:print("")
                file:print("#if defined(__config_%s__) && defined(__config_%s__)", mode, arch)
                file:print("#    include \"%s.%s.%s\"", mode, arch, path.filename(configheader_raw))
                file:print("#endif")
                file:close()
            end

            -- override the raw config header at last
            if last and os.isfile(configheader_tmp) then
                os.mv(configheader_tmp, configheader_raw)
            end
        end
    end
end

function _make_vsinfo_modes()
    local vsinfo_modes = {}
    local modes = option.get("modes")
    if modes then
        if not modes:find("\"") then
            modes = modes:gsub(",", path.envsep())
        end
        for _, mode in ipairs(path.splitenv(modes)) do
            table.insert(vsinfo_modes, mode:trim())
        end
    else
        vsinfo_modes = project.modes()
    end
    if not vsinfo_modes or #vsinfo_modes == 0 then
        vsinfo_modes = { config.mode() }
    end
    return vsinfo_modes
end

function _make_vsinfo_archs()
    local vsinfo_archs = {}
    local archs = option.get("archs")
    if archs then
        if not archs:find("\"") then
            archs = archs:gsub(",", path.envsep())
        end
        for _, arch in ipairs(path.splitenv(archs)) do
            table.insert(vsinfo_archs, arch:trim())
        end
    else
        -- we use it first if global set_arch("xx") is setted in xmake.lua
        vsinfo_archs = project.get("target.arch") or platform.archs()
    end
    if not vsinfo_archs or #vsinfo_archs == 0 then
        vsinfo_archs = { config.arch() }
    end
    return vsinfo_archs
end

-- config target
function _config_target(target)
    for _, rule in ipairs(target:orderules()) do
        local on_config = rule:script("config")
        if on_config then
            on_config(target)
        end
    end
    local on_config = target:script("config")
    if on_config then
        on_config(target)
    end
end

-- config targets
function _config_targets()
    for _, target in ipairs(project.ordertargets()) do
        if target:is_enabled() then
            _config_target(target)
        end
    end
end

-- make vstudio project
function make(outputdir, vsinfo)

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- init solution directory
    vsinfo.solution_dir = path.join(outputdir, "vs" .. vsinfo.vstudio_version)

    -- init modes
    vsinfo.modes = _make_vsinfo_modes()

    -- init archs
    vsinfo.archs = _make_vsinfo_archs()

    -- load targets
    local targets = {}
    for mode_idx, mode in ipairs(vsinfo.modes) do
        for arch_idx, arch in ipairs(vsinfo.archs) do

            -- trace
            print("checking for %s.%s ...", mode, arch)

            -- reload config, project and platform
            if mode ~= config.mode() or arch ~= config.arch() then

                -- modify config
                config.set("as", nil, {force = true}) -- force to re-check as for ml/ml64
                config.set("mode", mode, {readonly = true, force = true})
                config.set("arch", arch, {readonly = true, force = true})

                -- clear all options
                for _, opt in ipairs(project.options()) do
                    opt:clear()
                end

                -- clear cache
                memcache.clear()
                localcache.clear("config")
                localcache.clear("detect")
                localcache.clear("option")
                localcache.clear("package")
                localcache.clear("toolchain")

                -- check platform
                platform.load(config.plat(), arch):check()

                -- check project options
                project.check()

                -- install and update requires
                install_requires()

                -- config targets
                _config_targets()

                -- update config files
                generate_configfiles()
                generate_configheader()
            end

            -- ensure to enter project directory
            os.cd(project.directory())

            -- save targets
            for targetname, target in pairs(project.targets()) do
                if not target:is_phony() then

                    -- make target with the given mode and arch
                    targets[targetname] = targets[targetname] or {}
                    local _target = targets[targetname]

                    -- save c/c++ precompiled header
                    _target.pcheader   = target:pcheaderfile("c")     -- header.h
                    _target.pcxxheader = target:pcheaderfile("cxx")   -- header.[hpp|inl]

                    -- init target info
                    _target.name = targetname
                    _target.kind = target:kind()
                    _target.scriptdir = target:scriptdir()
                    _target.info = _target.info or {}
                    table.insert(_target.info, _make_targetinfo(mode, arch, target))

                    -- save all sourcefiles and headerfiles
                    _target.sourcefiles = table.unique(table.join(_target.sourcefiles or {}, (target:sourcefiles())))
                    _target.headerfiles = table.unique(table.join(_target.headerfiles or {}, (target:headerfiles())))

                    -- make target headers
                    _make_targetheaders(mode, arch, target, mode_idx == #vsinfo.modes and arch_idx == 2)
                end
            end
        end
    end

    -- make solution
    vs201x_solution.make(vsinfo)

    -- make .vcxproj
    for _, target in pairs(targets) do
        vs201x_vcxproj.make(vsinfo, target)
        vs201x_vcxproj_filters.make(vsinfo, target)
    end

    -- clear config and local cache
    _clear_cacheconf()

    -- leave project directory
    os.cd(oldir)
end
