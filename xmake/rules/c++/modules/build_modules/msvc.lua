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

-- build module files
function build_with_batchjobs(target, batchjobs, sourcebatch, opt)

    -- get modules flag
    local modulesflag
    local compinst = compiler.load("cxx", {target = target})
    if compinst:has_flags("/experimental:module") then
        modulesflag = "/experimental:module"
    end
    assert(modulesflag, "compiler(msvc): does not support c++ module!")

    -- get output flag
    local cachedir
    local outputflag
    if compinst:has_flags("/ifcOutput")  then
        outputflag = "/ifcOutput"
        cachedir = path.join(target:autogendir(), "rules", "modules", "cache")
        if not os.isdir(cachedir) then
            os.mkdir(cachedir)
        end
    elseif compinst:has_flags("/module:output") then
        outputflag = "/module:output"
    end
    assert(outputflag, "compiler(msvc): does not support c++ module!")

    -- get interface flag
    local interfaceflag
    if compinst:has_flags("/interface") then
        interfaceflag = "/interface"
    elseif compinst:has_flags("/module:interface") then
        interfaceflag = "/module:interface"
    end
    assert(interfaceflag, "compiler(msvc): does not support c++ module!")

    -- get reference flag
    local referenceflag
    if compinst:has_flags("/reference") then
        referenceflag = "/reference"
    elseif compinst:has_flags("/module:interface") then
        referenceflag = "/module:reference"
    end
    assert(referenceflag, "compiler(msvc): does not support c++ module!")

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
    --print(moduledeps)

    -- compile module files to object files
    local rootjob = opt.rootjob
    local count = 0
    local sourcefiles_total = #sourcebatch.sourcefiles
    for i = 1, sourcefiles_total do
        local sourcefile = sourcebatch.sourcefiles[i]
        batchjobs:addjob(sourcefile, function (index, total)
            local opt2 = table.join(opt, {configs = {force = {cxxflags = {interfaceflag,
                outputflag .. " " .. os.args(modulefiles[i]), "/TP"}}}})
            opt2.progress   = (index * 100) / total
            opt2.objectfile = sourcebatch.objectfiles[i]
            opt2.dependfile = sourcebatch.dependfiles[i]
            opt2.sourcekind = assert(sourcebatch.sourcekind, "%s: sourcekind not found!", sourcefile)
            objectbuilder.build_object(target, sourcefile, opt2)

            -- add module flags to other c++ files after building all modules
            count = count + 1
            if count == sourcefiles_total and not cachedir then
                for _, modulefile in ipairs(modulefiles) do
                    target:add("cxxflags", referenceflag .. " " .. os.args(modulefile))
                end
            end
        end, {rootjob = rootjob})
    end

    -- add module flags
    target:add("cxxflags", modulesflag)
    if cachedir then
        target:add("cxxflags", "/ifcSearchDir " .. os.args(cachedir))
    end
end

