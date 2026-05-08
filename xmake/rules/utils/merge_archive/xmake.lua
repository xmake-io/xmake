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
-- @file        xmake.lua
--

rule("utils.merge.archive")
    set_extensions(".a", ".lib")
    after_load(function (target)
        -- we need to disable inherit links if all static deps have been merged
        -- and we must disable it in after_load, because it will be called before rule(utils.inherit.links).on_config
        --
        -- @see https://github.com/xmake-io/xmake/issues/3404
        if target:policy("build.merge_archive") then
            target:data_set("inherit.links.export_static", false)

            for _, dep in ipairs(target:orderdeps()) do
                if dep:is_static() then
                    dep:data_set("inherit.links.deplink", false)
                end
            end
        else
            target:rule_enable("utils.merge.archive", false)
        end
    end)

    on_build_files(function (target, sourcebatch, opt)
        if sourcebatch.sourcefiles then
            target:data_set("merge_archive.sourcefiles", sourcebatch.sourcefiles)
        end
    end)

    after_link(function (target, opt)
        -- Returns full path of a given link archive, if found.
        local function _resolve_link(linkdirs, link)
            -- HELP: assume that 'linkpath' does not exists in multiple directories?
            for _, linkdir in ipairs(linkdirs) do
                local file_extension = target:is_plat("windows") and ".lib" or ".a"
                local link_path = path.join(linkdir, "lib" .. link .. file_extension)
                if os.exists(link_path) then
                    return link_path
                end
            end
        end

        if not target:is_static() then
            return
        end
        local sourcefiles = target:data("merge_archive.sourcefiles")
        if target:policy("build.merge_archive") or sourcefiles then
            import("private.utils.target", {alias = "target_utils"})
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

                -- TODO: what about syslinkdirs and syslinks?
                local linkdirs = target_utils.get_values_from_target(target, "linkdirs")
                for _, link in ipairs(target_utils.get_values_from_target(target, "links")) do
                    local link_path = _resolve_link(linkdirs, link)
                    if link_path then
                        table.insert(libraryfiles, link_path)
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
            end, {dependfile = target:dependfile(target:targetfile() .. ".merge_archive"), files = libraryfiles, changed = target:is_rebuilt()})
        end
    end)

