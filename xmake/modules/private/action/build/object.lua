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
-- @file        object.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.tool.compiler")
import("core.project.depend")
import("private.tools.ccache")
import("private.async.runjobs")

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
        local progress_prefix = "${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} "
        if verbose then
            cprint(progress_prefix .. "${dim color.build.object}%scompiling.$(mode) %s", progress, exists_ccache and "ccache " or "", sourcefile)
        else
            cprint(progress_prefix .. "${color.build.object}%scompiling.$(mode) %s", progress, exists_ccache and "ccache " or "", sourcefile)
        end
    end

    -- trace verbose info
    if verbose then
        print(compinst:compcmd(sourcefile, objectfile, {compflags = compflags}))
    end

    -- compile it 
    dependinfo.files = {}
    if not option.get("dry-run") then
        assert(compinst:compile(sourcefile, objectfile, {dependinfo = dependinfo, compflags = compflags}))
    end

    -- update files and values to the dependent file
    dependinfo.values = depvalues
    table.join2(dependinfo.files, sourcefile, target:pcoutputfile("cxx") or {}, target:pcoutputfile("c"))
    depend.save(dependinfo, dependfile)
end

-- build object
function _build_object(target, sourcefile, opt)
    local script = target:script("build_file", _do_build_file)
    if script then
        script(target, sourcefile, opt)
    end
end

-- build the source files
function build(target, sourcebatch, opt)
    for i = 1, #sourcebatch.sourcefiles do
        local sourcefile = sourcebatch.sourcefiles[i]
        opt.objectfile   = sourcebatch.objectfiles[i]
        opt.dependfile   = sourcebatch.dependfiles[i]
        opt.sourcekind   = assert(sourcebatch.sourcekind, "%s: sourcekind not found!", sourcefile)
        _build_object(target, sourcefile, opt)
    end
end

-- add batch jobs to build the source files
function main(target, batchjobs, sourcebatch, opt)
    local rootjob = opt.rootjob
    for i = 1, #sourcebatch.sourcefiles do
        local sourcefile = sourcebatch.sourcefiles[i]
        opt.objectfile   = sourcebatch.objectfiles[i]
        opt.dependfile   = sourcebatch.dependfiles[i]
        opt.sourcekind   = assert(sourcebatch.sourcekind, "%s: sourcekind not found!", sourcefile)
        batchjobs:addjob(sourcefile, function (index, total)
            opt.progress = (index * 100) / total
            _build_object(target, sourcefile, opt)
        end, rootjob)
    end
end
