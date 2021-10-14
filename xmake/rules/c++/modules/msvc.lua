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

-- build module files
function _build_modulefiles(target, sourcebatch, opt)

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

    -- attempt to compile the module files as cxx
    local modulefiles = {}
    opt = table.join(opt, {configs = {}})
    sourcebatch.sourcekind = "cxx"
    sourcebatch.objectfiles = sourcebatch.objectfiles or {}
    sourcebatch.dependfiles = sourcebatch.dependfiles or {}
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local objectfile = target:objectfile(sourcefile)
        local dependfile = target:dependfile(objectfile)
        local modulefile = (cachedir and path.join(cachedir, path.basename(sourcefile)) or objectfile) .. ".ifc"

        -- compile module file to *.pcm
        local singlebatch = {sourcekind = "cxx", sourcefiles = {sourcefile}, objectfiles = {objectfile}, dependfiles = {dependfile}}
        opt.configs.cxxflags = {modulesflag, interfaceflag, outputflag .. " " .. os.args(modulefile), "/TP"}
        if cachedir then
            table.insert(opt.configs.cxxflags, "/ifcSearchDir " .. os.args(cachedir))
        end
        import("private.action.build.object").build(target, singlebatch, opt)
        table.insert(modulefiles, modulefile)
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, dependfile)
    end

    -- add module files
    for _, modulefile in ipairs(modulefiles) do
        target:add("cxxflags", modulesflag)
        if cachedir then
            target:add("cxxflags", "/ifcSearchDir " .. os.args(cachedir))
        else
            target:add("cxxflags", referenceflag .. " " .. os.args(modulefile))
        end
    end
end

function build_with_batchjobs(target, batchjobs, sourcebatch, opt)
    local rootjob = opt.rootjob
    batchjobs:addjob("rule/c++.build.modules/msvc", function (index, total)
        opt.progress = (index * 100) / total
        _build_modulefiles(target, sourcebatch, opt)
    end, {rootjob = rootjob})
end
