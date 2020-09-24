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

        -- get uic
        local uic = target:data("qt.uic")

        -- get c++ header file for ui
        local headerfile_ui = path.join(target:autogendir(), "rules", "qt", "ui", "ui_" .. path.basename(sourcefile_ui) .. ".h")
        local headerfile_dir = path.directory(headerfile_ui)

        -- add includedirs
        target:add("includedirs", path.absolute(headerfile_dir, os.projectdir()))

        -- need build this object?
        local dependfile = target:dependfile(headerfile_ui)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(headerfile_ui)}) then
            return
        end

        -- trace progress info
        progress.show(opt.progress, "${color.build.object}compiling.qt.ui %s", sourcefile_ui)

        -- ensure ui header file directory
        if not os.isdir(headerfile_dir) then
            os.mkdir(headerfile_dir)
        end

        -- compile ui
        os.vrunv(uic, {sourcefile_ui, "-o", headerfile_ui})

        -- update files and values to the dependent file
        dependinfo.files = {sourcefile_ui}
        depend.save(dependinfo, dependfile)
    end)
