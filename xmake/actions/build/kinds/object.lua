--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        object.lua
--

-- imports
import("core.base.option")
import("core.tool.compiler")
import("core.tool.extractor")
import("core.project.rule")
import("core.project.config")
import("core.project.project")
import("core.language.language")
import("detect.tools.find_ccache")

-- is modified?
function _is_modified(target, sourcefile, objectfile, depinfo, buildinfo, program, compflags)

    -- rebuild?
    if buildinfo.rebuild then
        return true
    end

    -- get the dependent files
    local depfiles = table.join(depinfo.sources or {}, depinfo.includes or {})

    -- check the dependent files are modified?
    local modified      = false
    local objectmtime   = nil
    _g.depfile_results  = _g.depfile_results or {}
    for _, depfile in ipairs(depfiles) do

        -- optimization: this depfile has been not checked?
        local status = _g.depfile_results[depfile]
        if status == nil then

            -- optimization: only uses the mtime of first object file
            objectmtime = objectmtime or os.mtime(objectfile)

            -- source and header files have been modified?
            if os.mtime(depfile) > objectmtime then

                -- mark this depfile as modified
                _g.depfile_results[depfile] = true
                return true
            end

            -- mark this depfile as not modified
            _g.depfile_results[depfile] = false
        
        -- has been checked and modified?
        elseif status then
            return true
        end
    end

    -- the program has been modified?
    if program ~= depinfo.program then
        return true
    end

    -- the flags has been modified?
    return os.args(compflags) ~= os.args(depinfo.flags)
end

-- build the object from the *.[o|obj] source file
function _build_from_object(target, sourcefile, objectfile, percent)

    -- is verbose?
    local verbose = option.get("verbose")

    -- trace percent info
    if verbose then
        cprint("${green}[%02d%%]: ${dim magenta}inserting.$(mode) %s", percent, sourcefile)
    else
        cprint("${green}[%02d%%]: ${magenta}inserting.$(mode) %s", percent, sourcefile)
    end

    -- trace verbose info
    if verbose then
        print("cp %s %s", sourcefile, objectfile)
    end

    -- flush io buffer to update progress info
    io.flush()

    -- insert this object file
    os.cp(sourcefile, objectfile)
end

-- build the object from the *.[a|lib] source file
function _build_from_static(target, sourcefile, objectfile, percent)

    -- is verbose?
    local verbose = option.get("verbose")

    -- trace percent info
    if verbose then
        cprint("${green}[%02d%%]: ${dim magenta}inserting.$(mode) %s", percent, sourcefile)
    else
        cprint("${green}[%02d%%]: ${magenta}inserting.$(mode) %s", percent, sourcefile)
    end

    -- trace verbose info
    if verbose then
        print("ex %s %s", sourcefile, objectfile)
    end

    -- flush io buffer to update progress info
    io.flush()

    -- extract the static library to object directory
    extractor.extract(sourcefile, path.directory(objectfile))
end

