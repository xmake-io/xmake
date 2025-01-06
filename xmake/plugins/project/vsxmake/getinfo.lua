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
-- @author      OpportunityLiu
-- @file        getinfo.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.base.hashset")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("core.tool.compiler")
import("core.tool.linker")
import("core.tool.toolchain")
import("core.cache.memcache")
import("core.cache.localcache")
import("lib.detect.find_tool")
import("private.utils.target", {alias = "target_utils"})
import("private.action.run.runenvs")
import("private.action.require.install", {alias = "install_requires"})
import("actions.config.configfiles", {alias = "generate_configfiles", rootdir = os.programdir()})
import("vstudio.impl.vsutils", {rootdir = path.join(os.programdir(), "plugins", "project")})

-- strip dot directories, e.g. ..\..\.. => ..
-- @see https://github.com/xmake-io/xmake/issues/2039
function _strip_dotdirs(dir)
    local count
    dir, count = dir:gsub("%.%.[\\/]%.%.", "..")
    if count > 0 then
        dir = _strip_dotdirs(dir)
    end
    return dir
end

function _make_dirs(dir)
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
                return path.join("$(XmakeProjectDir)", vsutils.escape(path.relative(dir, project.directory())))
            end
            return vsutils.escape(dir)
        end
        return path.join("$(XmakeProjectDir)", vsutils.escape(dir))
    end
    local r = {}
    for k, v in ipairs(dir) do
        r[k] = _make_dirs(v)
    end
    r = table.unique(r)
    return path.joinenv(r)
end

function _make_arrs(arr, sep)
    if arr == nil then
        return ""
    end
    if type(arr) == "string" then
        return vsutils.escape(arr)
    end
    local r = {}
    for k, v in ipairs(arr) do
        r[k] = _make_arrs(v, sep)
    end
    r = table.unique(r)
    return table.concat(r, sep or ";")
end

-- get values from target
function _get_values_from_target(target, name)
    local values = {}
    for _, value in ipairs((target:get_from(name, "*"))) do
        table.join2(values, value)
    end
    return table.unique(values)
end

-- get flags from target
function _get_flags_from_target(target, name)
    local flags = _get_values_from_target(target, name)
    return target_utils.translate_flags_in_tool(target, name, flags)
end

