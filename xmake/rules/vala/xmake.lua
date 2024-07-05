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

rule("vala.build")
    set_extensions(".vala")
    -- Since vala can directly compile with C files
    -- we can add C sourcekinds
    -- And in the end we're going to be compiling C code
    set_sourcekinds("cc")
    on_load(function (target)
        -- we disable to build across targets in parallel, because the source files may depend on other target modules
        target:set("policy", "build.across_targets_in_parallel", false)

        -- get vapi file
        local vapifile = target:data("vala.vapifile")
        if not vapifile then
            local vapiname = target:values("vala.vapi")
            if vapiname then
                vapifile = path.absolute(path.join(target:targetdir(), vapiname))
            else
                vapifile = path.absolute(path.join(target:targetdir(), target:name() .. ".vapi"))
            end
            target:data_set("vala.vapifile", vapifile)
        end

        -- get header file
        local headerfile = target:data("vala.headerfile")
        if not headerfile then
            local headername = target:values("vala.header")
            if headername then
                headerfile = path.absolute(path.join(target:targetdir(), headername))
            else
                headerfile = path.absolute(path.join(target:targetdir(), target:name() .. ".h"))
            end
            target:data_set("vala.headerfile", headerfile)
        end
        if headerfile then
            target:add("headerfiles", headerfile)
            target:add("sysincludedirs", path.directory(headerfile), {public = true})
        end
    end)
    before_buildcmd_files(function (target, batchcmds, sourcebatch, opt)
        -- Here we compile vala files into C code

        -- We have to compile entire project each time
        -- because otherwise valac can't resolve symbols
        -- from other files, however, c files can be
        -- incrementally built

        -- get valac
        import("lib.detect.find_tool")
        local valac = assert(find_tool("valac"), "valac not found!")

        local argv = {"-C", "-d", target:autogendir()}

        -- add commands
        local packages = target:values("vala.packages")
        if packages then
            for _, package in ipairs(packages) do
                table.insert(argv, "--pkg")
                table.insert(argv, path(package))
            end
        end

        if target:is_binary() then
            for _, dep in ipairs(target:orderdeps()) do
                if dep:is_shared() or dep:is_static() then
                    local vapifile = dep:data("vala.vapifile")
                    if vapifile then
                        table.join2(argv, path(vapifile))
                    end
                end
            end
        else
            local vapifile = target:data("vala.vapifile")
            if vapifile then
                table.insert(argv, path(vapifile, function (p) return "--vapi=" .. p end))
            end
            local headerfile = target:data("vala.headerfile")
            if headerfile then
                table.insert(argv, "-H")
                table.insert(argv, path(headerfile))
            end
        end

        local vapidir = target:values("vala.vapidir")
        if vapidir then
            table.insert(argv, path(vapidir, function (p) return "--vapidir=" .. p end))
        end

        local valaflags = target:values("vala.flags")
        if valaflags then
            table.join2(argv, valaflags)
        end

        -- iterating through source files,
        -- otherwise valac would fail when compiling multiple files
        local lastmtime = 0
        local sourcefiles = {}
        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
            -- if it's only a vala file
            if path.extension(sourcefile) == ".vala" then
                local sourcefile_c = target:autogenfile((sourcefile:gsub(".vala$", ".c")))
                batchcmds:show_progress(opt.progress, "${color.build.object}compiling.vala %s", sourcefile)
                table.insert(argv, path(sourcefile))
                table.insert(sourcefiles, sourcefile)
                local sourcefile_c_mtime = os.mtime(sourcefile_c)
                if sourcefile_c_mtime > lastmtime then
                    lastmtime = sourcefile_c_mtime
                end
            end
        end

        if #sourcefiles > 0 then
            batchcmds:vrunv(valac.program, argv)
            batchcmds:add_depfiles(sourcefiles)
            batchcmds:set_depmtime(lastmtime)
        end
    end)

    on_buildcmd_file(function (target, batchcmds, sourcefile, opt)
        -- Again, only vala files need special treatment
        if path.extension(sourcefile) == ".vala" then
            local sourcefile_c = target:autogenfile((sourcefile:gsub(".vala$", ".c")))
            local basedir = path.directory(sourcefile_c)

            batchcmds:mkdir(basedir)

            local objectfile = target:objectfile(sourcefile_c)
            table.insert(target:objectfiles(), objectfile)

            batchcmds:show_progress(opt.progress, "${color.build.object}compiling.c %s", sourcefile_c)
            batchcmds:compile(sourcefile_c, objectfile, { configs = { force = { cflags = "-w" } } })

            batchcmds:add_depfiles(sourcefile)
            batchcmds:set_depmtime(os.mtime(objectfile))
            batchcmds:set_depcache(target:dependfile(objectfile))
        end
    end)

    after_install(function (target)
        if target:is_shared() or target:is_static() then
            local vapifile = target:data("vala.vapifile")
            if vapifile then
                local installdir = target:installdir()
                if installdir then
                    local sharedir = path.join(installdir, "share")
                    os.mkdir(sharedir)
                    os.vcp(vapifile, sharedir)
                end
            end
        end
    end)

    after_uninstall(function (target)
        if target:is_shared() or target:is_static() then
            local vapifile = target:data("vala.vapifile")
            if vapifile then
                local installdir = target:installdir()
                if installdir then
                    os.rm(path.join(installdir, "share", path.filename(vapifile)))
                end
            end
        end
    end)

rule("vala")

    -- add build rules
    add_deps("vala.build")

    -- set compiler runtime, e.g. vs runtime
    add_deps("utils.compiler.runtime")

    -- inherit links and linkdirs of all dependent targets by default
    add_deps("utils.inherit.links")

    -- support `add_files("src/*.o")` and `add_files("src/*.a")` to merge object and archive files to target
    add_deps("utils.merge.object", "utils.merge.archive")

    -- we attempt to extract symbols to the independent file and
    -- strip self-target binary if `set_symbols("debug")` and `set_strip("all")` are enabled
    add_deps("utils.symbols.extract")
