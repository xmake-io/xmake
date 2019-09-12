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
import("core.project.depend")
import("private.tools.ccache")

-- do build file
function _do_build_file(target, sourcefile, opt)

    -- get build info
    local objectfile = opt.objectfile
    local dependfile = opt.dependfile
    local sourcekind = opt.sourcekind
    local progress   = opt.progress

    -- load compiler 
    local compinst = compiler.load(sourcekind, {target = target})

    -- get compile flags
    local compflags = compinst:compflags({target = target, sourcefile = sourcefile, configs = opt.configs})

    -- load dependent info 
    local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
    
    -- need build this object?
    local depvalues = {compinst:program(), compflags}
    if not depend.is_changed(dependinfo, {lastmtime = os.mtime(objectfile), values = depvalues}) then
        return 
    end

    -- is verbose?
    local verbose = option.get("verbose")

    -- exists ccache?
    local exists_ccache = ccache.exists()

    -- trace progress info
    if not opt.quiet then
        cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", progress)
        if verbose then
            cprint("${dim color.build.object}%scompiling.$(mode) %s", exists_ccache and "ccache " or "", sourcefile)
        else
            cprint("${color.build.object}%scompiling.$(mode) %s", exists_ccache and "ccache " or "", sourcefile)
        end
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
function _build_object(target, sourcebatch, index, opt)

    -- get the object and source with the given index
    local sourcefile = sourcebatch.sourcefiles[index]
    local objectfile = sourcebatch.objectfiles[index]
    local dependfile = sourcebatch.dependfiles[index]
    local sourcekind = assert(sourcebatch.sourcekind, "%s: sourcekind not found!", sourcefile)

    -- get progress range
    local progress = assert(opt.progress, "no progress!")

    -- calculate progress
    local progress_now = progress.start + ((index - 1) * (progress.stop - progress.start)) / #sourcebatch.sourcefiles

    -- init build option
    local opt = table.join(opt, {objectfile = objectfile, dependfile = dependfile, sourcekind = sourcekind, progress = progress_now})

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

-- build the source files
function main(target, sourcebatch, opt)

    -- get the max job count
    local jobs = tonumber(option.get("jobs") or "4")

    -- run build jobs for each source file 
    local curdir = os.curdir()
    process.runjobs(function (index)

        -- force to set the current directory first because the other jobs maybe changed it
        os.cd(curdir)

        -- build object
        _build_object(target, sourcebatch, index, opt)

    end, #sourcebatch.sourcefiles, jobs)
end