-- make target info
function _make_targetinfo(mode, arch, target)

    -- init target info
    local targetinfo =
    {
        mode = mode
    ,   arch = arch
    ,   plat = config.get("plat")
    ,   vsarch = vsutils.vsarch(arch)
    ,   sdkver = config.get("vs_sdkver")
    }

    -- write only if not default
    -- use target:get("xxx") rather than target:xxx()

    -- save target kind
    targetinfo.kind          = target:kind()

    -- is default?
    targetinfo.default       = tostring(target:is_default())

    -- save target file
    targetinfo.basename      = vsutils.escape(target:basename())
    targetinfo.filename      = vsutils.escape(target:filename())

    -- save dirs
    targetinfo.targetdir     = _make_dirs(target:get("targetdir"))
    targetinfo.buildir       = _make_dirs(config.get("buildir"))
    targetinfo.rundir        = _make_dirs(target:get("rundir"))
    targetinfo.configdir     = _make_dirs(os.getenv("XMAKE_CONFIGDIR"))
    targetinfo.configfiledir = _make_dirs(target:get("configdir"))
    targetinfo.includedirs   = _make_dirs(table.join(_get_values_from_target(target, "includedirs") or {}, _get_values_from_target(target, "sysincludedirs")))
    targetinfo.linkdirs      = _make_dirs(_get_values_from_target(target, "linkdirs"))
    targetinfo.forceincludes = path.joinenv(table.wrap(_get_values_from_target(target, "forceincludes")))
    targetinfo.sourcedirs    = _make_dirs(_get_values_from_target(target, "values.project.vsxmake.sourcedirs"))
    targetinfo.pcheaderfile  = target:pcheaderfile("cxx") or target:pcheaderfile("c")

    -- save defines
    targetinfo.defines       = _make_arrs(_get_values_from_target(target, "defines"))

    -- save flags
    targetinfo.cflags        = _make_arrs(_get_flags_from_target(target, "cflags"), " ")
    targetinfo.cxflags       = _make_arrs(_get_flags_from_target(target, "cxflags"), " ")
    targetinfo.cxxflags      = _make_arrs(_get_flags_from_target(target, "cxxflags"), " ")

    -- save languages
    targetinfo.languages     = _make_arrs(_get_values_from_target(target, "languages"))
    if targetinfo.languages then
        -- fix c++17 to cxx17 for Xmake.props
        targetinfo.languages = targetinfo.languages:replace("c++", "cxx", {plain = true})
    end
    if target:is_phony() or target:is_headeronly() or target:is_moduleonly() or target:is_object() then
        return targetinfo
    end

    -- save subsystem
    local linkflags = linker.linkflags(target:kind(), target:sourcekinds(), {target = target})
    for _, linkflag in ipairs(linkflags) do
        if linkflag:lower():find("[%-/]subsystem:windows") then
            targetinfo.subsystem = "windows"
        end
    end
    if not targetinfo.subsystem then
        targetinfo.subsystem = "console"
    end

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
        -- https://github.com/xmake-io/xmake/issues/3391
        v = table.unique(v)
        if k:upper() == "PATH" then
            targetrunenvs[k] = _make_dirs(v) .. ";$([System.Environment]::GetEnvironmentVariable('" .. k .. "'))"
        else
            targetrunenvs[k] = path.joinenv(v) .. ";$([System.Environment]::GetEnvironmentVariable('" .. k .."'))"
        end
    end
    for k, v in table.orderpairs(setrunenvs) do
        if #v == 1 then
            v = v[1]
            if path.is_absolute(v) and v:startswith(project.directory()) then
                targetrunenvs[k] = _make_dirs(v)
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

    local runargs = target:get("runargs")
    if runargs then
        targetinfo.runargs = os.args(table.wrap(runargs))
    end

    -- use mfc? save the mfc runtime kind
    if target:rule("win.sdk.mfc.shared_app") or target:rule("win.sdk.mfc.shared") then
        targetinfo.mfckind = "Dynamic"
    elseif target:rule("win.sdk.mfc.static_app") or target:rule("win.sdk.mfc.static") then
        targetinfo.mfckind = "Static"
    end

    -- use cuda? save the cuda runtime version
    if target:rule("cuda") then
        local nvcc = find_tool("nvcc", { version = true })
        local ver = semver.new(nvcc.version)
        targetinfo.cudaver = ver:major() .. "." .. ver:minor()
    end
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

function _make_vsinfo_groups()
    local groups = {}
    local group_deps = {}
    for targetname, target in table.orderpairs(project.targets()) do
        local group_path = target:get("group")
        if group_path and #(group_path:trim()) > 0 then
            group_path = path.normalize(group_path)
            local group_name = path.filename(group_path)
            local group_names = path.split(group_path)
            local group_current_path
            for idx, name in ipairs(group_names) do
                group_current_path = group_current_path and path.join(group_current_path, name) or name
                local group = groups["group." .. group_current_path] or {}
                group.group = name
                group.group_id = hash.uuid4("group." .. group_current_path)
                if idx > 1 then
                    group_deps["group_dep." .. group_current_path] = {
                        current_id = group.group_id,
                        parent_id = hash.uuid4("group." .. path.directory(group_current_path))}
                end
                groups["group." .. group_current_path] = group
            end
            group_deps["group_dep.target." .. targetname] = {
                current_id = hash.uuid4(targetname),
                parent_id = groups["group." .. group_path].group_id}
        end
    end
    return groups, group_deps
end

