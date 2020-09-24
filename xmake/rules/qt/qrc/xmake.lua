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

-- define rule: *.qrc
rule("qt.qrc")

    -- add rule: qt environment
    add_deps("qt.env")

    -- set extensions
    set_extensions(".qrc")

    -- before load
    before_load(function (target)

        -- get rcc
        local rcc = path.join(target:data("qt").bindir, is_host("windows") and "rcc.exe" or "rcc")
        assert(rcc and os.isexec(rcc), "rcc not found!")

        -- save rcc
        target:data_set("qt.rcc", rcc)
    end)

    -- on build file
    on_build_file(function (target, sourcefile_qrc, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.config")
        import("core.project.depend")
        import("core.tool.compiler")
        import("private.utils.progress")

        -- get rcc
        local rcc = target:data("qt.rcc")

        -- get c++ source file for qrc
        local sourcefile_cpp = path.join(target:autogendir(), "rules", "qt", "qrc", path.basename(sourcefile_qrc) .. ".cpp")
        local sourcefile_dir = path.directory(sourcefile_cpp)

        -- get object file
        local objectfile = target:objectfile(sourcefile_cpp)

        -- load compiler
        local compinst = compiler.load("cxx", {target = target})

        -- get compile flags
        local compflags = compinst:compflags({target = target, sourcefile = sourcefile_cpp})

        -- add objectfile
        table.insert(target:objectfiles(), objectfile)

        -- load dependent info
        local dependfile = target:dependfile(objectfile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})

        -- need build this object?
        local depvalues = {compinst:program(), compflags}
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(objectfile), values = depvalues}) then
            return
        end

        -- trace progress info
        progress.show(opt.progress, "${color.build.object}compiling.qt.qrc %s", sourcefile_qrc)

        -- ensure the source file directory
        if not os.isdir(sourcefile_dir) then
            os.mkdir(sourcefile_dir)
        end

        -- compile qrc
        os.vrunv(rcc, {"-name", path.basename(sourcefile_qrc), sourcefile_qrc, "-o", sourcefile_cpp})

        -- trace
        if option.get("verbose") then
            print(compinst:compcmd(sourcefile_cpp, objectfile, {compflags = compflags}))
        end

        -- compile c++ source file for qrc
        dependinfo.files = {}
        assert(compinst:compile(sourcefile_cpp, objectfile, {dependinfo = dependinfo, compflags = compflags}))

        -- update files and values to the dependent file
        dependinfo.values = depvalues
        table.insert(dependinfo.files, sourcefile_qrc)
        depend.save(dependinfo, dependfile)
    end)

