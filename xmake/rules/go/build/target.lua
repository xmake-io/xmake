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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        target.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.tool.compiler")
import("core.project.depend")
import("utils.progress")

-- build the source files
function build_sourcefiles(target, sourcebatch, opt)

    -- get the target file
    local targetfile = target:targetfile()

    -- get source files and kind
    local sourcefiles = sourcebatch.sourcefiles
    local sourcekind  = sourcebatch.sourcekind

    -- get depend file
    local dependfile = target:dependfile(targetfile)

    -- load compiler
    local compinst = compiler.load(sourcekind, {target = target})

    -- get compile flags
    local compflags = compinst:compflags({target = target})

    -- load dependent info
    local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})

    -- need build this target?
    local depvalues = {compinst:program(), compflags}
    if not depend.is_changed(dependinfo, {lastmtime = os.mtime(targetfile), values = depvalues}) then
        return
    end

    -- trace progress info
    progress.show(opt.progress, "${color.build.target}linking.$(mode) %s", path.filename(targetfile))

    -- flush io buffer to update progress info
    io.flush()

    -- build it (compile and link in one step for Go)
    -- Go builds packages, so we need to change to the source directory
    local projectdir = os.projectdir()
    local srcdir = path.absolute(path.directory(sourcefiles[1]), projectdir)

    -- convert targetfile to absolute path before changing directory
    -- targetfile is relative to project directory, so use projectdir as base
    local abs_targetfile = path.is_absolute(targetfile) and targetfile or path.absolute(targetfile, projectdir)

    -- ensure output directory exists before changing directory
    os.mkdir(path.directory(abs_targetfile))

    -- convert source files to relative paths from source directory
    local rel_sourcefiles = {}
    for _, sourcefile in ipairs(sourcefiles) do
        local abs_sourcefile = path.is_absolute(sourcefile) and sourcefile or path.absolute(sourcefile, projectdir)
        local rel_sourcefile = path.relative(abs_sourcefile, srcdir)
        table.insert(rel_sourcefiles, rel_sourcefile)
    end

    -- trace verbose info
    vprint(os.args(table.join("cd", srcdir)))
    vprint(compinst:buildcmd(rel_sourcefiles, abs_targetfile, {target = target, compflags = compflags}))
    vprint(os.args(table.join("cd", original_dir)))

    local original_dir = os.cd(srcdir)

    dependinfo.files = {}
    local ok, errmsg = compinst:build(rel_sourcefiles, abs_targetfile, {target = target, dependinfo = dependinfo, compflags = compflags})

    -- restore the original working directory before asserting,
    -- ensuring a consistent state for other tasks in the same process
    -- even the build fails
    os.cd(original_dir)

    assert(ok, errmsg)

    -- update files and values to the dependent file
    dependinfo.values = depvalues
    table.join2(dependinfo.files, sourcefiles)
    depend.save(dependinfo, dependfile)
end

-- build target
function main(target, opt)

    -- @note only support one source kind!
    local sourcebatches = target:sourcebatches()
    if sourcebatches then
        local sourcebatch = sourcebatches["go.build"]
        if sourcebatch then
            build_sourcefiles(target, sourcebatch, opt)
        end
    end
end
