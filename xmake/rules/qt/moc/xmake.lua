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

-- define rule: moc
rule("qt.moc")

    -- add rule: qt environment
    add_deps("qt.env")

    -- set extensions
    set_extensions(".h", ".hpp")

    -- before load
    before_load(function (target)

        -- get moc
        local moc = path.join(target:data("qt").bindir, is_host("windows") and "moc.exe" or "moc")
        assert(moc and os.isexec(moc), "moc not found!")

        -- save moc
        target:data_set("qt.moc", moc)
    end)

    -- before build file (we need compile it first if exists Q_PRIVATE_SLOT)
    before_build_file(function (target, sourcefile, opt)

        -- imports
        import("moc")
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.config")
        import("core.tool.compiler")
        import("core.project.depend")
        import("private.utils.progress")

        -- get c++ source file for moc
        --
        -- add_files("mainwindow.h") -> moc_MainWindow.cpp
        -- add_files("mainwindow.cpp", {rules = "qt.moc"}) -> mainwindow.moc, @see https://github.com/xmake-io/xmake/issues/750
        --
        local basename = path.basename(sourcefile)
        local filename_moc = "moc_" .. basename .. ".cpp"
        if sourcefile:endswith(".cpp") then
            filename_moc = basename .. ".moc"
        end
        local sourcefile_moc = path.join(target:autogendir(), "rules", "qt", "moc", filename_moc)

        -- get object file
        local objectfile = target:objectfile(sourcefile_moc)

        -- load compiler
        local compinst = compiler.load("cxx", {target = target})

        -- get compile flags
        local compflags = compinst:compflags({target = target, sourcefile = sourcefile_moc})

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
        progress.show(opt.progress, "${color.build.object}compiling.qt.moc %s", sourcefile)

        -- generate c++ source file for moc
        moc.generate(target, sourcefile, sourcefile_moc)

        -- we need compile this moc_xxx.cpp file if exists Q_PRIVATE_SLOT, @see https://github.com/xmake-io/xmake/issues/750
        dependinfo.files = {}
        local mocdata = io.readfile(sourcefile)
        if mocdata and mocdata:find("Q_PRIVATE_SLOT") or sourcefile_moc:endswith(".moc") then
            -- add includedirs of sourcefile_moc
            target:add("includedirs", path.directory(sourcefile_moc))

            -- remove the object file of sourcefile_moc
            local objectfiles = target:objectfiles()
            for idx, objectfile in ipairs(objectfiles) do
                if objectfile == target:objectfile(sourcefile_moc) then
                    table.remove(objectfiles, idx)
                    break
                end
            end
        else
            -- trace
            if option.get("verbose") then
                print(compinst:compcmd(sourcefile_moc, objectfile, {compflags = compflags}))
            end

            -- compile c++ source file for moc
            assert(compinst:compile(sourcefile_moc, objectfile, {dependinfo = dependinfo, compflags = compflags}))
        end

        -- update files and values to the dependent file
        dependinfo.values = depvalues
        table.insert(dependinfo.files, sourcefile)
        depend.save(dependinfo, dependfile)
    end)
