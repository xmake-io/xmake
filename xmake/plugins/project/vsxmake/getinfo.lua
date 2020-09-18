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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      OpportunityLiu
-- @file        getinfo.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.base.hashset")
import("core.project.config")
import("core.project.cache")
import("core.project.project")
import("core.platform.platform")
import("core.tool.compiler")
import("core.tool.linker")
import("lib.detect.find_tool")
import("private.action.run.make_runenvs")
import("actions.config.configheader", {alias = "generate_configheader", rootdir = os.programdir()})
import("actions.config.configfiles", {alias = "generate_configfiles", rootdir = os.programdir()})

-- escape special chars in msbuild file
function _escape(str)
    if not str then
        return nil
    end

    local map =
    {
         ["%"] = "%25" -- Referencing metadata
    ,    ["$"] = "%24" -- Referencing properties
    ,    ["@"] = "%40" -- Referencing item lists
    ,    ["'"] = "%27" -- Conditions and other expressions
    ,    [";"] = "%3B" -- List separator
    ,    ["?"] = "%3F" -- Wildcard character for file names in Include and Exclude attributes
    ,    ["*"] = "%2A" -- Wildcard character for use in file names in Include and Exclude attributes
    -- html entities
    ,    ["\""] = "&quot;"
    ,    ["<"] = "&lt;"
    ,    [">"] = "&gt;"
    ,    ["&"] = "&amp;"
    }

    return (string.gsub(str, "[%%%$@';%?%*\"<>&]", function (c) return assert(map[c]) end))
end

function _vs_arch(arch)
    if arch == 'x86' or arch == 'i386' then return "Win32" end
    if arch == 'x86_64' then return "x64" end
    if arch:startswith('arm64') then return "ARM64" end
    if arch:startswith('arm') then return "ARM" end
    return arch
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
                return path.join("$(XmakeProjectDir)", _escape(path.relative(dir, project.directory())))
            end
            return _escape(dir)
        end
        return path.join("$(XmakeProjectDir)", _escape(dir))
    end
    local r = {}
    for k, v in ipairs(dir) do
        r[k] = _make_dirs(v)
    end
    r = table.unique(r)
    return path.joinenv(r)
end

function _make_arrs(arr)
    if arr == nil then
        return ""
    end
    if type(arr) == "string" then
        return _escape(arr)
    end
    local r = {}
    for k, v in ipairs(arr) do
        r[k] = _make_arrs(v)
    end
    r = table.unique(r)
    return table.concat(r, ";")
end

-- get values from target
function _get_values_from_target(target, name)
    local values = table.wrap(target:get(name))
    table.join2(values, target:get_from_opts(name))
    table.join2(values, target:get_from_pkgs(name))
    table.join2(values, target:get_from_deps(name, {interface = true}))
    return table.unique(values)
end

