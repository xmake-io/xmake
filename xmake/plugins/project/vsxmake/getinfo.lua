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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      OpportunityLiu
-- @file        getinfo.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("core.platform.environment")
import("core.tool.compiler")
import("core.tool.linker")
import("lib.detect.find_tool")
import("actions.config.configheader", {alias = "generate_configheader", rootdir = os.programdir()})
import("actions.config.configfiles", {alias = "generate_configfiles", rootdir = os.programdir()})

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
                return path.join("$(XmakeProjectDir)", path.relative(dir, project.directory()))
            end
            return dir
        end
        return path.join("$(XmakeProjectDir)", dir)
    end
    local r = {}
    for k, v in ipairs(dir) do
        r[k] = _make_dirs(v)
    end
    r = table.unique(r)
    return table.concat(r, path.envsep())
end

function _get_values(target, name)
    local values = table.wrap(target:get(name))
    for _, dep in irpairs(target:orderdeps()) do
        local depinherit = target:extraconf("deps", dep:name(), "inherit")
        if depinherit == nil or depinherit then
            table.join2(values, dep:get(name, {interface = true}))
        end
    end
    return values
end

-- make target info
function _make_targetinfo(mode, arch, target)

    -- init target info
    local targetinfo = { mode = mode, arch = arch, plat = config.get("plat"), vsarch = (arch == "x86" and "Win32" or arch) }

    -- write only if not default
    -- use target:get("xxx") rather than target:xxx()

    -- save target kind
    targetinfo.kind          = target:get("kind")

    -- save target file
    targetinfo.basename      = target:get("basename")
    targetinfo.filename      = target:get("filename")

    -- save dirs
    targetinfo.targetdir     = _make_dirs(target:get("targetdir"))
    targetinfo.buildir       = _make_dirs(config.get("buildir"))
    targetinfo.rundir        = _make_dirs(target:get("rundir"))
    targetinfo.configdir     = _make_dirs(os.getenv("XMAKE_CONFIGDIR"))
    targetinfo.configfiledir = _make_dirs(target:get("configdir"))
    targetinfo.includedirs   = _make_dirs(_get_values(target, "includedirs"))
    targetinfo.linkdirs      = _make_dirs(_get_values(target, "linkdirs"))

    -- save defines
    targetinfo.defines       = table.concat(_get_values(target, "defines"), ";")
    targetinfo.languages     = table.concat(_get_values(target, "languages"), ";")

    -- save runenvs
    local runenvs = {}
    for k, v in pairs(target:get("runenvs")) do
        local defs = {}
        for _, d in ipairs(v) do
            table.insert(defs, vformat(d))
        end
        table.insert(runenvs, format("%s=%s", k, table.concat(defs, path.envsep())))
    end
    targetinfo.runenvs = table.concat(runenvs, "\n")

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

    -- ok
    return targetinfo
end

function _make_vsinfo_modes()
    local vsinfo_modes = {}
    local modes = option.get("modes")
    if modes then
        for _, mode in ipairs(modes:split(',')) do
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
        for _, arch in ipairs(archs:split(',')) do
            table.insert(vsinfo_archs, arch:trim())
        end
    else
        vsinfo_archs = platform.archs()
    end
    if not vsinfo_archs or #vsinfo_archs == 0 then
        vsinfo_archs = { config.arch() }
    end
    return vsinfo_archs
end