-- make filter
function _make_filter(filepath, target, vcxprojdir)
    local filter
    local is_plain = false
    local filegroups = target.filegroups
    if filegroups then
        -- @see https://github.com/xmake-io/xmake/issues/2282
        filepath = path.absolute(filepath)
        local scriptdir = target.absscriptdir
        local filegroups_extraconf = target.filegroups_extraconf or {}
        for _, filegroup in ipairs(filegroups) do
            local extraconf = filegroups_extraconf[filegroup] or {}
            local rootdir = extraconf.rootdir
            assert(rootdir, "please set root directory, e.g. add_filegroups(%s, {rootdir = 'xxx'})", filegroup)
            for _, rootdir in ipairs(table.wrap(rootdir)) do
                if not path.is_absolute(rootdir) then
                    rootdir = path.absolute(rootdir, scriptdir)
                end
                local fileitem = path.relative(filepath, rootdir)
                local files = extraconf.files or "**"
                local mode = extraconf.mode
                for _, filepattern in ipairs(files) do
                    filepattern = path.pattern(path.absolute(path.join(rootdir, filepattern)))
                    if filepath:match(filepattern) then
                        if mode == "plain" then
                            filter = path.normalize(filegroup)
                            is_plain = true
                        else
                            -- file tree mode (default)
                            if filegroup ~= "" then
                                filter = path.normalize(path.join(filegroup, path.directory(fileitem)))
                            else
                                filter = path.normalize(path.directory(fileitem))
                            end
                        end
                        goto found_filter
                    end
                end
                -- stop once a rootdir matches
                if filter then
                    goto found_filter
                end
            end
            ::found_filter::
        end
    end
    if not filter and not is_plain then
        -- use the default filter rule
        filter = path.relative(path.absolute(path.directory(filepath)), vcxprojdir)
        -- @see https://github.com/xmake-io/xmake/issues/2039
        if filter then
            filter = _strip_dotdirs(filter)
        end
    end
    if filter and filter == '.' then
        filter = nil
    end
    return filter
end


