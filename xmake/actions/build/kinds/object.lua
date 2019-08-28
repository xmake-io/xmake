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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        object.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.tool.compiler")
import("core.tool.extractor")
import("core.project.rule")
import("core.project.config")
import("core.project.depend")
import("core.project.project")
import("core.language.language")

-- build the object from the *.[o|obj] source file
function _build_from_object(target, sourcefile, objectfile, progress)

    -- is verbose?
    local verbose = option.get("verbose")

    -- trace progress info
    cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", progress)
    if verbose then
        cprint("${dim color.build.object}inserting.$(mode) %s", sourcefile)
    else
        cprint("${clear}${color.build.object}inserting.$(mode) %s", sourcefile)
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
function _build_from_static(target, sourcefile, objectfile, progress)

    -- is verbose?
    local verbose = option.get("verbose")

    -- trace progress info
    cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", progress)
    if verbose then
        cprint("${dim color.build.object}inserting.$(mode) %s", sourcefile)
    else
        cprint("${color.build.object}inserting.$(mode) %s", sourcefile)
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

-- do build file
function _do_build_file(target, sourcefile, opt)

    -- get build info
    local buildinfo  = _g.buildinfo
    local objectfile = opt.objectfile
    local dependfile = opt.dependfile
    local sourcekind = opt.sourcekind
    local progress   = opt.progress

    -- build the object for the *.o/obj source makefile
    if sourcekind == "obj" then 
        return _build_from_object(target, sourcefile, objectfile, progress)
    -- build the object for the *.[a|lib] source file
    elseif sourcekind == "lib" then 
        return _build_from_static(target, sourcefile, objectfile, progress)
    end

    -- load compiler 
    local compinst = compiler.load(sourcekind, {target = target})

    -- get compile flags
    local compflags = compinst:compflags({target = target, sourcefile = sourcefile})

    -- load dependent info 
    local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
    
    -- need build this object?
    local depvalues = {compinst:program(), compflags}
    if not depend.is_changed(dependinfo, {lastmtime = os.mtime(objectfile), values = depvalues}) then
        return 
    end

    -- is verbose?
    local verbose = option.get("verbose")

    -- get build prefix
    local build_prefix = target:data("build.object.prefix")
    build_prefix = build_prefix and (build_prefix .. " ") or ""

    -- trace progress info
    cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", progress)
    if verbose then
        cprint("${dim color.build.object}%scompiling.$(mode) %s", build_prefix, sourcefile)
    else
        cprint("${color.build.object}%scompiling.$(mode) %s", build_prefix, sourcefile)
    end

    -- trace verbose info
    if verbose then
        print(compinst:compcmd(sourcefile, objectfile, {compflags = compflags}))
    end

    -- flush io buffer to update progress info
    io.flush()

    -- compile it 
    dependinfo.files = {}
    assert(compinst:compile(sourcefile, objectfile, {dependinfo = dependinfo, compflags = compflags}))

    -- update files and values to the dependent file
    dependinfo.values = depvalues
    table.join2(dependinfo.files, sourcefile, target:pcoutputfile("cxx") or {}, target:pcoutputfile("c"))
    depend.save(dependinfo, dependfile)
end

-- build object
function _build_object(target, index, sourcebatch)

    -- get the object and source with the given index
    local buildinfo = _g.buildinfo
    local sourcefile = sourcebatch.sourcefiles[index]
    local objectfile = sourcebatch.objectfiles[index]
    local dependfile = sourcebatch.dependfiles[index]
    local sourcekind = sourcebatch.sourcekind

    -- calculate progress
    local progress = ((buildinfo.targetindex + (buildinfo.sourceindex + index - 1) / buildinfo.sourcecount) * 100 / buildinfo.targetcount)

    -- init build option
    local opt = {objectfile = objectfile, dependfile = dependfile, sourcekind = sourcekind, progress = progress}

    -- do before build
    local before_build_file = target:script("build_file_before")
    if before_build_file then
        before_build_file(target, sourcefile, opt)
    end

    -- do build 
    local on_build_file = target:script("build_file")
    if on_build_file then
        opt.origin = _do_build_file
        on_build_file(target, sourcefile, opt)
        opt.origin = nil
    else
        _do_build_file(target, sourcefile, opt)
    end

    -- do after build
    local after_build_file = target:script("build_file_after")
    if after_build_file then
        after_build_file(target, sourcefile, opt)
    end
