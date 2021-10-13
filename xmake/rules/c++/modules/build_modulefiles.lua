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
-- @file        build_modulefiles.lua
--

-- imports
import("core.tool.compiler")

-- build module files using clang
function _build_modulefiles_clang(target, sourcebatch, opt)

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
        local objectfile = target:objectfile(sourcefile) .. ".pcm"
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, target:dependfile(objectfile))
    end

    -- compile module files to *.pcm
    opt = table.join(opt, {configs = {force = {cxxflags = {modulesflag,
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
    opt.configs = {cxxflags = {modulesflag, "-fmodules-cache-path=" .. cachedir}}
    opt.quiet   = true
    import("private.action.build.object").build(target, sourcebatch, opt)

    -- add module files
    target:add("cxxflags", opt.modulesflag, "-fmodules-cache-path=" .. cachedir)
    for _, modulefile in ipairs(modulefiles) do
        target:add("cxxflags", "-fmodule-file=" .. modulefile)
    end
end

-- build module files using gcc
function _build_modulefiles_gcc(target, sourcebatch, opt)

    -- get modules flag
    local modulesflag
    local compinst = compiler.load("cxx", {target = target})
    if compinst:has_flags("-fmodules-ts") then
        modulesflag = "-fmodules-ts"
    end
    assert(modulesflag, "compiler(gcc): does not support c++ module!")

    -- attempt to compile the module files as cxx
    sourcebatch.sourcekind = "cxx"
    sourcebatch.objectfiles = sourcebatch.objectfiles or {}
    sourcebatch.dependfiles = sourcebatch.dependfiles or {}
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local objectfile = target:objectfile(sourcefile)
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, target:dependfile(objectfile))
    end

    -- compile module files to object files
    opt = table.join(opt, {configs = {force = {cxxflags = {modulesflag, "-x c++"}}}})
    import("private.action.build.object").build(target, sourcebatch, opt)

    -- add module files
    target:add("cxxflags", modulesflag)
end

-- build module files using msvc
function _build_modulefiles_msvc(target, sourcebatch, opt)

    -- get modules flag
    local modulesflag
    local compinst = compiler.load("cxx", {target = target})
    if compinst:has_flags("/experimental:module") then
        modulesflag = "/experimental:module"
    end
    assert(modulesflag, "compiler(msvc): does not support c++ module!")

    -- get output flag
    local outputflag
    if compinst:has_flags("/ifcOutput")  then
        outputflag = "/ifcOutput"
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
        local modulefile = objectfile .. ".ifc"

        -- compile module file to *.pcm
        local singlebatch = {sourcekind = "cxx", sourcefiles = {sourcefile}, objectfiles = {objectfile}, dependfiles = {dependfile}}
        opt.configs.cxxflags = {modulesflag, interfaceflag, outputflag .. " " .. os.args(modulefile), "/TP"}
        import("private.action.build.object").build(target, singlebatch, opt)
        table.insert(modulefiles, modulefile)
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, dependfile)
    end

    -- add module files
    for _, modulefile in ipairs(modulefiles) do
        target:add("cxxflags", modulesflag, referenceflag .. " " .. os.args(modulefile))
    end
end

-- build module files
function main(target, sourcebatch, opt)
    local _, toolname = target:tool("cxx")
    if toolname:find("clang", 1, true) then
        _build_modulefiles_clang(target, sourcebatch, opt)
    elseif toolname:find("gcc", 1, true) then
        _build_modulefiles_gcc(target, sourcebatch, opt)
    elseif toolname == "cl" then
        _build_modulefiles_msvc(target, sourcebatch, opt)
    else
        raise("compiler(%s): does not support c++ module!", toolname)
    end
end