-- build object
function _build_object(target, buildinfo, index, sourcebatch, ccache)

    -- get the object and source with the given index
    local sourcefile = sourcebatch.sourcefiles[index]
    local objectfile = sourcebatch.objectfiles[index]
    local dependfile = sourcebatch.dependfiles[index]
    local sourcekind = sourcebatch.sourcekind

    -- calculate percent
    local percent = ((buildinfo.targetindex + (_g.sourceindex + index - 1) / _g.sourcecount) * 100 / buildinfo.targetcount)

    -- build the object for the *.o/obj source makefile
    if sourcekind == "obj" then 
        return _build_from_object(target, sourcefile, objectfile, percent)
    -- build the object for the *.[a|lib] source file
    elseif sourcekind == "lib" then 
        return _build_from_static(target, sourcefile, objectfile, percent)
    end

    -- get dependent info 
    local depinfo = {}
    if not buildinfo.rebuild and os.isfile(dependfile) then
        depinfo = io.load(dependfile) or {}
    end
    
    -- load compiler instance
    local compiler_instance = compiler.load(sourcekind, {target = target})

    -- get compiler program
    local program = compiler_instance:program()

    -- get compile flags
    local compflags = compiler_instance:compflags({target = target, sourcefile = sourcefile})

    -- is modified?
    local modified = _is_modified(target, sourcefile, objectfile, depinfo, buildinfo, program, compflags)
    if not modified then
        return 
    end

    -- mark this target as modified
    buildinfo.modified[target:name()] = true

    -- is verbose?
    local verbose = option.get("verbose")

    -- trace percent info
    if verbose then
        cprint("${green}[%02d%%]:${dim} %scompiling.$(mode) %s", percent, ifelse(ccache, "ccache ", ""), sourcefile)
    else
        cprint("${green}[%02d%%]:${clear} %scompiling.$(mode) %s", percent, ifelse(ccache, "ccache ", ""), sourcefile)
    end

    -- trace verbose info
    if verbose then
        print(compiler_instance:compcmd(sourcefile, objectfile, {compflags = compflags}))
    end

    -- flush io buffer to update progress info
    io.flush()

    -- complie it 
    assert(compiler_instance:compile(sourcefile, objectfile, {depinfo = depinfo, compflags = compflags}))

    -- save sources to the dependent info
    depinfo.sources = table.join(sourcefile, target:pcheaderfile("cxx") or {}, target:pcheaderfile("c"))

    -- save program to the dependent info
    depinfo.program = program

    -- save flags to the dependent info
    depinfo.flags = compflags

    -- save the dependent info
    io.save(dependfile, depinfo)
end

