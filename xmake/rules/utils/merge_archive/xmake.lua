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
-- @file        xmake.lua
--

rule("utils.merge.archive")
    set_extensions(".a", ".lib")
    on_build_files(function (target, sourcebatch, opt)
        if sourcebatch.sourcefiles then
            target:data_set("merge_archive.sourcefiles", sourcebatch.sourcefiles)
        end
    end)
    after_link(function (target, opt)
        if not target:is_static() then
            return
        end
        local sourcefiles = target:data("merge_archive.sourcefiles")
        if target:policy("build.merge_archive") or sourcefiles then
            import("utils.archive.merge_staticlib")
            import("core.project.depend")
            import("utils.progress")
            local libraryfiles = {}
            if sourcefiles then
                table.join2(libraryfiles, sourcefiles)
            else
                for _, dep in ipairs(target:orderdeps()) do
                    if dep:is_static() then
                        table.insert(libraryfiles, dep:targetfile())
                    end
                end
            end
            if #libraryfiles > 0 then
                table.insert(libraryfiles, target:targetfile())
            end
            depend.on_changed(function ()
                progress.show(opt.progress, "${color.build.target}merging.$(mode) %s", path.filename(target:targetfile()))
                if #libraryfiles > 0 then
                    local tmpfile = os.tmpfile() .. path.extension(target:targetfile())
                    merge_staticlib(target, tmpfile, libraryfiles)
                    os.cp(tmpfile, target:targetfile())
                    os.rm(tmpfile)
                end
            end, {dependfile = target:dependfile(target:targetfile() .. ".merge_archive"), files = libraryfiles})
        end
    end)

