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
-- @file        gcc.lua
--

-- imports
import("core.tool.compiler")
import("private.action.build.object", {alias = "objectbuilder"})

-- build module files
function build_with_batchjobs(target, batchjobs, sourcebatch, opt)

    -- get modules flag
    local modulesflag
    local compinst = compiler.load("cxx", {target = target})
    if compinst:has_flags("-fmodules-ts") then
        modulesflag = "-fmodules-ts"
    end
    assert(modulesflag, "compiler(gcc): does not support c++ module!")

    -- we need patch objectfiles to sourcebatch for linking module objects
    sourcebatch.sourcekind = "cxx"
    sourcebatch.objectfiles = sourcebatch.objectfiles or {}
    sourcebatch.dependfiles = sourcebatch.dependfiles or {}
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local objectfile = target:objectfile(sourcefile)
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, target:dependfile(objectfile))
    end

    -- compile module files to object files
    local rootjob = opt.rootjob
    for i = 1, #sourcebatch.sourcefiles do
        local sourcefile = sourcebatch.sourcefiles[i]
        batchjobs:addjob(sourcefile, function (index, total)
            opt = table.join(opt, {configs = {force = {cxxflags = {modulesflag, "-x c++"}}}})
            opt.progress   = (index * 100) / total
            opt.objectfile = sourcebatch.objectfiles[i]
            opt.dependfile = sourcebatch.dependfiles[i]
            opt.sourcekind = assert(sourcebatch.sourcekind, "%s: sourcekind not found!", sourcefile)
            objectbuilder.build_object(target, sourcefile, opt)
        end, {rootjob = rootjob})
    end

    -- add module files
    target:add("cxxflags", modulesflag)
end