-- build each objects from the given source batch
function _build_each_objects(target, buildinfo, sourcekind, sourcebatch, jobs, ccache)

    -- run build jobs for each source file 
    local curdir = os.curdir()
    process.runjobs(function (index)

        -- force to set the current directory first because the other jobs maybe changed it
        os.cd(curdir)

        -- build object
        _build_object(target, buildinfo, index, sourcebatch, ccache)

    end, #sourcebatch.sourcefiles, jobs)

    -- update object index
    _g.sourceindex = _g.sourceindex + #sourcebatch.sourcefiles
end

-- compile source files to single object at the same time
function _build_single_object(target, buildinfo, sourcekind, sourcebatch, jobs, ccache)

    -- is verbose?
    local verbose = option.get("verbose")

    -- get source and object files
    local sourcefiles = sourcebatch.sourcefiles
    local objectfiles = sourcebatch.objectfiles
    local dependfiles = sourcebatch.dependfiles

    -- trace percent info
    for index, sourcefile in ipairs(sourcefiles) do

        -- calculate percent
        local percent = ((buildinfo.targetindex + (_g.sourceindex + index - 1) / _g.sourcecount) * 100 / buildinfo.targetcount)

        -- trace percent info
        if verbose then
            cprint("${green}[%02d%%]:${clear} ${dim}%scompiling.$(mode) %s", percent, ifelse(ccache, "ccache ", ""), sourcefile)
        else
            cprint("${green}[%02d%%]:${clear} %scompiling.$(mode) %s", percent, ifelse(ccache, "ccache ", ""), sourcefile)
        end
    end

    -- trace verbose info
    if verbose then
        print(compiler.compcmd(sourcefiles, objectfiles, {target = target, sourcekind = sourcekind}))
    end

    -- mark this target as modified
    buildinfo.modified[target:name()] = true

    -- complie them
    compiler.compile(sourcefiles, objectfiles, {dependfiles = dependfiles, target = target, sourcekind = sourcekind})

    -- update object index
    _g.sourceindex = _g.sourceindex + #sourcebatch.sourcefiles
end

-- build precompiled header files (only for c/c++)
function _build_pcheaderfiles(target, buildinfo)

    -- for c/c++
    for _, langkind in ipairs({"c", "cxx"}) do

        -- get the precompiled header
        local pcheaderfile = target:pcheaderfile(langkind)
        if pcheaderfile then

            -- init sourcefile, objectfile and dependfile
            local sourcefile = pcheaderfile
            local objectfile = target:pcoutputfile(langkind)
            local dependfile = objectfile .. ".d"
            local sourcekind = language.langkinds()[langkind]

            -- init source batch
            local sourcebatch = {sourcekind = sourcekind, sourcefiles = {sourcefile}, objectfiles = {objectfile}, dependfiles = {dependfile}}

            -- build this precompiled header
            _build_object(target, buildinfo, 1, sourcebatch, false)
        end
    end
end

-- build source files with the custom rule
function _build_files_with_rule(target, buildinfo, sourcebatch, jobs, suffix)

    -- the rule name
    local rulename = sourcebatch.rulename

    -- get rule instance
    local ruleinst = project.rule(rulename) or rule.rule(rulename)
    assert(ruleinst, "unknown rule: %s", rulename)

    -- on_build_files?
    local on_build_files = ruleinst:script("build_files" .. (suffix and ("_" .. suffix) or ""))
    if on_build_files then
        on_build_files(target, sourcebatch.sourcefiles)
    else
        -- get the build file script
        local on_build_file = ruleinst:script("build_file" .. (suffix and ("_" .. suffix) or ""))
        if on_build_file then

            -- run build jobs for each source file 
            local curdir = os.curdir()
            process.runjobs(function (index)

                -- force to set the current directory first because the other jobs maybe changed it
                os.cd(curdir)

                -- calculate percent
                local percent = ((buildinfo.targetindex + (_g.sourceindex + index - 1) / _g.sourcecount) * 100 / buildinfo.targetcount)
                if suffix then
                    percent = ((buildinfo.targetindex + (suffix == "before" and _g.sourceindex or _g.sourcecount) / _g.sourcecount) * 100 / buildinfo.targetcount)
                end

                -- the source file
                local sourcefile = sourcebatch.sourcefiles[index]

                -- trace percent info
                if option.get("verbose") then
                    cprint("${green}[%02d%%]:${dim} compiling.%s %s", percent, rulename, sourcefile)
                else
                    cprint("${green}[%02d%%]:${clear} compiling.%s %s", percent, rulename, sourcefile)
                end

                -- do build file
                on_build_file(target, sourcefile)

            end, #sourcebatch.sourcefiles, jobs)
        end
    end

    -- update object index
    if not suffix then
        _g.sourceindex = _g.sourceindex + #sourcebatch.sourcefiles
    end
end

-- build objects for the given target
function build(target, buildinfo)

    -- init source index and count
    _g.sourceindex = 0
    _g.sourcecount = target:sourcecount()

    -- get the max job count
    local jobs = tonumber(option.get("jobs") or "4")

    -- get ccache
    local ccache = nil
    if config.get("ccache") then
        ccache = find_ccache()
    end

    -- build precompiled headers
    _build_pcheaderfiles(target, buildinfo)

    -- build source batches with custom rules before building other sources
    for sourcekind, sourcebatch in pairs(target:sourcebatches()) do
        if sourcebatch.rulename then
            _build_files_with_rule(target, buildinfo, sourcebatch, jobs, "before")
        end
    end

    -- build source batches
    for sourcekind, sourcebatch in pairs(target:sourcebatches()) do

        -- compile source files with custom rule
        if sourcebatch.rulename then
            _build_files_with_rule(target, buildinfo, sourcebatch, jobs)
        -- compile source files to single object at once
        elseif type(sourcebatch.objectfiles) == "string" then
            _build_single_object(target, buildinfo, sourcekind, sourcebatch, jobs, ccache)
        else
            _build_each_objects(target, buildinfo, sourcekind, sourcebatch, jobs, ccache)
        end
    end

    -- build source batches with custom rules after building other sources
    for sourcekind, sourcebatch in pairs(target:sourcebatches()) do
        if sourcebatch.rulename then
            _build_files_with_rule(target, buildinfo, sourcebatch, jobs, "after")
        end
    end
end

