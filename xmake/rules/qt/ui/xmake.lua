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

rule("qt.ui")
    add_deps("qt.env")
    set_extensions(".ui")
    on_load(function (target)

        -- get uic
        local qt = assert(target:data("qt"), "qt not found!")
        local uic = path.join(qt.bindir, is_host("windows") and "uic.exe" or "uic")
        if not os.isexec(uic) and qt.libexecdir then
            uic = path.join(qt.libexecdir, is_host("windows") and "uic.exe" or "uic")
        end
        if not os.isexec(uic) and qt.libexecdir_host then
            uic = path.join(qt.libexecdir_host, is_host("windows") and "uic.exe" or "uic")
        end
        assert(uic and os.isexec(uic), "uic not found!")

        -- add includedirs, @note we need create this directory first to suppress warning (file not found).
        -- and we muse add it in load stage to ensure `depend.on_changed` work.
        --
        -- @see https://github.com/xmake-io/xmake/issues/1180
        --
        local headerfile_dir = path.join(target:autogendir(), "rules", "qt", "ui")
        if not os.isdir(headerfile_dir) then
            os.mkdir(headerfile_dir)
        end
        target:add("includedirs", path.absolute(headerfile_dir, os.projectdir()))

        -- save uic
        target:data_set("qt.uic", uic)
    end)

    before_buildcmd_file(function (target, batchcmds, sourcefile_ui, opt)
        local uic = target:data("qt.uic")
        local headerfile_dir = path.join(target:autogendir(), "rules", "qt", "ui")
        local headerfile_ui = path.join(headerfile_dir, "ui_" .. path.basename(sourcefile_ui) .. ".h")
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.qt.ui %s", sourcefile_ui)
        batchcmds:mkdir(headerfile_dir)
        batchcmds:vrunv(uic, {path(sourcefile_ui), "-o", path(headerfile_ui)})
        batchcmds:add_depfiles(sourcefile_ui)
        batchcmds:set_depmtime(os.mtime(headerfile_ui))
        batchcmds:set_depcache(target:dependfile(headerfile_ui))
    end)

