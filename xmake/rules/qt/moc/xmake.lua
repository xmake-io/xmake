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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
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

    -- on build file
    on_build_file(function (target, headerfile_moc, opt)

        -- imports
        import("moc")
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.config")
        import("core.tool.compiler")
        import("core.project.depend")

        -- get c++ source file for moc
        local sourcefile_moc = path.join(target:autogendir(), "rules", "qt", "moc", "moc_" .. path.basename(headerfile_moc) .. ".cpp")

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
        cprintf("${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} ", opt.progress)
        if option.get("verbose") then
            cprint("${dim color.build.object}compiling.qt.moc %s", headerfile_moc)
        else
            cprint("${color.build.object}compiling.qt.moc %s", headerfile_moc)
        end

        -- generate c++ source file for moc
        moc.generate(target, headerfile_moc, sourcefile_moc)

        -- trace
        if option.get("verbose") then
            print(compinst:compcmd(sourcefile_moc, objectfile, {compflags = compflags}))
        end

        -- compile c++ source file for moc
        dependinfo.files = {}
        assert(compinst:compile(sourcefile_moc, objectfile, {dependinfo = dependinfo, compflags = compflags}))

        -- update files and values to the dependent file
        dependinfo.values = depvalues
        table.insert(dependinfo.files, headerfile_moc)
        depend.save(dependinfo, dependfile)
    end)