end

-- build each objects from the given source batch
function _build_files_for_each(target, sourcebatch, jobs)

    -- run build jobs for each source file 
    local curdir = os.curdir()
    process.runjobs(function (index)

        -- force to set the current directory first because the other jobs maybe changed it
        os.cd(curdir)

        -- build object
        _build_object(target, index, sourcebatch)

    end, #sourcebatch.sourcefiles, jobs)
end

-- compile source files to single object at the same time
function _build_files_for_single(target, sourcebatch, jobs)

    -- is verbose?
    local verbose = option.get("verbose")

    -- get source and object files
    local sourcefiles = sourcebatch.sourcefiles
    local objectfiles = sourcebatch.objectfiles
    local dependfiles = sourcebatch.dependfiles
    local sourcekind  = sourcebatch.sourcekind

    -- get build prefix
    local build_prefix = target:data("build.object.prefix")
    build_prefix = build_prefix and (build_prefix .. " ") or ""

    -- trace progress info
    local buildinfo = _g.buildinfo
    for index, sourcefile in ipairs(sourcefiles) do

        -- calculate progress
        local progress = ((buildinfo.targetindex + (buildinfo.sourceindex + index - 1) / buildinfo.sourcecount) * 100 / buildinfo.targetcount)

        -- trace progress info
        cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", progress)
        if verbose then
            cprint("${dim color.build.object}%scompiling.$(mode) %s", build_prefix, sourcefile)
        else
            cprint("${color.build.object}%scompiling.$(mode) %s", build_prefix, sourcefile)
        end
    end

    -- trace verbose info
    if verbose then
        print(compiler.compcmd(sourcefiles, objectfiles, {target = target, sourcekind = sourcekind}))
    end

    -- compile them
    compiler.compile(sourcefiles, objectfiles, {dependfiles = dependfiles, target = target, sourcekind = sourcekind})
end

-- build source files with the custom rule
function _build_files_for_rule(target, sourcebatch, jobs, suffix)

    -- the rule name
    local rulename = sourcebatch.rulename
    local buildinfo = _g.buildinfo

    -- get rule instance
    local ruleinst = project.rule(rulename) or rule.rule(rulename)
    assert(ruleinst, "unknown rule: %s", rulename)

    -- on_build_files?
    local on_build_files = ruleinst:script("build_files" .. (suffix and ("_" .. suffix) or ""))
    if on_build_files then

        -- calculate progress
        local progress = (buildinfo.targetindex + buildinfo.sourceindex / buildinfo.sourcecount) * 100 / buildinfo.targetcount

        -- do build files
        on_build_files(target, sourcebatch, {jobs = jobs, progress = progress})
    else
        -- get the build file script
        local on_build_file = ruleinst:script("build_file" .. (suffix and ("_" .. suffix) or ""))
        if on_build_file then

            -- run build jobs for each source file 
            local curdir = os.curdir()
            process.runjobs(function (index)

                -- force to set the current directory first because the other jobs maybe changed it
                os.cd(curdir)

                -- calculate progress
                local progress = ((buildinfo.targetindex + (buildinfo.sourceindex + index - 1) / buildinfo.sourcecount) * 100 / buildinfo.targetcount)
                if suffix then
                    progress = ((buildinfo.targetindex + (suffix == "before" and buildinfo.sourceindex or buildinfo.sourcecount) / buildinfo.sourcecount) * 100 / buildinfo.targetcount)
                end

                -- get source file
                local sourcefile = sourcebatch.sourcefiles[index]

                -- do build file
                on_build_file(target, sourcefile, {sourcekind = sourcebatch.sourcekind, progress = progress})

            end, #sourcebatch.sourcefiles, jobs)
        end
    end
end

-- do build files
function _do_build_files(target, sourcebatch, opt)

    -- compile source files with custom rule
    if sourcebatch.rulename then
        _build_files_for_rule(target, sourcebatch, opt.jobs)
    -- compile source files to single object at once
    elseif type(sourcebatch.objectfiles) == "string" then
        _build_files_for_single(target, sourcebatch, opt.jobs)
    else
        _build_files_for_each(target, sourcebatch, opt.jobs)
    end
end

-- build files
function _build_files(target, sourcebatch, jobs)

    -- calculate progress
    local buildinfo = _g.buildinfo
    local progress = (buildinfo.targetindex + buildinfo.sourceindex / buildinfo.sourcecount) * 100 / buildinfo.targetcount

    -- init build option
    local opt = {jobs = jobs, progress = progress}

    -- do before build
    local before_build_files = target:script("build_files_before")
    if before_build_files then
        before_build_files(target, sourcebatch, opt)
    end

    -- do build
    local on_build_files = target:script("build_files")
    if on_build_files then
        opt.origin = _do_build_files
        on_build_files(target, sourcebatch, opt)
        opt.origin = nil
    else
        _do_build_files(target, sourcebatch, opt)
    end

    -- update object index
    buildinfo.sourceindex = buildinfo.sourceindex + #sourcebatch.sourcefiles

    -- do after build
    local after_build_files = target:script("build_files_after")
    if after_build_files then
        after_build_files(target, sourcebatch, opt)
    end
end

-- build precompiled header files (only for c/c++)
function _build_pcheaderfiles(target, buildinfo)

    -- for c/c++
    _g.buildinfo = buildinfo
    for _, langkind in ipairs({"c", "cxx"}) do

        -- get the precompiled header
        local pcheaderfile = target:pcheaderfile(langkind)
        if pcheaderfile then

            -- init sourcefile, objectfile and dependfile
            local sourcefile = pcheaderfile
            local objectfile = target:pcoutputfile(langkind)
            local dependfile = target:dependfile(objectfile)
            local sourcekind = language.langkinds()[langkind]

            -- init source batch
            local sourcebatch = {sourcekind = sourcekind, sourcefiles = {sourcefile}, objectfiles = {objectfile}, dependfiles = {dependfile}}

            -- build this precompiled header
            _build_object(target, 1, sourcebatch, false)
        end
    end
end

-- build source files
function build_sourcefiles(target, buildinfo, sourcebatches)

    -- get the max job count
    local jobs = tonumber(option.get("jobs") or "4")

    -- save buildinfo
    _g.buildinfo = buildinfo

    -- build source batches with custom rules before building other sources
    for _, sourcebatch in pairs(sourcebatches) do
        if sourcebatch.rulename then
            _build_files_for_rule(target, sourcebatch, jobs, "before")
        end
    end

    -- build source batches
    for _, sourcebatch in pairs(sourcebatches) do
        _build_files(target, sourcebatch, jobs)
    end

    -- build source batches with custom rules after building other sources
    for _, sourcebatch in pairs(sourcebatches) do
        if sourcebatch.rulename then
            _build_files_for_rule(target, sourcebatch, jobs, "after")
        end
    end
end

-- build objects for the given target
function build(target, buildinfo)

    -- init source index and count
    buildinfo.sourceindex = 0
    buildinfo.sourcecount = target:sourcecount()

    -- build precompiled headers
    _build_pcheaderfiles(target, buildinfo)

    -- build source files
    build_sourcefiles(target, buildinfo, target:sourcebatches())
end

