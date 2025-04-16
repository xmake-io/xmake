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

-- add *.idl for rc file
rule("platform.windows.idl")
    set_extensions(".idl")
    on_config("windows", "mingw", function (target)
        import("idl").configure(target)
    end)
    before_build_files(function (target, jobgraph, sourcebatch, opt)
        import("idl").gen_idl(target, jobgraph, sourcebatch, opt)
    end, {jobgraph = true, batch = true})
    on_build_files(function (target, jobgraph, sourcebatch, opt)
        import("idl").build_idlfiles(target, jobgraph, sourcebatch, opt)
    end, {jobgraph = true, batch = true, distcc = true})
