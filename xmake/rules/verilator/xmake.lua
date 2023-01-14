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

-- @see https://github.com/xmake-io/xmake/issues/3257
rule("verilator.binary")
    set_extensions(".v")
    on_load(function (target)
        target:set("kind", "binary")
    end)

    on_config(function (target)
        local toolchain = assert(target:toolchain("verilator"), 'we need set_toolchains("verilator") in target("%s")', target:name())
        local verilator = assert(toolchain:config("verilator"), "verilator not found!")
        local autogendir = path.join(target:autogendir(), "rules", "verilator")
        local tmpdir = os.tmpfile() .. ".dir"
        local cmakefile = path.join(tmpdir, "test.cmake")
        local sourcefile = path.join(tmpdir, "main.v")
        local argv = {"--cc", "--make", "cmake", "--prefix", "test", "--Mdir", tmpdir, sourcefile}
        local flags = target:values("verilator.flags")
        if flags then
            table.join2(argv, flags)
        end
        io.writefile(sourcefile, [[
module hello;
  initial begin
    $display("hello world!");
    $finish ;
  end
endmodule]])
        os.mkdir(tmpdir)
        os.runv(verilator, argv)

        -- parse some configurations from cmakefile
        local verilator_root
        local switches = {}
        local targetname = target:name()
        io.gsub(cmakefile, "set%((%S-) (.-)%)", function (key, values)
            if key == "VERILATOR_ROOT" then
                verilator_root = values:match("\"(.-)\" CACHE PATH")
                if not verilator_root then
                    verilator_root = values:match("(.-) CACHE PATH")
                end
            elseif key == "test_SC" then
                -- SystemC output mode?  0/1 (from --sc)
                switches.SC = values:trim()
            elseif key == "test_COVERAGE" then
                -- Coverage output mode?  0/1 (from --coverage)
                switches.COVERAGE = values:trim()
            elseif key == "test_TIMING" then
                -- Timing mode?  0/1 (from --timing)
                switches.TIMING = values:trim()
            elseif key == "test_THREADS" then
                -- Threaded output mode?  1/N threads (from --threads)
                switches.THREADS = values:trim()
            elseif key == "test_TRACE_VCD" then
                -- VCD Tracing output mode?  0/1 (from --trace)
                switches.TRACE_VCD = values:trim()
            elseif key == "test_TRACE_FST" then
                -- FST Tracing output mode? 0/1 (from --trace-fst)
                switches.TRACE_FST = values:trim()
            end

        end)
        assert(verilator_root, "the verilator root directory not found!")
        target:data_set("verilator.root", verilator_root)

        -- add includedirs
        if not os.isfile(autogendir) then
            os.mkdir(autogendir)
        end
        target:add("includedirs", autogendir)
        target:add("includedirs", path.join(verilator_root, "include"))
        target:add("includedirs", path.join(verilator_root, "include", "vltstd"))

        -- set languages
        local languages = target:get("languages")
        local cxxlang = false
        for _, lang in ipairs(languages) do
            if lang:startswith("xx") or lang:startswith("++") then
                cxxlang = true
                break
            end
        end
        if not cxxlang then
            target:set("languages", "c++20")
        end

        -- add defines for switches
        for k, v in pairs(switches) do
            target:add("defines", "VM_" .. k .. "=" .. v)
        end

        -- add syslinks
        if target:is_plat("linux", "macosx") and switches.THREADS == "1" then
            target:add("syslinks", "pthread")
        end

        os.rm(tmpdir)
    end)

    before_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        local toolchain = assert(target:toolchain("verilator"), 'we need set_toolchains("verilator") in target("%s")', target:name())
        local verilator = assert(toolchain:config("verilator"), "verilator not found!")
        local autogendir = path.join(target:autogendir(), "rules", "verilator")
        local targetname = target:name()
        local cmakefile = path.join(autogendir, targetname .. ".cmake")
        local dependfile = cmakefile .. ".d"

        local argv = {"--cc", "--make", "cmake", "--prefix", targetname, "--Mdir", path(autogendir)}
        local flags = target:values("verilator.flags")
        if flags then
            table.join2(argv, flags)
        end
        local sourcefiles = sourcebatch.sourcefiles
        for _, sourcefile in ipairs(sourcefiles) do
            batchcmds:show_progress(opt.progress, "${color.build.object}compiling.verilator %s", path.filename(sourcefile))
        end
        table.join2(argv, sourcefiles)

        -- generate c++ sourcefiles
        batchcmds:vrunv(verilator, argv)
        batchcmds:add_depfiles(sourcefiles)
        batchcmds:set_depmtime(os.mtime(cmakefile))
        batchcmds:set_depcache(dependfile)
    end)

    on_buildcmd_files(function (target, batchcmds, sourcebatch, opt)
        local toolchain = assert(target:toolchain("verilator"), 'we need set_toolchains("verilator") in target("%s")', target:name())
        local verilator = assert(toolchain:config("verilator"), "verilator not found!")
        local autogendir = path.join(target:autogendir(), "rules", "verilator")
        local targetname = target:name()
        local cmakefile = path.join(autogendir, targetname .. ".cmake")
        local dependfile = path.join(autogendir, targetname .. ".build.d")
        local verilator_root = assert(target:data("verilator.root"), "no verilator_root!")

        -- parse some configurations from cmakefile
        local global_classes = {}
        io.gsub(cmakefile, "set%((%S-) (.-)%)", function (key, values)
            if key == targetname .. "_GLOBAL" then
                -- get global class source files
                -- set(hello_GLOBAL "${VERILATOR_ROOT}/include/verilated.cpp" "${VERILATOR_ROOT}/include/verilated_threads.cpp")
                for classfile in values:gmatch("\"(.-)\"") do
                    classfile = classfile:gsub("%${VERILATOR_ROOT}", verilator_root)
                    if os.isfile(classfile) then
                        table.insert(global_classes, classfile)
                    end
                end
            end
        end)

        -- get compiled source files
        local sourcefiles = os.files(path.join(autogendir, "*.cpp"))
        table.join2(sourcefiles, global_classes)

        -- do build
        for _, sourcefile in ipairs(sourcefiles) do
            local objectfile = target:objectfile(sourcefile)
            batchcmds:show_progress(opt.progress, "${color.build.object}compiling.$(mode) %s", path.filename(sourcefile))
            batchcmds:compile(sourcefile, objectfile)
            table.insert(target:objectfiles(), objectfile)
        end
        batchcmds:add_depfiles(sourcefiles)
        batchcmds:set_depmtime(os.mtime(dependfile))
        batchcmds:set_depcache(dependfile)
    end)

