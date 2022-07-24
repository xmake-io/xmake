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
import("core.project.config")
import("private.action.build.object", {alias = "objectbuilder"})
import("module_parser")

-- load parent target with modules files
function load_parent(target, opt)
    -- get modules flag
    local modulesflag
    local compinst = compiler.load("cxx", {target = target})
    if compinst:has_flags("-fmodules") then
        modulesflag = "-fmodules"
    elseif compinst:has_flags("-fmodules-ts") then
        modulesflag = "-fmodules-ts"
    end
    assert(modulesflag, "compiler(clang): does not support c++ module!")

    -- add module flags
    target:add("cxxflags", modulesflag)

    -- add the module cache directory
    local cachedir = path.join(config.buildir(), ".gens", "rules", "modules", "cache")
    target:add("cxxflags", "-fmodules-cache-path=" .. cachedir, {force = true})
    target:add("cxxflags", "-fimplicit-modules", "-fimplicit-module-maps", "-fprebuilt-module-path=" .. cachedir, {force = true})
end

-- build module files
function build_with_batchjobs(target, opt)

    -- get modules flag
    local modulesflag
    local compinst = compiler.load("cxx", {target = target})
    if compinst:has_flags("-fmodules") then
        modulesflag = "-fmodules"
    elseif compinst:has_flags("-fmodules-ts") then
        modulesflag = "-fmodules-ts"
    end
    assert(modulesflag, "compiler(clang): does not support c++ module!")

    -- get the module cache directory, @note we must use same cache directory for each targets
    -- @see https://github.com/xmake-io/xmake/issues/2194
    --
    local cachedir = path.join(config.buildir(), ".gens", "rules", "modules", "cache")

    -- we need patch objectfiles to sourcebatch for linking module objects
    sourcebatch.sourcekind = "cxx"
    sourcebatch.objectfiles = sourcebatch.objectfiles or {}
    sourcebatch.dependfiles = sourcebatch.dependfiles or {}
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local objectfile = target:objectfile(sourcefile)
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, target:dependfile(objectfile))
    end

    -- load moduledeps
    local moduledeps, moduledeps_files = module_parser.load(target, sourcebatch, opt)

    -- compile module files to object files
    local count = 0
    local modulefiles = {}
    local sourcefiles_total = #sourcebatch.sourcefiles
    for i = 1, sourcefiles_total do
        local sourcefile = sourcebatch.sourcefiles[i]
        local moduleinfo = moduledeps_files[sourcefile] or {}

        -- make module file path, @note we need process submodule name, e.g. module.submodule.mpp -> module.submodule.pcm
        -- @see https://github.com/xmake-io/xmake/pull/1982
        local modulefile = path.join(cachedir, (moduleinfo.name or path.basename(sourcefile)) .. ".pcm")
        table.insert(modulefiles, modulefile)

        -- make build job
        moduleinfo.job = batchjobs:newjob(sourcefile, function (index, total)

            -- compile module files to *.pcm
            local opt2 = table.join(opt, {configs = {force = {cxxflags = {modulesflag,
                "-fimplicit-modules", "-fimplicit-module-maps", "-fprebuilt-module-path=" .. cachedir,
                "--precompile", "-x c++-module", "-fmodules-cache-path=" .. cachedir}}}})
            opt2.progress   = (index * 100) / total
            opt2.objectfile = modulefiles[i]
            opt2.dependfile = target:dependfile(opt2.objectfile)
            opt2.sourcekind = assert(sourcebatch.sourcekind, "%s: sourcekind not found!", sourcefile)
            objectbuilder.build_object(target, sourcefile, opt2)

            -- compile *.pcm to object files
            opt2.configs    = {force = {cxxflags = {modulesflag, "-fmodules-cache-path=" .. cachedir,
                "-fimplicit-modules", "-fimplicit-module-maps", "-fprebuilt-module-path=" .. cachedir}}}
            opt2.quiet      = true
            opt2.objectfile = sourcebatch.objectfiles[i]
            opt2.dependfile = sourcebatch.dependfiles[i]
            objectbuilder.build_object(target, modulefiles[i], opt2)

            -- add module flags to other c++ files after building all modules
            count = count + 1
            if count == sourcefiles_total then
                target:add("cxxflags", modulesflag, "-fmodules-cache-path=" .. cachedir, {force = true})
                -- FIXME It is invalid for the module implementation unit
                --target:add("cxxflags", "-fimplicit-modules", "-fimplicit-module-maps", "-fprebuilt-module-path=" .. cachedir, {force = true})
                for _, modulefile in ipairs(modulefiles) do
                    target:add("cxxflags", "-fmodule-file=" .. modulefile, {force = true})
                end
            end
        end)
    end

    -- build batchjobs
    module_parser.build_batchjobs(moduledeps, batchjobs, opt.rootjob)
end
