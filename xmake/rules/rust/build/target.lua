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

    -- need build this object?
    local depvalues = {compinst:program(), compflags}
    if not depend.is_changed(dependinfo, {lastmtime = os.mtime(targetfile), values = depvalues}) then
        return
    end

    -- trace progress into
    progress.show(opt.progress, "${color.build.target}linking.$(mode) %s", path.filename(targetfile))

    -- trace verbose info
    vprint(compinst:buildcmd(sourcefiles, targetfile, {target = target, compflags = compflags}))

    -- flush io buffer to update progress info
    io.flush()

    -- compile it
    dependinfo.files = {}
    assert(compinst:build(sourcefiles, targetfile, {target = target, dependinfo = dependinfo, compflags = compflags}))

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
        local sourcebatch = sourcebatches["rust.build"]
        if sourcebatch then
            build_sourcefiles(target, sourcebatch, opt)
        end
    end
end
