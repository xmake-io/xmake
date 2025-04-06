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

-- add *.idl for rc file
rule("platform.windows.idl")
    set_extensions(".idl")

    on_config(function (target)
        local autogendir = path.join(target:autogendir(), "platform/windows/idl")
        os.mkdir(autogendir)
        target:add("includedirs", autogendir, {public = true})
    end)

    before_buildcmd_file(function (target, batchcmds, sourcefile, opt)
        import("lib.detect.find_tool")

        local msvc = target:toolchain("msvc") or target:toolchain("clang-cl") or target:toolchain("clang")
        local midl = assert(find_tool("midl", {envs = msvc:runenvs(), toolchain = msvc}), "midl not found!")

        local name = path.basename(sourcefile)
        local autogendir = path.join(target:autogendir(), "platform/windows/idl")

        local flags = {"/nologo"}
        table.join2(flags, table.wrap(target:values("idl.flags")))
        table.join2(flags, {
            "/out",    path(autogendir),
            "/header", name .. ".h",
            "/iid",    name .. "_i.c",
            "/proxy",  name .. "_p.c",
            "/tlb",    name .. ".tlb",
            path(sourcefile)
        })

        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.idl %s", sourcefile)
        batchcmds:vrunv(midl.program, flags, {envs = msvc:runenvs()})
        
        local iid_file = path.join(autogendir, name .. "_i.c")
        local objectfile = target:objectfile(iid_file)
        table.insert(target:objectfiles(), objectfile)

        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.$(mode) %s", iid_file)
        batchcmds:compile(iid_file, objectfile)

        batchcmds:add_depfiles(sourcefile, iid_file)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)
