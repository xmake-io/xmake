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

-- define rule: *.ui
rule("qt.ui")

    -- add rule: qt environment
    add_deps("qt.env")

    -- set extensions
    set_extensions(".ui")

    -- before load
    before_load(function (target)

        -- get uic
        local uic = path.join(target:data("qt").bindir, is_host("windows") and "uic.exe" or "uic")
        assert(uic and os.isexec(uic), "uic not found!")

        -- add includedirs, @note we use sysincludedirs to suppress warning (file not found).
        -- and we muse add it in load stage to ensure `depend.on_changed` work.
        --
        -- @see https://github.com/xmake-io/xmake/issues/1180
        --
        local headerfile_dir = path.join(target:autogendir(), "rules", "qt", "ui")
        target:add("sysincludedirs", path.absolute(headerfile_dir, os.projectdir()))

        -- save uic
        target:data_set("qt.uic", uic)
    end)

    -- before build file
    before_build_file(function (target, sourcefile_ui, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.config")
        import("core.project.depend")
        import("private.utils.progress")

        -- do build
        local uic = target:data("qt.uic")
        local dryrun = option.get("dry-run")
        local headerfile_dir = path.join(target:autogendir(), "rules", "qt", "ui")
        local headerfile_ui = path.join(headerfile_dir, "ui_" .. path.basename(sourcefile_ui) .. ".h")
        depend.on_changed(function ()
            progress.show(opt.progress, "${color.build.object}compiling.qt.ui %s", sourcefile_ui)
            if not dryrun then
                if not os.isdir(headerfile_dir) then
                    os.mkdir(headerfile_dir)
                end
                os.vrunv(uic, {sourcefile_ui, "-o", headerfile_ui})
            end
        end, {dependfile = target:dependfile(headerfile_ui), files = {sourcefile_ui}, lastmtime = os.mtime(headerfile_ui), always_changed = dryrun})
    end)
