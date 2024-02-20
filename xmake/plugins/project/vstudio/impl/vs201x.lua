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
import("core.base.colors")
import("core.base.hashset")
import("core.project.rule")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("core.tool.compiler")
import("core.tool.linker")
import("core.tool.toolchain")
import("vs201x_solution")
import("vs201x_vcxproj")
import("vs201x_vcxproj_filters")
import("vsutils")
import("core.cache.memcache")
import("core.cache.localcache")
import("private.action.require.install", {alias = "install_requires"})
import("private.action.run.runenvs")
import("actions.config.configfiles", {alias = "generate_configfiles", rootdir = os.programdir()})
import("private.utils.batchcmds")
import("private.utils.rule_groups")
import("plugins.project.utils.target_cmds", {rootdir = os.programdir()})

function _translate_path(dir, vcxprojdir)
    if dir == nil then
        return ""
    end
    if type(dir) == "string" then
        dir = path.translate(dir)
        if dir == "" then
            return ""
        end
        if path.is_absolute(dir) then
            if dir:startswith(project.directory()) then
                return vsutils.escape(path.relative(dir, vcxprojdir))
            end
            return vsutils.escape(dir)
        else
            return vsutils.escape(path.relative(path.absolute(dir), vcxprojdir))
        end
    end
    local r = {}
    for k, v in ipairs(dir) do
        r[k] = _translate_path(v, vcxprojdir)
    end
    r = table.unique(r)
    return path.joinenv(r)
end

-- clear cache
function _clear_cache()
    localcache.clear("detect")
    localcache.clear("option")
    localcache.clear("package")
    localcache.clear("toolchain")

    -- force recheck
    localcache.set("config", "recheck", true)

    localcache.save()
end

-- get c++ modules rules
function _get_cxxmodules_rules()
    return {"c++.build.modules", "c++.build.modules.builder"}
end

-- get command string
function _get_command_string(cmd, vcxprojdir)
    local kind = cmd.kind
    local opt = cmd.opt
    if cmd.program then
        local argv = {}
        for _, v in ipairs(table.join(cmd.program, cmd.argv)) do
            if path.instance_of(v) then
                v = v:clone():set(_translate_path(v:rawstr(), vcxprojdir)):str()
            elseif path.is_absolute(v) then
                v = _translate_path(v, vcxprojdir)
            end
            table.insert(argv, v)
        end
        local command = os.args(argv)
        if opt and opt.curdir then
            command = string.format("pushd \"%s\"\n%s\npopd", _translate_path(opt.curdir, vcxprojdir), command)
        end
        return command
    elseif kind == "cp" then
        return string.format("copy /Y \"%s\" \"%s\"", _translate_path(cmd.srcpath, vcxprojdir), _translate_path(cmd.dstpath, vcxprojdir))
    elseif kind == "rm" then
        return string.format("del /F /Q \"%s\" || rmdir /S /Q \"%s\"", _translate_path(cmd.filepath, vcxprojdir), _translate_path(cmd.filepath, vcxprojdir))
    elseif kind == "rmdir" then
        return string.format("rmdir /S /Q \"%s\"", _translate_path(cmd.filepath, vcxprojdir))
    elseif kind == "mv" then
        return string.format("rename \"%s\" \"%s\"", _translate_path(cmd.srcpath, vcxprojdir), _translate_path(cmd.dstpath, vcxprojdir))
    elseif kind == "cd" then
        return string.format("cd \"%s\"", _translate_path(cmd.dir, vcxprojdir))
    elseif kind == "mkdir" then
        local dir = _translate_path(cmd.dir, vcxprojdir)
        return string.format("if not exist \"%s\" mkdir \"%s\"", dir, dir)
    elseif kind == "show" then
        return string.format("echo %s", colors.ignore(cmd.showtext))
    end
end

-- make custom commands
function _make_custom_commands(target, vcxprojdir)
    -- https://github.com/xmake-io/xmake/issues/2337
    target:data_set("plugin.project.kind", "vs")
    -- https://github.com/xmake-io/xmake/issues/2258
    target:data_set("plugin.project.translate_path", function (p)
        return _translate_path(p, vcxprojdir)
    end)

    -- build sourcebatch groups first
    local sourcegroups = rule_groups.build_sourcebatch_groups(target, target:sourcebatches())

    -- ignore c++ modules rules
    local ignored_rules = _get_cxxmodules_rules()

    -- add before commands
    -- we use irpairs(groups), because the last group that should be given the highest priority.
    local cmds_before = {}
    target_cmds.get_target_buildcmd(target, cmds_before, {suffix = "before", ignored_rules = ignored_rules})
    target_cmds.get_target_buildcmd_sourcegroups(target, cmds_before, sourcegroups, {suffix = "before", ignored_rules = ignored_rules})
    -- rule.on_buildcmd_files should also be executed before building the target, as cmake PRE_BUILD does not work.
    target_cmds.get_target_buildcmd_sourcegroups(target, cmds_before, sourcegroups, {ignored_rules = ignored_rules})

    -- add after commands
    local cmds_after = {}
    target_cmds.get_target_buildcmd_sourcegroups(target, cmds_after, sourcegroups, {suffix = "after", ignored_rules = ignored_rules})
    target_cmds.get_target_buildcmd(target, cmds_after, {suffix = "after", ignored_rules = ignored_rules})

    local commands = {}
    for _, cmd in ipairs(cmds_before) do
        commands.before = commands.before or {}
        table.insert(commands.before, _get_command_string(cmd, vcxprojdir))
    end
    for _, cmd in ipairs(cmds_after) do
        commands.after = commands.after or {}
        table.insert(commands.after, _get_command_string(cmd, vcxprojdir))
    end
    return commands
