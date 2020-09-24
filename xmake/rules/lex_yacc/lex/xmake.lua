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

-- define rule: lex
rule("lex")

    -- set extension
    set_extensions(".l", ".ll")

    -- load lex/flex
    before_load(function (target)
        import("core.project.config")
        import("lib.detect.find_tool")
        local lex = config.get("__lex")
        if not lex then
            lex = find_tool("flex") or find_tool("lex")
            if lex and lex.program then
                config.set("__lex", lex.program)
                cprint("checking for Lex ... ${color.success}%s", lex.program)
            else
                cprint("checking for Lex ... ${color.nothing}${text.nothing}")
                raise("lex/flex not found!")
            end
        end
    end)

    -- build lex file
    on_build_file(function (target, sourcefile_lex, opt)

        -- imports
        import("core.base.option")
        import("core.theme.theme")
        import("core.project.config")
        import("core.project.depend")
        import("core.tool.compiler")
        import("private.utils.progress")

        -- get lex
        local lex = assert(config.get("__lex"), "lex not found!")

        -- get extension: .l/.ll
        local extension = path.extension(sourcefile_lex)

        -- get c/c++ source file for lex
        local sourcefile_cx = path.join(target:autogendir(), "rules", "lex_yacc", path.basename(sourcefile_lex) .. (extension == ".ll" and ".cpp" or ".c"))
        local sourcefile_dir = path.directory(sourcefile_cx)

        -- get object file
        local objectfile = target:objectfile(sourcefile_cx)

        -- load compiler
        local compinst = compiler.load((extension == ".ll" and "cxx" or "cc"), {target = target})

        -- get compile flags
        local compflags = compinst:compflags({target = target, sourcefile = sourcefile_cx, configs = {includedirs = sourcefile_dir}})

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
        progress.show(opt.progress, "${color.build.object}compiling.lex %s", sourcefile_lex)

        -- ensure the source file directory
        if not os.isdir(sourcefile_dir) then
            os.mkdir(sourcefile_dir)
        end

        -- compile lex
        os.vrunv(lex, {"-o", sourcefile_cx, sourcefile_lex})

        -- trace
        if option.get("verbose") then
            print(compinst:compcmd(sourcefile_cx, objectfile, {compflags = compflags}))
        end

        -- compile c/c++ source file for lex
        dependinfo.files = {}
        assert(compinst:compile(sourcefile_cx, objectfile, {dependinfo = dependinfo, compflags = compflags}))

        -- update files and values to the dependent file
        dependinfo.values = depvalues
        table.insert(dependinfo.files, sourcefile_lex)
        depend.save(dependinfo, dependfile)
    end)

