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
    on_load(function (target)
        -- only vala source files? we need patch c source kind for linker
        local sourcekinds = target:sourcekinds()
        if #sourcekinds == 0 then
            table.insert(sourcekinds, "cc")
        end

        -- we disable to build across targets in parallel, because the source files may depend on other target modules
        target:set("policy", "build.across_targets_in_parallel", false)

        -- get vapi file
        local vapifile = target:data("vala.vapifile")
        if not vapifile then
            local vapiname = target:values("vala.vapi")
            if vapiname then
                vapifile = path.join(target:targetdir(), vapiname)
            else
                vapifile = path.join(target:targetdir(), target:name() .. ".vapi")
            end
            target:data_set("vala.vapifile", vapifile)
        end
    end)
    before_buildcmd_file(function (target, batchcmds, sourcefile_vala, opt)

        -- get valac
        import("lib.detect.find_tool")
        local valac = assert(find_tool("valac"), "valac not found!")

        -- get c source file for vala
        local sourcefile_c = target:autogenfile((sourcefile_vala:gsub(".vala$", ".c")))
        local basedir = path.directory(sourcefile_c)

        -- add objectfile
        local objectfile = target:objectfile(sourcefile_c)
        table.insert(target:objectfiles(), objectfile)

        -- add commands
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.vala %s", sourcefile_vala)
        batchcmds:mkdir(basedir)
        local argv = {"-C", "-b", basedir}
        local packages = target:values("vala.packages")
        if packages then
            for _, package in ipairs(packages) do
                table.insert(argv, "--pkg")
                table.insert(argv, package)
            end
        end
        if target:is_binary() then
            for _, dep in ipairs(target:orderdeps()) do
                if dep:is_shared() or dep:is_static() then
                    local vapifile = dep:data("vala.vapifile")
                    if vapifile then
                        table.join2(argv, vapifile)
                    end
                end
            end
        else
            local vapifile = target:data("vala.vapifile")
            if vapifile then
                table.insert(argv, "--vapi=" .. vapifile)
            end
        end
        table.insert(argv, sourcefile_vala)
        batchcmds:vrunv(valac.program, argv)
        batchcmds:compile(sourcefile_c, objectfile)

        -- add deps
        batchcmds:add_depfiles(sourcefile_vala)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
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

    -- check targets
    add_deps("utils.check.targets")

    -- check licenses
    add_deps("utils.check.licenses")