-- make vstudio project
function main(outputdir, vsinfo)

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- init solution directory
    vsinfo.solution_dir = path.absolute(path.join(outputdir, "vsxmake" .. vsinfo.vstudio_version))
    vsinfo.programdir = _make_dirs(xmake.programdir())
    vsinfo.programfile = xmake.programfile()
    vsinfo.projectdir = project.directory()
    vsinfo.sln_projectfile = path.relative(project.rootfile(), vsinfo.solution_dir)
    local projectfile = path.filename(project.rootfile())
    vsinfo.slnfile = project.name() or path.filename(project.directory())
    -- write only if not default
    if projectfile ~= "xmake.lua" then
        vsinfo.projectfile = projectfile
    end

    vsinfo.xmake_info = format("xmake version %s", xmake.version())
    vsinfo.solution_id = hash.uuid4(project.directory() .. vsinfo.solution_dir)
    vsinfo.vs_version = vsinfo.project_version .. ".0"

    -- init modes
    vsinfo.modes = _make_vsinfo_modes()

    -- init archs
    vsinfo.archs = _make_vsinfo_archs()

    -- init groups
    local groups, group_deps = _make_vsinfo_groups()
    vsinfo.groups            = table.orderkeys(groups)
    vsinfo.group_deps        = table.orderkeys(group_deps)
    vsinfo._groups           = groups
    vsinfo._group_deps       = group_deps

    -- init config flags
    local flags = {}
    for k, v in table.orderpairs(localcache.get("config", "options")) do
        if k ~= "plat" and k ~= "mode" and k ~= "arch" and k ~= "clean" and k ~= "buildir" then
            table.insert(flags, "--" .. k .. "=" .. tostring(v))
        end
    end
    vsinfo.configflags = os.args(flags)

    -- load targets
    local targets = {}
    vsinfo._arch_modes = {}
    for _, mode in ipairs(vsinfo.modes) do
        vsinfo._arch_modes[mode] = {}
        for _, arch in ipairs(vsinfo.archs) do
            vsinfo._arch_modes[mode][arch] = { mode = mode, arch = arch }

            -- trace
            print("checking for %s.%s ...", mode, arch)

            -- reload config, project and platform
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

            -- ensure to enter project directory
            os.cd(project.directory())

            -- save targets
            for targetname, target in table.orderpairs(project.targets()) do

                -- https://github.com/xmake-io/xmake/issues/2337
                target:data_set("plugin.project.kind", "vsxmake")

                -- make target with the given mode and arch
                targets[targetname] = targets[targetname] or {}
                local _target = targets[targetname]

                -- init target info
                _target.target = targetname
                _target.vcxprojdir = path.join(vsinfo.solution_dir, targetname)
                _target.target_id = hash.uuid4(targetname)
                _target.kind = target:kind()
                _target.absscriptdir = target:scriptdir()
                _target.scriptdir = path.relative(target:scriptdir(), _target.vcxprojdir)
                _target.projectdir = path.relative(project.directory(), _target.vcxprojdir)
                local targetdir = target:get("targetdir")
                if targetdir then _target.targetdir = path.relative(targetdir, _target.vcxprojdir) end
                _target._targets = _target._targets or {}
                _target._targets[mode] = _target._targets[mode] or {}
                local targetinfo = _make_targetinfo(mode, arch, target)
                _target._targets[mode][arch] = targetinfo
                _target.sdkver = targetinfo.sdkver
                _target.default = targetinfo.default

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

                -- save deps
                _target.deps = table.unique(table.join(_target.deps or {}, table.orderkeys(target:deps()), nil))
            end
        end
    end
    os.cd(oldir)
    for _, target in table.orderpairs(targets) do
        target._paths = {}
        local dirs = {}
        local projectdir = project.directory()
        local root = target.absscriptdir or projectdir
        target.sourcefiles = table.imap(target.sourcefiles, function(_, v) return path.relative(v, projectdir) end)
        target.headerfiles = table.imap(target.headerfiles, function(_, v) return path.relative(v, projectdir) end)
        target.extrafiles = table.imap(target.extrafiles, function(_, v) return path.relative(v, projectdir) end)
        for _, f in ipairs(table.join(target.sourcefiles, target.headerfiles or {}, target.extrafiles)) do
            local dir = _make_filter(f, target, root)
            local escaped_f = vsutils.escape(f)
            target._paths[f] =
            {
                -- @see https://github.com/xmake-io/xmake/issues/2077
                path = path.is_absolute(escaped_f) and escaped_f or "$(XmakeProjectDir)\\" .. escaped_f,
                dir = vsutils.escape(dir)
            }
            while dir and dir ~= "." do
                if not dirs[dir] then
                    dirs[dir] =
                    {
                        dir = vsutils.escape(dir),
                        dir_id = hash.uuid4(dir)
                    }
                end
                dir = path.directory(dir) or "."
            end
        end
        target._dirs = dirs
        target.dirs = table.orderkeys(dirs)
        target._deps = {}
        for _, v in ipairs(target.deps) do
            target._deps[v] = targets[v]
        end
    end

    -- we need to set startup project for default or binary target
    -- @see https://github.com/xmake-io/xmake/issues/1249
    local targetnames = {}
    for targetname, target in table.orderpairs(project.targets()) do
        if target:get("default") == true then
            table.insert(targetnames, 1, targetname)
        elseif target:is_binary() then
            local first_target = targetnames[1] and project.target(targetnames[1], {namespace = target:namespace()})
            if not first_target or first_target:get("default") ~= true then
                table.insert(targetnames, 1, targetname)
            else
                table.insert(targetnames, targetname)
            end
        else
            table.insert(targetnames, targetname)
        end
    end
    vsinfo.targets = targetnames
    vsinfo._targets = targets
    return vsinfo
end
