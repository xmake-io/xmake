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
-- @file        clang.lua
--

-- imports
import("core.tool.compiler")

-- build module files
function _build_modulefiles(target, sourcebatch, opt)

    -- get modules flag
    local modulesflag
    local compinst = compiler.load("cxx", {target = target})
    if compinst:has_flags("-fmodules") then
        modulesflag = "-fmodules"
    elseif compinst:has_flags("-fmodules-ts") then
        modulesflag = "-fmodules-ts"
    end
    assert(modulesflag, "compiler(clang): does not support c++ module!")

    -- the module cache directory
    local cachedir = path.join(target:autogendir(), "rules", "modules", "cache")

    -- attempt to compile the module files as cxx
    sourcebatch.sourcekind = "cxx"
    sourcebatch.objectfiles = sourcebatch.objectfiles or {}
    sourcebatch.dependfiles = sourcebatch.dependfiles or {}
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local objectfile = path.join(cachedir, path.basename(sourcefile) .. ".pcm")
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, target:dependfile(objectfile))
    end

    -- compile module files to *.pcm
    opt = table.join(opt, {configs = {force = {cxxflags = {modulesflag,
        "-fimplicit-modules", "-fimplicit-module-maps", "-fprebuilt-module-path=" .. cachedir,
        "--precompile", "-x c++-module", "-fmodules-cache-path=" .. cachedir}}}})
    import("private.action.build.object").build(target, sourcebatch, opt)

    -- compile *.pcm to object files
    local modulefiles = {}
    for idx, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local modulefile = sourcebatch.objectfiles[idx]
        local objectfile = target:objectfile(sourcefile)
        sourcebatch.sourcefiles[idx] = modulefile
        sourcebatch.objectfiles[idx] = objectfile
        sourcebatch.dependfiles[idx] = target:dependfile(objectfile)
        table.insert(modulefiles, modulefile)
    end
    opt.configs = {cxxflags = {modulesflag, "-fmodules-cache-path=" .. cachedir,
        "-fimplicit-modules", "-fimplicit-module-maps", "-fprebuilt-module-path=" .. cachedir}}
    opt.quiet   = true
    import("private.action.build.object").build(target, sourcebatch, opt)

    -- add module files
    target:add("cxxflags", modulesflag, "-fmodules-cache-path=" .. cachedir)
    -- FIXME It is invalid for the module implementation unit
--    target:add("cxxflags", "-fimplicit-modules", "-fimplicit-module-maps", "-fprebuilt-module-path=" .. cachedir)
    for _, modulefile in ipairs(modulefiles) do
        target:add("cxxflags", "-fmodule-file=" .. modulefile)
    end
end

function build_with_batchjobs(target, batchjobs, sourcebatch, opt)
    local rootjob = opt.rootjob
    batchjobs:addjob("rule/c++.build.modules/clang", function (index, total)
        opt.progress = (index * 100) / total
        _build_modulefiles(target, sourcebatch, opt)
    end, {rootjob = rootjob})
end
