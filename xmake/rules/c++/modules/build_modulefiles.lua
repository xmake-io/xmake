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
-- @author      ruki
-- @file        build_modulefiles.lua
--

-- imports
import("core.tool.compiler")

-- build module files using clang
function _build_modulefiles_clang(target, sourcebatch, opt)

    -- attempt to compile the module files as cxx
    sourcebatch.sourcekind = "cxx"
    sourcebatch.objectfiles = sourcebatch.objectfiles or {}
    sourcebatch.dependfiles = sourcebatch.dependfiles or {}
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local objectfile = target:objectfile(sourcefile) .. ".pcm"
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, target:dependfile(objectfile))
    end

    -- compile module files to *.pcm
    opt = table.join(opt, {configs = {force = {cxxflags = {"-fmodules-ts", "--precompile", "-x c++-module"}}}})
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
    opt.configs = {cxxflags = {"-fmodules-ts"}}
    opt.quiet   = true
    import("private.action.build.object").build(target, sourcebatch, opt)

    -- add module files
    target:add("cxxflags", "-fmodules-ts")
    for _, modulefile in ipairs(modulefiles) do
        target:add("cxxflags", "-fmodule-file=" .. modulefile)
    end
end

-- TODO
-- build module files using gcc
function _build_modulefiles_gcc(target, sourcebatch, opt)

    --[[
    -- attempt to compile the module files as cxx
    local modulefiles = {}
    opt = table.join(opt, {configs = {}})
    sourcebatch.sourcekind = "cxx"
    sourcebatch.objectfiles = sourcebatch.objectfiles or {}
    sourcebatch.dependfiles = sourcebatch.dependfiles or {}
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local objectfile = target:objectfile(sourcefile)
        local dependfile = target:dependfile(objectfile)
        local modulefile = objectfile .. ".pcm"

        -- compile module file to *.pcm
        local singlebatch = {sourcekind = "cxx", sourcefiles = {sourcefile}, objectfiles = {objectfile}, dependfiles = {dependfile}}
        opt.configs.cxxflags = {"-fmodules-ts", "-fmodule-output=" .. modulefile, "-x c++"}
        import("private.action.build.object").build(target, singlebatch, opt)
        table.insert(modulefiles, modulefile)
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, dependfile)
    end

    -- add module files
    for _, modulefile in ipairs(modulefiles) do
        target:add("cxxflags", "-fmodules-ts", "-fmodule-file=" .. modulefile)
    end]]
    raise("compiler(gcc): not implemented for c++ module!")
end

-- build module files using msvc
function _build_modulefiles_msvc(target, sourcebatch, opt)

    -- attempt to compile the module files as cxx
    local modulefiles = {}
    opt = table.join(opt, {configs = {}})
    sourcebatch.sourcekind = "cxx"
    sourcebatch.objectfiles = sourcebatch.objectfiles or {}
    sourcebatch.dependfiles = sourcebatch.dependfiles or {}
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local objectfile = target:objectfile(sourcefile)
        local dependfile = target:dependfile(objectfile)
        local modulefile = objectfile .. ".pcm"

        -- compile module file to *.pcm
        local singlebatch = {sourcekind = "cxx", sourcefiles = {sourcefile}, objectfiles = {objectfile}, dependfiles = {dependfile}}
        opt.configs.cxxflags = {"/experimental:module /module:interface /module:output " .. os.args(modulefile), "/TP"}
        import("private.action.build.object").build(target, singlebatch, opt)
        table.insert(modulefiles, modulefile)
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, dependfile)
    end

    -- add module files
    for _, modulefile in ipairs(modulefiles) do
        target:add("cxxflags", "/experimental:module /module:reference " .. os.args(modulefile))
    end
end

-- build module files
function main(target, sourcebatch, opt)

    -- do compile
    local compinst = compiler.load("cxx")
    if compinst:name() == "clang" and compinst:has_flags("-fmodules-ts") then
        _build_modulefiles_clang(target, sourcebatch, opt)
    elseif compinst:name() == "gcc" and compinst:has_flags("-fmodules-ts") then
        _build_modulefiles_gcc(target, sourcebatch, opt)
    elseif compinst:name() == "cl" and compinst:has_flags("/experimental:module") then
        _build_modulefiles_msvc(target, sourcebatch, opt)
    else
        raise("compiler(%s): does not support c++ module!", compinst:name())
    end
end

