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
-- @file        msvc.lua
--

-- imports
import("core.tool.compiler")
import("private.action.build.object", {alias = "objectbuilder"})
import("module_parser")

-- load parent target with modules files
function load_parent(target, opt)

    -- get modules flag
    local modulesflag
    local compinst = compiler.load("cxx", {target = target})
    if compinst:has_flags("/experimental:module", "cxxflags") then
        modulesflag = "/experimental:module"
    end
    assert(modulesflag, "compiler(msvc): does not support c++ module!")

    -- add module flags
    target:add("cxxflags", modulesflag)

    -- get output flag
    if compinst:has_flags("/ifcOutput", "cxxflags")  then
        for _, dep in ipairs(target:orderdeps()) do
            local sourcebatches = dep:sourcebatches()
            if sourcebatches and sourcebatches["c++.build.modules"] then
                local cachedir = path.join(dep:autogendir(), "rules", "modules", "cache")
                target:add("cxxflags", {"/ifcSearchDir", cachedir}, {force = true, expand = false})
            end
        end
    end
end

-- build module files
function build_with_batchjobs(target, batchjobs, sourcebatch, opt)

    -- get modules flag
    local modulesflag
    local compinst = compiler.load("cxx", {target = target})
    if compinst:has_flags("/experimental:module", "cxxflags") then
        modulesflag = "/experimental:module"
    end
    assert(modulesflag, "compiler(msvc): does not support c++ module!")

    -- get output flag
    local cachedir
    local outputflag
    if compinst:has_flags("/ifcOutput", "cxxflags")  then
        outputflag = "/ifcOutput"
        cachedir = path.join(target:autogendir(), "rules", "modules", "cache")
        if not os.isdir(cachedir) then
            os.mkdir(cachedir)
        end
    elseif compinst:has_flags("/module:output", "cxxflags") then
        outputflag = "/module:output"
    end
    assert(outputflag, "compiler(msvc): does not support c++ module!")

    -- get interface flag
    local interfaceflag
    if compinst:has_flags("/interface", "cxxflags") then
        interfaceflag = "/interface"
    elseif compinst:has_flags("/module:interface", "cxxflags") then
        interfaceflag = "/module:interface"
    end
    assert(interfaceflag, "compiler(msvc): does not support c++ module!")

    -- get reference flag
    local referenceflag
    if compinst:has_flags("/reference", "cxxflags") then
        referenceflag = "/reference"
    elseif compinst:has_flags("/module:interface", "cxxflags") then
        referenceflag = "/module:reference"
    end
    assert(referenceflag, "compiler(msvc): does not support c++ module!")

    -- get stdifcdir flag
    local stdifcdirflag
    if compinst:has_flags("/stdIfcDir", "cxxflags") then
        stdifcdirflag = "/stdIfcDir"
    elseif compinst:has_flags("/module:stdIfcDir", "cxxflags") then
        stdifcdirflag = "/module:stdIfcDir"
    end
    assert(stdifcdirflag, "compiler(msvc): does not support c++ module!")

    -- we need patch objectfiles to sourcebatch for linking module objects
    local modulefiles = {}
    sourcebatch.sourcekind = "cxx"
    sourcebatch.objectfiles = sourcebatch.objectfiles or {}
    sourcebatch.dependfiles = sourcebatch.dependfiles or {}
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local objectfile = target:objectfile(sourcefile)
        local dependfile = target:dependfile(objectfile)
        local modulefile = (cachedir and path.join(cachedir, path.basename(sourcefile)) or objectfile) .. ".ifc"
        table.insert(modulefiles, modulefile)
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, dependfile)
    end

    -- load moduledeps
    local moduledeps = module_parser.load(target, sourcebatch, opt)

    -- build moduledeps
    local moduledeps_files = module_parser.build(moduledeps)

    -- compile module files to object files
    local count = 0
    local sourcefiles_total = #sourcebatch.sourcefiles
    for i = 1, sourcefiles_total do
        local sourcefile = sourcebatch.sourcefiles[i]
        local moduledep = assert(moduledeps_files[sourcefile], "moduledep(%s) not found!", sourcefile)
        moduledep.job = batchjobs:newjob(sourcefile, function (index, total)
            local opt2 = table.join(opt, {configs = {force = {cxxflags = {
                    interfaceflag,
                    {outputflag, modulefiles[i]},
                    "/TP"}}}})
            opt2.progress   = (index * 100) / total
            opt2.objectfile = sourcebatch.objectfiles[i]
            opt2.dependfile = sourcebatch.dependfiles[i]
            opt2.sourcekind = assert(sourcebatch.sourcekind, "%s: sourcekind not found!", sourcefile)
            objectbuilder.build_object(target, sourcefile, opt2)

            -- add module flags to other c++ files after building all modules
            count = count + 1
            if count == sourcefiles_total and not cachedir then
                for _, modulefile in ipairs(modulefiles) do
                    target:add("cxxflags", {referenceflag, modulefile}, {force = true, expand = false})
                end
            end
        end)
    end

    -- add module flags
    target:add("cxxflags", modulesflag)
    if cachedir then
        target:add("cxxflags", {"/ifcSearchDir", cachedir}, {force = true, expand = false})
    end
    if stdifcdirflag then
        for _, toolchain_inst in ipairs(target:toolchains()) do
            if toolchain_inst:name() == "msvc" then
                local vcvars = toolchain_inst:config("vcvars")
                if vcvars.VCInstallDir and vcvars.VCToolsVersion then
                    local stdifcdir = path.join(vcvars.VCInstallDir, "Tools", "MSVC", vcvars.VCToolsVersion, "ifc", target:is_arch("x64") and "x64" or "x86")
                    if os.isdir(stdifcdir) then
                        target:add("cxxflags", {stdifcdirflag, winos.short_path(stdifcdir)}, {force = true, expand = false})
                    end
                end
                break
            end
        end
    end

    -- build batchjobs
    local rootjob = opt.rootjob
    for _, moduledep in pairs(moduledeps) do
        if moduledep.parents then
            for _, parent in ipairs(moduledep.parents) do
                batchjobs:add(moduledep.job, parent.job)
            end
        else
           batchjobs:add(moduledep.job, rootjob)
        end
    end
end

