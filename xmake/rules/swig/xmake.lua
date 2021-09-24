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

-- references:
--
-- https://github.com/xmake-io/xmake/issues/1622
-- http://www.swig.org/Doc4.0/SWIGDocumentation.html#Introduction_nn4
--

rule("swig.base")
    on_load(function (target)
        target:set("kind", "shared")
        if target:is_plat("windows") then
            target:set("extension", ".pyd")
        end
    end)

rule("swig.c")
    set_extensions(".i")
    add_deps("swig.base")
    on_buildcmd_file(function (target, batchcmds, sourcefile, opt)
        import("build_module_file")(target, batchcmds, sourcefile, table.join({sourcekind = "cc"}, opt))
    end)

rule("swig.cpp")
    set_extensions(".i")
    add_deps("swig.base")
    on_buildcmd_file(function (target, batchcmds, sourcefile, opt)
        import("build_module_file")(target, batchcmds, sourcefile, table.join({sourcekind = "cxx"}, opt))
    end)