-- make target info
function _make_targetinfo(mode, arch, target)

    -- init target info
    local targetinfo =
    {
        mode = mode
    ,   arch = arch
    ,   plat = config.get("plat")
    ,   vsarch = _vs_arch(arch)
    ,   sdkver = config.get("vs_sdkver")
    }

    -- write only if not default
    -- use target:get("xxx") rather than target:xxx()

    -- save target kind
    targetinfo.kind          = target:get("kind")

    -- save target file
    targetinfo.basename      = _escape(target:get("basename"))
    targetinfo.filename      = _escape(target:get("filename"))

    -- save dirs
    targetinfo.targetdir     = _make_dirs(target:get("targetdir"))
    targetinfo.buildir       = _make_dirs(config.get("buildir"))
    targetinfo.rundir        = _make_dirs(target:get("rundir"))
    targetinfo.configdir     = _make_dirs(os.getenv("XMAKE_CONFIGDIR"))
    targetinfo.configfiledir = _make_dirs(target:get("configdir"))
    targetinfo.includedirs   = _make_dirs(_get_values_from_target(target, "includedirs"))
    targetinfo.linkdirs      = _make_dirs(_get_values_from_target(target, "linkdirs"))
    targetinfo.sourcedirs    = _make_dirs(_get_values_from_target(target, "values.project.vsxmake.sourcedirs"))

    -- save defines
    targetinfo.defines       = _make_arrs(_get_values_from_target(target, "defines"))
    targetinfo.languages     = _make_arrs(_get_values_from_target(target, "languages"))
    local configcache = cache("local.config")
    local flags = {}
    for k, v in pairs(configcache:get("options_" .. target:name())) do
        if k ~= "plat" and k ~= "mode" and k ~= "arch" and k ~= "clean" and k ~= "buildir" then
            table.insert(flags, "--" .. k .. "=" .. tostring(v));
        end
    end
    targetinfo.configflags   = os.args(flags)

    -- save runenvs
    local runenvs = {}
    local addrunenvs, setrunenvs = make_runenvs(target)
    for k, v in pairs(addrunenvs) do
        if k:upper() == "PATH" then
            runenvs[k] = format("%s;$([System.Environment]::GetEnvironmentVariable('%s'))", _make_dirs(v), k)
        else
            runenvs[k] = format("%s;$([System.Environment]::GetEnvironmentVariable('%s'))", path.joinenv(v), k)
        end
    end
    for k, v in pairs(setrunenvs) do
        if #v == 1 then
            v = v[1]
            if path.is_absolute(v) and v:startswith(project.directory()) then
                runenvs[k] = _make_dirs(v)
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
    vsinfo.programdir = _make_dirs(xmake.programdir())
    vsinfo.projectdir = project.directory()
    vsinfo.sln_projectfile = path.relative(project.rootfile(), vsinfo.solution_dir)
    local projectfile = path.filename(project.rootfile())
    vsinfo.slnfile = path.filename(project.directory())
    -- write only if not default
    if projectfile ~= "xmake.lua" then
        vsinfo.projectfile = projectfile
        vsinfo.slnfile = path.basename(projectfile)
    end

    vsinfo.xmake_info = format("xmake version %s", xmake.version())
    vsinfo.solution_id = hash.uuid4(project.directory() .. vsinfo.solution_dir)
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
            print("checking for %s.%s ...", mode, arch)

            -- reload config, project and platform
            -- modify config
            config.set("as", nil, {force = true}) -- force to re-check as for ml/ml64
            config.set("mode", mode, {readonly = true, force = true})
            config.set("arch", arch, {readonly = true, force = true})

            -- clear project to reload and recheck it
            project.clear()

            -- check configure
            config.check()

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

            -- save targets
            for targetname, target in pairs(project.targets()) do
                if not target:isphony() then

                    -- make target with the given mode and arch
                    targets[targetname] = targets[targetname] or {}
                    local _target = targets[targetname]

                    -- init target info
                    _target.target = targetname
                    _target.vcxprojdir = path.join(vsinfo.solution_dir, targetname)
                    _target.target_id = hash.uuid4(targetname)
                    _target.kind = target:targetkind()
                    _target.scriptdir = path.relative(target:scriptdir(), _target.vcxprojdir)
                    _target.projectdir = path.relative(project.directory(), _target.vcxprojdir)
                    local tgtdir = target:get("targetdir")
                    if tgtdir then _target.targetdir = path.relative(tgtdir, _target.vcxprojdir) end
                    _target._sub = _target._sub or {}
                    _target._sub[mode] = _target._sub[mode] or {}
                    local tgtinfo = _make_targetinfo(mode, arch, target)
                    _target._sub[mode][arch] = tgtinfo
                    _target.sdkver = tgtinfo.sdkver

                    -- save all sourcefiles and headerfiles
                    _target.sourcefiles = table.unique(table.join(_target.sourcefiles or {}, (target:sourcefiles())))
                    _target.headerfiles = table.unique(table.join(_target.headerfiles or {}, (target:headerfiles())))

                    _target.deps = table.unique(table.join(_target.deps or {}, table.keys(target:deps()), nil))
                end
            end
        end
    end

    -- leave project directory
    os.cd(oldir)
    for _,target in pairs(targets) do
        target._sub2 = {}
        local dirs = {}
        local root = project.directory()
        target.sourcefiles = table.imap(target.sourcefiles, function(_, v) return path.relative(v, root) end)
        target.headerfiles = table.imap(target.headerfiles, function(_, v) return path.relative(v, root) end)
        for _, f in ipairs(table.join(target.sourcefiles, target.headerfiles)) do
            local dir = path.directory(f)
            target._sub2[f] =
            {
                path = _escape(f),
                dir = _escape(dir)
            }
            while dir ~= "." do
                if not dirs[dir] then
                    dirs[dir] =
                    {
                        dir = _escape(dir),
                        dir_id = hash.uuid4(dir)
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
