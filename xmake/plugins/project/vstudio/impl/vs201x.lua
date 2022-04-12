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
import("private.action.run.make_runenvs")
import("actions.config.configfiles", {alias = "generate_configfiles", rootdir = os.programdir()})
import("actions.config.configheader", {alias = "generate_configheader", rootdir = os.programdir()})
import("private.utils.batchcmds")

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

-- get command string
function _get_command_string(cmd, vcxprojdir)
    local kind = cmd.kind
    local opt = cmd.opt
    if cmd.program then
        local argv = {}
        for _, v in ipairs(table.join(cmd.program, cmd.argv)) do
            if path.is_absolute(v) then
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
        return string.format("copy /Y \"%s\" \"%s\"", cmd.srcpath, cmd.dstpath)
    elseif kind == "rm" then
        return string.format("del /F /Q \"%s\" || rmdir /S /Q \"%s\"", cmd.filepath, cmd.filepath)
    elseif kind == "mv" then
        return string.format("rename \"%s\" \"%s\"", cmd.srcpath, cmd.dstpath)
    elseif kind == "cd" then
        return string.format("cd \"%s\"", cmd.dir)
    elseif kind == "mkdir" then
        return string.format("if not exist \"%s\" mkdir \"%s\"", cmd.dir, cmd.dir)
    elseif kind == "show" then
        return string.format("echo %s", cmd.showtext)
    end
end

-- add target custom commands for target
function _make_custom_commands_for_target(commands, target, vcxprojdir, suffix)
    for _, ruleinst in ipairs(target:orderules()) do
        local scriptname = "buildcmd" .. (suffix and ("_" .. suffix) or "")
        local script = ruleinst:script(scriptname)
        if script then
            local batchcmds_ = batchcmds.new({target = target})
            script(target, batchcmds_, {})
            if not batchcmds_:empty() then
                for _, cmd in ipairs(batchcmds_:cmds()) do
                    local command = _get_command_string(cmd, vcxprojdir)
                    if command then
                        local key = suffix and suffix or "before"
                        commands[key] = commands[key] or {}
                        table.insert(commands[key], command)
                    end
                end
            end
        end

        scriptname = "linkcmd" .. (suffix and ("_" .. suffix) or "")
        script = ruleinst:script(scriptname)
        if script then
            local batchcmds_ = batchcmds.new({target = target})
            script(target, batchcmds_, {})
            if not batchcmds_:empty() then
                for _, cmd in ipairs(batchcmds_:cmds()) do
                    local command = _get_command_string(cmd, vcxprojdir)
                    if command then
                        local key = (suffix and suffix or "before") .. "_link"
                        commands[key] = commands[key] or {}
                        table.insert(commands[key], command)
                    end
                end
            end
        end
    end
end

-- add target custom commands for object rules
function _make_custom_commands_for_objectrules(commands, target, sourcebatch, vcxprojdir, suffix)

    -- get rule
    local rulename = assert(sourcebatch.rulename, "unknown rule for sourcebatch!")
    local ruleinst = assert(project.rule(rulename) or rule.rule(rulename), "unknown rule: %s", rulename)

    -- generate commands for xx_buildcmd_files
    local scriptname = "buildcmd_files" .. (suffix and ("_" .. suffix) or "")
    local script = ruleinst:script(scriptname)
    if script then
        local batchcmds_ = batchcmds.new({target = target})
        script(target, batchcmds_, sourcebatch, {})
        if not batchcmds_:empty() then
            for _, cmd in ipairs(batchcmds_:cmds()) do
                local command = _get_command_string(cmd, vcxprojdir)
                if command then
                    local key = suffix and suffix or "before"
                    commands[key] = commands[key] or {}
                    table.insert(commands[key], command)
                end
            end
        end
    end

    -- generate commands for xx_buildcmd_file
    if not script then
        scriptname = "buildcmd_file" .. (suffix and ("_" .. suffix) or "")
        script = ruleinst:script(scriptname)
        if script then
            local sourcekind = sourcebatch.sourcekind
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                local batchcmds_ = batchcmds.new({target = target})
                script(target, batchcmds_, sourcefile, {})
                if not batchcmds_:empty() then
                    for _, cmd in ipairs(batchcmds_:cmds()) do
                        local command = _get_command_string(cmd, vcxprojdir)
                        if command then
                            local key = suffix and suffix or "before"
                            commands[key] = commands[key] or {}
                            table.insert(commands[key], command)
                        end
                    end
                end
            end
        end
    end
end

