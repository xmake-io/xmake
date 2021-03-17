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

-- add *.bpf.c for linux bpf program
-- @see https://github.com/xmake-io/xmake/issues/1274
rule("platform.linux.bpf")
    set_extensions(".bpf.c")
    on_config(function (target)
        assert(is_host("linux"), 'rule("platform.linux.bpf"): only supported on linux!')
        local headerdir = path.join(target:autogendir(), "rules", "bpf")
        target:add("includedirs", headerdir)
    end)
    before_buildcmd_file(function (target, batchcmds, sourcefile, opt)
        local headerfile = path.join(target:autogendir(), "rules", "bpf", (path.filename(sourcefile):gsub("%.bpf%.c", ".skel.h")))
        local objectfile = path.join(target:autogendir(), "rules", "bpf", (path.filename(sourcefile):gsub("%.bpf%.c", ".bpf.o")))
        target:add("includedirs", path.directory(headerfile))
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.bpf %s", sourcefile)
        batchcmds:mkdir(path.directory(objectfile))
        batchcmds:compile(sourcefile, objectfile, {configs = {force = {cxflags = {"-target bpf", "-g"}, defines = "__TARGET_ARCH_x86"}}})
        batchcmds:mkdir(path.directory(headerfile))
        batchcmds:vrunv("bpftool", {"gen", "skeleton", objectfile}, {stdout = headerfile})
        batchcmds:add_depfiles(sourcefile)
        batchcmds:set_depmtime(os.mtime(headerfile))
        batchcmds:set_depcache(target:dependfile(headerfile))
    end)

