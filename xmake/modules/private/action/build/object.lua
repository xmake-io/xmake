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
import("private.cache.build_cache")
import("async.runjobs")
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
    local dependinfo = target:is_rebuilt() and {} or (depend.load(dependfile, {target = target}) or {})

    -- dry run?
    local dryrun = option.get("dry-run")

    -- need build this object?
    --
    -- we need use `os.mtime(dependfile)` to determine the mtime of the dependfile to avoid objectfile corruption due to compilation interruptions
    -- @see https://github.com/xmake-io/xmake/issues/748
    --
    -- we also need avoid the problem of not being able to recompile after the objectfile has been deleted
    -- @see https://github.com/xmake-io/xmake/issues/2551#issuecomment-1183922208
    --
    -- optimization:
    -- we enable time cache to speed up is_changed, because there are a lot of header files in depfiles.
    -- but we cannot cache it in link stage, maybe some objectfiles will be updated.
    -- @see https://github.com/xmake-io/xmake/issues/6089
    local depvalues = {compinst:program(), compflags}
    local lastmtime = os.isfile(objectfile) and os.mtime(dependfile) or 0
    if not dryrun and not depend.is_changed(dependinfo, {lastmtime = lastmtime, values = depvalues, timecache = true}) then
        return
    end

    -- is verbose?
    local verbose = option.get("verbose")

    -- exists ccache or distcc?
    -- we just show cache/distc to avoid confusion with third-party ccache/distcc
    local prefix = ""
    if build_cache.is_enabled(target) and build_cache.is_supported(sourcekind) then
        prefix = "cache "
    end
    if distcc_build_client.is_distccjob() and distcc_build_client.singleton():has_freejobs() then
        prefix = prefix .. "distc "
    end

    -- trace progress info
    if not opt.quiet then
        local filepath = sourcefile
        if target:namespace() then
            filepath = target:namespace() .. "::" .. filepath
        end
        progress.show(opt.progress, "${color.build.object}%scompiling.$(mode) %s", prefix, filepath)
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

        -- update files and values to the depfiles
        dependinfo.values = depvalues
        table.insert(dependinfo.files, sourcefile)

        -- add precompiled header to the depfiles when building sourcefile
        local build_pch
        local pcxxoutputfile = target:pcoutputfile("cxx")
        local pcoutputfile = target:pcoutputfile("c")
        if pcxxoutputfile or pcoutputfile then
            -- https://github.com/xmake-io/xmake/issues/3988
            local extension = path.extension(sourcefile)
            if (extension:startswith(".h") or extension == ".inl") then
                build_pch = true
            end
        end
        if target:has_sourcekind("cxx") and pcxxoutputfile and not build_pch then
            table.insert(dependinfo.files, pcxxoutputfile)
        end
        if target:has_sourcekind("cc") and pcoutputfile and not build_pch then
            table.insert(dependinfo.files, pcoutputfile)
        end
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
        batchjobs:addjob(sourcefile, function (index, total, jobopt)
            local build_opt = table.join({objectfile = objectfile, dependfile = dependfile, sourcekind = sourcekind, progress = jobopt.progress}, opt)
            build_object(target, sourcefile, build_opt)
        end, {rootjob = rootjob, distcc = opt.distcc})
    end
end