end

-- make target info
function _make_targetinfo(mode, arch, target, vcxprojdir)

    -- init target info
    local targetinfo = { mode = mode, arch = vsutils.vsarch(arch) }

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

    -- save languages
    targetinfo.languages = table.wrap(target:get("languages"))

    -- save symbols
    targetinfo.symbols = target:get("symbols")

    -- has modules
    targetinfo.has_modules = target:data("cxx.has_modules")

    -- save target kind
    targetinfo.targetkind = target:kind()
    if target:is_phony() or target:is_headeronly() then
        return targetinfo
    end

    -- save target file
    targetinfo.targetfile = target:targetfile()

    -- save symbol file
    targetinfo.symbolfile = target:symbolfile()

    -- save sourcekinds
    targetinfo.sourcekinds = target:sourcekinds()

    -- save target dir
    targetinfo.targetdir = target:targetdir()

    -- save object dir
    targetinfo.objectdir = target:objectdir()

    -- save compiler flags and cmds
    local firstcompflags = nil
    targetinfo.compflags = {}
    targetinfo.compargvs = {}
    local sourcebatches = target:sourcebatches()
    for _, sourcebatch in table.orderpairs(sourcebatches) do
        local sourcekind = sourcebatch.sourcekind
        local rulename = sourcebatch.rulename
        if sourcekind then
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                local compflags = compiler.compflags(sourcefile, {target = target, sourcekind = sourcekind})
                if not firstcompflags and (rulename == "c.build" or rulename == "c++.build" or rulename == "c++.build.modules" or rulename == "cuda.build") then
                    firstcompflags = compflags
                end
                targetinfo.compflags[sourcefile] = compflags
                targetinfo.compargvs[sourcefile] = table.join(compiler.compargv("__sourcefile__", "__objectfile__", {sourcekind = sourcekind, target = target}))

                -- detect manifest
                -- @see https://github.com/xmake-io/xmake/issues/2176
                if sourcekind == "mrc" and os.isfile(sourcefile) then
                    local resoucedata = io.readfile(sourcefile)
                    if resoucedata and resoucedata:find("RT_MANIFEST") then
                        targetinfo.manifest_embed = false
                    end
                end
            end
        end
    end

    -- save sourcebatches
    targetinfo.sourcebatches = target:sourcebatches()

    -- save linker flags
    local linkflags = linker.linkflags(target:is_moduleonly() and 'static' or target:kind(), target:sourcekinds(), {target = target})
    targetinfo.linkflags = linkflags

    if table.contains(target:sourcekinds(), "cu") then
        -- save cuda linker flags
        local linkinst = linker.load("gpucode", "cu", {target = target})
        targetinfo.culinkflags = linkinst:linkflags({target = target})

        -- save cuda devlink status
        targetinfo.cudevlink = target:policy("build.cuda.devlink") or target:values("cuda.build.devlink")
    end

    -- save execution dir (when executed from VS)
    targetinfo.rundir = target:is_moduleonly() and "" or target:rundir()

    -- save runenvs
    local targetrunenvs = {}
    local addrunenvs, setrunenvs = runenvs.make(target)
    for k, v in table.orderpairs(target:pkgenvs()) do
        addrunenvs = addrunenvs or {}
        addrunenvs[k] = table.join(table.wrap(addrunenvs[k]), path.splitenv(v))
    end
    for _, dep in ipairs(target:orderdeps()) do
        for k, v in table.orderpairs(dep:pkgenvs()) do
            addrunenvs = addrunenvs or {}
            addrunenvs[k] = table.join(table.wrap(addrunenvs[k]), path.splitenv(v))
        end
    end
    for k, v in table.orderpairs(addrunenvs) do
        if k:upper() == "PATH" then
            targetrunenvs[k] = _translate_path(v, vcxprojdir) .. ";$([System.Environment]::GetEnvironmentVariable('" .. k .. "'))"
        else
            targetrunenvs[k] = path.joinenv(v) .. ";$([System.Environment]::GetEnvironmentVariable('" .. k .."'))"
        end
    end
    for k, v in table.orderpairs(setrunenvs) do
        if #v == 1 then
            v = v[1]
            if path.is_absolute(v) and v:startswith(project.directory()) then
                targetrunenvs[k] = _translate_path(v, vcxprojdir)
            else
                targetrunenvs[k] = v[1]
            end
        else
            targetrunenvs[k] = path.joinenv(v)
        end
    end
    local runenvstr = {}
    for k, v in table.orderpairs(targetrunenvs) do
        table.insert(runenvstr, k .. "=" .. v)
    end
    targetinfo.runenvs = table.concat(runenvstr, "\n")

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

    -- save custom commands
    targetinfo.commands = _make_custom_commands(target, vcxprojdir)
    return targetinfo
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
        vsinfo_archs = project.get("target.arch")
        if not vsinfo_archs then
            -- for set_allowedarchs()
            local allowed_archs = project.allowed_archs(config.plat())
            if allowed_archs then
                vsinfo_archs = allowed_archs:to_array()
            end
        end
        if not vsinfo_archs then
            local default_archs = toolchain.load("msvc"):config("vcarchs")
            if not default_archs then
                default_archs = platform.archs()
            end
            if default_archs then
                default_archs = hashset.from(table.wrap(default_archs))
                -- just generate single arch by default to avoid some fails for installing packages.
                -- @see https://github.com/xmake-io/xmake/issues/3268
                local arch = config.arch()
                if default_archs:has(arch) then
                    vsinfo_archs = { arch }
                else
                    default_archs:remove("arm64")
                    vsinfo_archs = default_archs:to_array()
                end
            end
        end
    end
    if not vsinfo_archs or #vsinfo_archs == 0 then
        vsinfo_archs = { config.arch() }
    end
    return vsinfo_archs
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
                localcache.clear("detect")
                localcache.clear("option")
                localcache.clear("package")
                localcache.clear("toolchain")
                localcache.clear("cxxmodules")

                -- check platform
                platform.load(config.plat(), arch):check()

                -- check project options
                project.check_options()

                -- install and update requires
                install_requires()

                -- load targets
                project.load_targets()

                -- update config files
                generate_configfiles()
            end

            -- ensure to enter project directory
            os.cd(project.directory())

            -- save targets
            for targetname, target in table.orderpairs(project.targets()) do

                -- make target with the given mode and arch
                targets[targetname] = targets[targetname] or {}
                local _target = targets[targetname]

                -- the vcxproj directory
                _target.project_dir = path.join(vsinfo.solution_dir, targetname)

                -- save c/c++ precompiled header
                _target.pcheader   = target:pcheaderfile("c")     -- header.h
                _target.pcxxheader = target:pcheaderfile("cxx")   -- header.[hpp|inl]

                -- init target info
                _target.name = targetname
                _target.kind = target:kind()
                _target.scriptdir = target:scriptdir()
                _target.info = _target.info or {}
                table.insert(_target.info, _make_targetinfo(mode, arch, target, _target.project_dir))

                -- save all sourcefiles and headerfiles
                _target.sourcefiles = table.unique(table.join(_target.sourcefiles or {}, (target:sourcefiles())))
                _target.headerfiles = table.unique(table.join(_target.headerfiles or {}, (target:headerfiles())))
                _target.extrafiles = table.unique(table.join(_target.extrafiles or {}, (target:extrafiles())))

                -- sort them to stabilize generation
                table.sort(_target.sourcefiles)
                table.sort(_target.headerfiles)
                table.sort(_target.extrafiles)

                -- save file groups
                _target.filegroups = table.unique(table.join(_target.filegroups or {}, target:get("filegroups")))

                -- save references to deps
                for _, dep in ipairs(target:orderdeps()) do
                    _target.deps = _target.deps or {}
                    local dep_name = dep:name()
                    _target.deps[dep_name] = path.relative(path.join(vsinfo.solution_dir, dep_name, dep_name .. ".vcxproj"), _target.project_dir)
                end

                for filegroup, groupconf in pairs(target:extraconf("filegroups")) do
                    _target.filegroups_extraconf = _target.filegroups_extraconf or {}
                    local mergedconf = _target.filegroups_extraconf[filegroup]
                    if not mergedconf then
                        mergedconf = {}
                        _target.filegroups_extraconf[filegroup] = mergedconf
                    end

                    if groupconf.rootdir then
                        mergedconf.rootdir = table.unique(table.join(mergedconf.rootdir or {}, table.wrap(groupconf.rootdir)))
                    end
                    if groupconf.files then
                        mergedconf.files = table.unique(table.join(mergedconf.files or {}, table.wrap(groupconf.files)))
                    end
                    mergedconf.plain = groupconf.plain or mergedconf.plain
                end
            end
        end
    end

    -- make solution
    vs201x_solution.make(vsinfo)

    -- make .vcxproj
    for _, target in table.orderpairs(targets) do
        vs201x_vcxproj.make(vsinfo, target)
        vs201x_vcxproj_filters.make(vsinfo, target)
    end

    -- clear local cache
    _clear_cache()

    -- leave project directory
    os.cd(oldir)
end
