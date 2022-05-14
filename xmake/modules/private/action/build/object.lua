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
-- @file        object.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.tool.compiler")
import("core.project.depend")
import("private.tools.ccache")
import("private.async.runjobs")
import("utils.progress")
import("private.service.distcc_build.client", {alias = "distcc_build_client"})

-- do build file
function _do_build_file(target, sourcefile, opt)

    -- get build info
    local objectfile = opt.objectfile
    local dependfile = opt.dependfile
    local sourcekind = opt.sourcekind

    -- load compiler
    local compinst = compiler.load(sourcekind, {target = target})

    -- get compile flags
    local compflags = compinst:compflags({target = target, sourcefile = sourcefile, configs = opt.configs})

    -- load dependent info
    local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})

    -- dry run?
    local dryrun = option.get("dry-run")

    -- need build this object?
    -- @note we use mtime(dependfile) instead of mtime(objectfile) to ensure the object file is is fully compiled.
    -- @see https://github.com/xmake-io/xmake/issues/748
    local depvalues = {compinst:program(), compflags}
    if not dryrun and not depend.is_changed(dependinfo, {lastmtime = os.mtime(dependfile), values = depvalues}) then
        return
    end

    -- is verbose?
    local verbose = option.get("verbose")

    -- exists ccache or distcc?
    local prefix = ""
    if distcc_build_client.is_distccjob() and distcc_build_client.singleton():has_freejobs() then
        prefix = "distcc "
    elseif ccache.exists() then
        prefix = "ccache "
    end

    -- trace progress info
    if not opt.quiet then
        progress.show(opt.progress, "${color.build.object}%scompiling.$(mode) %s", prefix, sourcefile)
    end

    -- trace verbose info
    if verbose then
        -- show the full link command with raw arguments, it will expand @xxx.args for msvc/link on windows
        print(compinst:compcmd(sourcefile, objectfile, {compflags = compflags, rawargs = true}))
    end
    if not dryrun then

        -- do compile
        dependinfo.files = {}
        assert(compinst:compile(sourcefile, objectfile, {dependinfo = dependinfo, compflags = compflags}))

        -- update files and values to the dependent file
        dependinfo.values = depvalues
        table.join2(dependinfo.files, sourcefile, target:pcoutputfile("cxx") or {}, target:pcoutputfile("c"))
        depend.save(dependinfo, dependfile)
    end
end

-- build object
function build_object(target, sourcefile, opt)
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
        build_object(target, sourcefile, opt)
    end
end

-- add batch jobs to build the source files
function main(target, batchjobs, sourcebatch, opt)
    local rootjob = opt.rootjob
    for i = 1, #sourcebatch.sourcefiles do
        local sourcefile = sourcebatch.sourcefiles[i]
        local objectfile = sourcebatch.objectfiles[i]
        local dependfile = sourcebatch.dependfiles[i]
        local sourcekind = assert(sourcebatch.sourcekind, "%s: sourcekind not found!", sourcefile)
        batchjobs:addjob(sourcefile, function (index, total)
            local build_opt = table.join({objectfile = objectfile, dependfile = dependfile, sourcekind = sourcekind, progress = (index * 100) / total}, opt)
            build_object(target, sourcefile, build_opt)
        end, {rootjob = rootjob, distcc = opt.distcc})
    end
end