-- make custom commands
function _make_custom_commands(target, vcxprojdir)
    -- https://github.com/xmake-io/xmake/issues/2258
    target:data_set("plugin.project.translate_path", function (p)
        return _translate_path(p, vcxprojdir)
    end)
    local commands = {}
    _make_custom_commands_for_target(commands, target, vcxprojdir, "before")
    _make_custom_commands_for_target(commands, target, vcxprojdir)
    for _, sourcebatch in pairs(target:sourcebatches()) do
        local sourcekind = sourcebatch.sourcekind
        if sourcekind ~= "cc" and sourcekind ~= "cxx" and sourcekind ~= "as" then
            _make_custom_commands_for_objectrules(commands, target, sourcebatch, vcxprojdir, "before")
            _make_custom_commands_for_objectrules(commands, target, sourcebatch, vcxprojdir, nil)
            _make_custom_commands_for_objectrules(commands, target, sourcebatch, vcxprojdir, "after")
        end
    end
    _make_custom_commands_for_target(commands, target, vcxprojdir, "after")
    return commands
end

-- make target info
function _make_targetinfo(mode, arch, target, vcxprojdir)

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

    -- save languages
    targetinfo.languages = table.wrap(target:get("languages"))

    -- save symbols
    targetinfo.symbols = target:get("symbols")

    -- save target kind
    targetinfo.targetkind = target:kind()
    if target:is_phony() or target:is_headeronly() then
        return targetinfo
    end

    -- save target file
    targetinfo.targetfile = target:targetfile()

    -- save symbol file
    targetinfo.symbolfile = target:symbolfile()

    -- save sourcebatches
    targetinfo.sourcebatches = target:sourcebatches()

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
    for _, sourcebatch in pairs(target:sourcebatches()) do
        local sourcekind = sourcebatch.sourcekind
        if sourcekind then
            for idx, sourcefile in ipairs(sourcebatch.sourcefiles) do
                local compflags = compiler.compflags(sourcefile, {target = target})
                if not firstcompflags and (sourcekind == "cc" or sourcekind == "cxx" or sourcekind == "cu") then
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

    -- save linker flags
    local linkflags = linker.linkflags(target:kind(), target:sourcekinds(), {target = target})
    targetinfo.linkflags = linkflags

    if table.contains(target:sourcekinds(), "cu") then
        -- save cuda linker flags
        local linkinst = linker.load("gpucode", "cu", {target = target})
        targetinfo.culinkflags = linkinst:linkflags({target = target})

        -- save cuda devlink status
        targetinfo.cudevlink = target:values("cuda.build.devlink")
    end

    -- save execution dir (when executed from VS)
    targetinfo.rundir = target:rundir()

    -- save runenvs
    local runenvs = {}
    local addrunenvs, setrunenvs = make_runenvs(target)
    for k, v in pairs(target:pkgenvs()) do
        addrunenvs = addrunenvs or {}
        addrunenvs[k] = table.join(table.wrap(addrunenvs[k]), path.splitenv(v))
    end
    for _, dep in ipairs(target:orderdeps()) do
        for k, v in pairs(dep:pkgenvs()) do
            addrunenvs = addrunenvs or {}
            addrunenvs[k] = table.join(table.wrap(addrunenvs[k]), path.splitenv(v))
        end
    end
    for k, v in pairs(addrunenvs) do
        if k:upper() == "PATH" then
            runenvs[k] = _translate_path(v, vcxprojdir) .. ";$([System.Environment]::GetEnvironmentVariable('" .. k .. "'))"
        else
            runenvs[k] = path.joinenv(v) .. ";$([System.Environment]::GetEnvironmentVariable('" .. k .."'))"
        end
    end
    for k, v in pairs(setrunenvs) do
        if #v == 1 then
            v = v[1]
            if path.is_absolute(v) and v:startswith(project.directory()) then
                runenvs[k] = _translate_path(v, vcxprojdir)
            else
                runenvs[k] = v[1]
            end
        else
            runenvs[k] = path.joinenv(v)
        end
    end
    local runenvstr = {}
    for k, v in pairs(runenvs) do
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
        vsinfo_archs = project.get("target.arch")
        if not vsinfo_archs then
            -- for set_allowedarchs()
            local allowed_archs = project.allowed_archs(config.plat())
            if allowed_archs then
                vsinfo_archs = allowed_archs:to_array()
            end
        end
        if not vsinfo_archs then
            vsinfo_archs = platform.archs()
        end
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

                -- make target headers
                _make_targetheaders(mode, arch, target, mode_idx == #vsinfo.modes and arch_idx == 2)
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

    -- clear local cache
    _clear_cache()

    -- leave project directory
    os.cd(oldir)
end
