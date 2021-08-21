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
-- @author      ruki, TheVeryDarkness
-- @file        build_modulefiles.lua
--

-- imports
local flag    = import("get_module_flags")
local json    = import("core.base.json")
local builder = import("private.action.build.object")
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
    opt = table.join(opt, {configs = {force = {cxxflags = {opt.modulesflag, "--precompile", "-x c++-module"}}}})
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
    opt.configs = {cxxflags = {opt.modulesflag}}
    opt.quiet   = true
    import("private.action.build.object").build(target, sourcebatch, opt)

    -- add module files
    target:add("cxxflags", opt.modulesflag)
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
        opt.configs.cxxflags = {"-fmodules", "-fmodule-output=" .. modulefile, "-x c++"}
        import("private.action.build.object").build(target, singlebatch, opt)
        table.insert(modulefiles, modulefile)
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, dependfile)
    end

    -- add module files
    for _, modulefile in ipairs(modulefiles) do
        target:add("cxxflags", "-fmodules", "-fmodule-file=" .. modulefile)
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

    -- Map module name to its path.
    -- It's a map or a dict.
    local moduleMap = {}
    local uncompiled_modules = {}
    local moduleDependenciesMap = {}

    function compile_module(sourcefile)
        local objectfile = target:objectfile(sourcefile)
        local dependfile = target:dependfile(objectfile)
        local modulefile = objectfile .. ".ifc"

        -- compile module file to *.ifc
        local singlebatch = {sourcekind = "cxx", sourcefiles = {sourcefile}, objectfiles = {objectfile}, dependfiles = {dependfile}}
        local dependTable = moduleDependenciesMap[sourcefile]
        local this_module_name = dependTable["Data"]["ProvidedModule"]

        -- Failed for unknown reason
        --[[
        print(this_module_name)
        local interface_or_partition = not string.find(this_module_name, ":", 1, true)
        ]]
        local interface_or_partition = true
        local filetype
        if interface_or_partition then
            filetype = opt.interfaceflag
        else
            filetype = opt.partitionflag
        end

        local out_dir = modulefile:gsub("[^\\\\/]*$", "")

        opt.configs.cxxflags = {opt.modulesflag, filetype, "/sourceDependencies " .. out_dir, opt.outputflag .. " " .. os.args(modulefile), "/TP"}

        for _, moduleName in ipairs(dependTable["Data"]["ImportedModules"]) do
            if not moduleName or not moduleMap[moduleName] then
                os.raise("\"" .. moduleName .. "\" is not listed in modules. Why? Listed modules are " .. json.encode(moduleMap))
            end
            table.insert(opt.configs.cxxflags, "/reference " .. moduleName .. "=" .. moduleMap[moduleName])
        end

        if sourcefile:endswith(".mxx") or sourcefile:endswith(".mpp") or sourcefile:endswith(".ixx") or sourcefile:endswith(".cppm") then
            builder.build(target, singlebatch, opt)
        end
    end

    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local objectfile = target:objectfile(sourcefile)
        local modulefile = objectfile .. ".ifc"
        local descFile = modulefile .. ".d.json"

        local dependTable = json.loadfile(descFile)
        moduleDependenciesMap[sourcefile] = dependTable

        local name = dependTable["Data"]["ProvidedModule"]
        moduleMap[name] = modulefile
        table.insert(uncompiled_modules, sourcefile)
    end

    while #uncompiled_modules > 0 do
        local compiled_one_in_this_loop = false

        for _, to_be_compiled in ipairs(uncompiled_modules) do

            local dependTable = moduleDependenciesMap[to_be_compiled]
            local compilable = true
            if not dependTable then
                os.raise(to_be_compiled .. " is not in list. Why?")
            end
            for _, to_be_imported in ipairs(dependTable["Data"]["ImportedModules"]) do
                for _, uncompiled in ipairs(uncompiled_modules)do
                    if to_be_imported == uncompiled then
                        compilable = false
                        break
                    end
                end
                if not compilable then
                    break
                end
            end
            if compilable then
                compile_module(to_be_compiled)
                compiled_one_in_this_loop = true
                table.remove(uncompiled_modules, _)
            end
        end
        if not compiled_one_in_this_loop then
            os.raise("Ring import detected among ", uncompiled_modules)
        end
    end
    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
        local objectfile = target:objectfile(sourcefile)
        local dependfile = target:dependfile(objectfile)
        local modulefile = objectfile .. ".ifc"
        local dependTable = moduleDependenciesMap[sourcefile]
        local modulename = dependTable["Data"]["ProvidedModule"]

        table.insert(modulefiles, modulename .. "=" .. modulefile)
        table.insert(sourcebatch.objectfiles, objectfile)
        table.insert(sourcebatch.dependfiles, dependfile)
    end

    -- add module files
    for _, modulefile in ipairs(modulefiles) do
        target:add("cxxflags", opt.modulesflag)
        target:add("cxxflags", "/reference " .. os.args(modulefile))
    end
end

-- build module files
function main(target, sourcebatch, opt)
    -- do compile
    local _, toolname = target:tool("cxx")
    local compinst = compiler.load("cxx")
    flag.get_module_flags(compinst, toolname, opt)

    if toolname:find("clang", 1, true) then
        _build_modulefiles_clang(target, sourcebatch, opt)
    elseif toolname:find("gcc", 1, true) then
        _build_modulefiles_gcc(target, sourcebatch, opt)
    elseif toolname == "cl" then
        _build_modulefiles_msvc(target, sourcebatch, opt)
    else
        raise("compiler(%s): does not support c++ module!", toolname)
    end
    if opt.origin then
        -- opt.origin(target, sourcebatch, opt)
    end
end
