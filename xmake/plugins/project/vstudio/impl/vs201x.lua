--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
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
import("vs201x_solution")
import("vs201x_vcxproj")
import("vs201x_vcxproj_filters")
import("actions.config.configheader", {rootdir = os.programdir()})

-- make target info
function _make_targetinfo(mode, arch, target)

    -- init target info
    local targetinfo = { mode = mode, arch = ifelse(arch == "x86", "Win32", "x64") }

    -- get sdk version
    local vcvarsall = config.get("__vcvarsall")
    if vcvarsall then
        targetinfo.sdkver = (vcvarsall[arch] or {}).sdkver
    end

    -- save symbols
    targetinfo.symbols = target:get("symbols")

    -- save target kind
    targetinfo.targetkind = target:targetkind()

    -- save target file
    targetinfo.targetfile = target:targetfile()

    -- save sourcebatches
    targetinfo.sourcebatches = target:sourcebatches()

    -- save compiler flags
    targetinfo.compflags = {}
    for _, sourcefile in ipairs(target:sourcefiles()) do
        local _, compflags = compiler.compflags(sourcefile, {target = target})
        targetinfo.compflags[sourcefile] = compflags
    end

    -- save linker flags
    local _, linkflags = linker.linkflags(target:get("kind"), target:sourcekinds(), {target = target})
    targetinfo.linkflags = linkflags

    -- ok
    return targetinfo
end

-- make target headers
function _make_targetheaders(mode, arch, target, last)

    -- only for static and shared target
    local kind = target:get("kind")
    if kind == "static" or kind == "shared" then

        -- make headers
        local srcheaders, dstheaders = target:headerfiles()
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

-- make vstudio project
function make(outputdir, vsinfo)

    -- enter project directory
    local olddir = os.cd(project.directory())

    -- init solution directory
    vsinfo.solution_dir = path.join(outputdir, "vs" .. vsinfo.vstudio_version)

    -- init modes
    local modes = option.get("modes")
    if modes then
        vsinfo.modes = {}
        for _, mode in ipairs(modes:split(',')) do
            table.insert(vsinfo.modes, mode:trim())
        end
    else
        vsinfo.modes = project.modes()
    end
    if not vsinfo.modes or #vsinfo.modes == 0 then
        vsinfo.modes = { config.mode() }
    end

    -- load targets
    local targets = {}
    for mode_idx, mode in ipairs(vsinfo.modes) do
        for arch_idx, arch in ipairs({"x86", "x64"}) do

            -- trace
            print("checking for the %s.%s ...", mode, arch)

            -- reload config, project and platform
            if mode ~= config.mode() or arch ~= config.arch() then
                
                -- modify config
                config.set("mode", mode)
                config.set("arch", arch)

                -- recheck project options
                project.check(true)

                -- reload platform
                platform.load(config.plat())

                -- reload project
                project.load()

                -- remake configheader
                configheader.make()
            end

            -- ensure to enter project directory
            os.cd(project.directory())

            -- save targets
            for targetname, target in pairs(project.targets()) do
                if not target:isphony() then

                    -- make target with the given mode and arch
                    targets[targetname] = targets[targetname] or {}
                    local _target = targets[targetname]

                    -- init target info
                    _target.name = targetname
                    _target.kind = target:get("kind")
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

    -- leave project directory
    os.cd(olddir)
end
