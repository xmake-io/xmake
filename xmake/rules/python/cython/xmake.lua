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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      Wu, Zhenyu
-- @file        xmake.lua
--

rule("python.cython")
    add_deps("python.module")
    set_extensions(".py", ".pyx", ".pyi")

    on_load(function (target)
        local language = target:extraconf("rules", "python.cython", "language")
        if language == "c" then
            target:add("deps", "c")
        elseif language == "c++" then
            target:add("deps", "c++")
        end
    end)

    before_buildcmd_file(function (target, batchcmds, sourcefile, opt)
        import("lib.detect.find_tool")

        local cython = assert(find_tool("cython"), "cython not found! please `pip install cython`.")
        local language = target:extraconf("rules", "python.cython", "language")
        local ext = "c"
        local arg = "-3"
        if language == "c++" then
            ext = "cc"
            arg = arg .. "+"
        end
        local dirname = path.join(target:autogendir(), "rules", "python", "cython")
        local sourcefile_c = path.join(dirname, path.basename(sourcefile) .. "." .. ext)

        -- add objectfile
        local objectfile = target:objectfile(sourcefile_c)
        table.insert(target:objectfiles(), objectfile)

        -- add commands
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.python %s", sourcefile)
        batchcmds:mkdir(path.directory(sourcefile_c))
        batchcmds:vrunv(cython.program, {arg, "-o", path(sourcefile_c), path(sourcefile)})
        batchcmds:compile(sourcefile_c, objectfile)

        -- add deps
        batchcmds:add_depfiles(sourcefile)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)
