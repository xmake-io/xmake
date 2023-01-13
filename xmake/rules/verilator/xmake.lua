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
        io.gsub(cmakefile, "set%((%S-) (.-)%)", function (key, values)
            if key == "VERILATOR_ROOT" then
                verilator_root = values:match("\"(.-)\" CACHE PATH")
                if not verilator_root then
                    verilator_root = values:match("(.-) CACHE PATH")
                end
            end
        end)
        assert(verilator_root, "the verilator root directory not found!")

        -- add includedirs
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

        -- TODO add defines
        target:add("defines", "VM_COVERAGE=0")
        target:add("defines", "VM_SC=0")
        target:add("defines", "VM_TRACE=1")
        target:add("defines", "VM_TRACE_FST=0")
        target:add("defines", "VM_TRACE_VCD=1")

        -- add syslinks
        if target:is_plat("linux", "macosx") then
            target:add("syslinks", "pthread")
            target:add("ldflags", "-fcoroutines")
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
        local sourcefiles = sourcebatch.sourcefiles
        for _, sourcefile in ipairs(sourcefiles) do
            batchcmds:show_progress(opt.progress, "${color.build.target}compiling.verilator %s", path.filename(sourcefile))
        end
        table.join2(argv, sourcefiles)

        -- generate c++ sourcefiles
        batchcmds:mkdir(autogendir)
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
        local dependfile = path.join(autogendir, targetname .. ".build.d")

        -- TODO we need get correct files list
        local sourcefiles = os.files(path.join(autogendir, "*.cpp"))

        -- do build
        for _, sourcefile in ipairs(sourcefiles) do
            local objectfile = target:objectfile(sourcefile)
            batchcmds:compile(sourcefile, objectfile)
            table.insert(target:objectfiles(), objectfile)
        end
        batchcmds:add_depfiles(sourcefiles)
        batchcmds:set_depmtime(os.mtime(dependfile))
        batchcmds:set_depcache(dependfile)
    end)