-- make vstudio project
function main(outputdir, vsinfo)

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- init solution directory
    vsinfo.solution_dir = path.absolute(path.join(outputdir, "vsxmake" .. vsinfo.vstudio_version))
    vsinfo.programdir = xmake.programdir()
    vsinfo.projectdir = project.directory()
    vsinfo.sln_projectfile = path.relative(project.file(), vsinfo.solution_dir)
    local projectfile = path.filename(project.file())
    vsinfo.slnfile = path.filename(project.directory())
    -- write only if not default
    if projectfile ~= "xmake.lua" then
        vsinfo.projectfile = projectfile
        vsinfo.slnfile = path.basename(projectfile)
    end

    vsinfo.xmake_info = format("xmake version %s", xmake.version())
    vsinfo.solution_id = hash.uuid(project.directory() .. vsinfo.solution_dir)
    vsinfo.vs_version = vsinfo.project_version .. ".0"

    -- init modes
    vsinfo.modes = _make_vsinfo_modes()
    -- init archs
    vsinfo.archs = _make_vsinfo_archs()

    -- load targets
    local targets = {}
    vsinfo._sub2 = {}
    for _, mode in ipairs(vsinfo.modes) do
        vsinfo._sub2[mode] = {}
        for _, arch in ipairs(vsinfo.archs) do
            vsinfo._sub2[mode][arch] = { mode = mode, arch = arch }

            -- trace
            print("checking for the %s.%s ...", mode, arch)

            -- reload config, project and platform
            -- modify config
            config.set("as", nil, {force = true}) -- force to re-check as for ml/ml64
            config.set("mode", mode, {readonly = true, force = true})
            config.set("arch", arch, {readonly = true, force = true})

            -- clear project to reload and recheck it
            project.clear()

            -- check project options
            project.check()

            -- reload platform
            platform.load(config.plat())

            -- re-generate configheader
            generate_configheader()

            -- re-generate configfiles
            generate_configfiles()

            -- ensure to enter project directory
            os.cd(project.directory())

            -- enter environment (maybe check flags by calling tools)
            environment.enter("toolchains")

            -- save targets
            for targetname, target in pairs(project.targets()) do
                if not target:isphony() then

                    -- make target with the given mode and arch
                    targets[targetname] = targets[targetname] or {}
                    local _target = targets[targetname]

                    -- init target info
                    _target.target = targetname
                    _target.vcxprojdir = path.join(vsinfo.solution_dir, targetname)
                    _target.target_id = hash.uuid(targetname)
                    _target.kind = target:targetkind()
                    _target.scriptdir = path.relative(target:scriptdir(), _target.vcxprojdir)
                    _target.projectdir = path.relative(project.directory(), _target.vcxprojdir)
                    local tgtdir = target:get("targetdir")
                    if tgtdir then _target.targetdir = path.relative(tgtdir, _target.vcxprojdir) end
                    _target._sub = _target._sub or {}
                    _target._sub[mode] = _target._sub[mode] or {}
                    _target._sub[mode][arch] = _make_targetinfo(mode, arch, target)

                    -- save all sourcefiles and headerfiles
                    _target.sourcefiles = table.unique(table.join(_target.sourcefiles or {}, (target:sourcefiles())))
                    _target.headerfiles = table.unique(table.join(_target.headerfiles or {}, (target:headerfiles())))

                    _target.deps = table.unique(table.join(_target.deps or {}, table.keys(target:deps()), nil))
                end
            end

            -- leave environment
            environment.leave("toolchains")
        end
    end

    -- leave project directory
    os.cd(oldir)
    for _,target in pairs(targets) do
        target._sub2 = {}
        local dirs = {}
        for _,f in ipairs(table.join(target.sourcefiles, target.headerfiles)) do
            local dir = path.directory(f)
            target._sub2[f] =
            {
                path = path.join("$(XmakeProjectDir)", f),
                dir = dir
            }
            while dir ~= "." do
                if not dirs[dir] then
                    dirs[dir] =
                    {
                        dir = dir,
                        dir_id = hash.uuid(dir)
                    }
                end
                dir = path.directory(dir)
            end
        end
        target._sub3 = dirs
        target.dirs = table.keys(dirs)
        target._sub4 = {}
        for _, v in ipairs(target.deps) do
            target._sub4[v] = targets[v]
        end
    end
    vsinfo.targets = table.keys(targets)
    vsinfo._sub = targets
    return vsinfo
end
