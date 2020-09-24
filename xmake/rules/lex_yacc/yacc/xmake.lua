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

-- define rule: yacc
rule("yacc")

    -- set extension
    set_extensions(".y", ".yy")

    -- load yacc/bison
    before_load(function (target)
        import("core.project.config")
        import("lib.detect.find_tool")
        local yacc = config.get("__yacc")
        if not yacc then
            yacc = find_tool("bison") or find_tool("yacc")
            if yacc and yacc.program then
                config.set("__yacc", yacc.program)
                cprint("checking for Yacc ... ${color.success}%s", yacc.program)
            else
                cprint("checking for Yacc ... ${color.nothing}${text.nothing}")
                raise("yacc/bison not found!")
            end
        end
    end)

    -- build yacc file
    before_build_file(function (target, sourcefile_yacc, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.config")
        import("core.project.depend")
        import("core.tool.compiler")
        import("private.utils.progress")

        -- get yacc
        local yacc = assert(config.get("__yacc"), "yacc not found!")

        -- get extension: .l/.ll
        local extension = path.extension(sourcefile_yacc)

        -- get c/c++ source file for yacc
        local sourcefile_cx = path.join(target:autogendir(), "rules", "lex_yacc", path.basename(sourcefile_yacc) .. ".tab" .. (extension == ".yy" and ".cpp" or ".c"))
        local sourcefile_dir = path.directory(sourcefile_cx)

        -- get object file
        local objectfile = target:objectfile(sourcefile_cx)

        -- load compiler
        local compinst = compiler.load((extension == ".yy" and "cxx" or "cc"), {target = target})

        -- get compile flags
        local compflags = compinst:compflags({target = target, sourcefile = sourcefile_cx})

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
        progress.show(opt.progress, "${color.build.object}compiling.yacc %s", sourcefile_yacc)

        -- ensure the source file directory
        if not os.isdir(sourcefile_dir) then
            os.mkdir(sourcefile_dir)
        end

        -- compile yacc
        os.vrunv(yacc, {"-d", "-o", sourcefile_cx, sourcefile_yacc})

        -- trace
        if option.get("verbose") then
            print(compinst:compcmd(sourcefile_cx, objectfile, {compflags = compflags}))
        end

        -- compile c/c++ source file for yacc
        dependinfo.files = {}
        assert(compinst:compile(sourcefile_cx, objectfile, {dependinfo = dependinfo, compflags = compflags}))

        -- update files and values to the dependent file
        dependinfo.values = depvalues
        table.insert(dependinfo.files, sourcefile_yacc)
        depend.save(dependinfo, dependfile)
    end)

