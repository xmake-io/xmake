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
    add_deps("c++")
    set_extensions(".v", ".sv")
    on_load(function (target)
        target:set("kind", "binary")
    end)

    on_config(function (target)
        import("verilator").config(target)
    end)

    before_build_files(function (target, sourcebatch)
        -- Just to avoid before_buildcmd_files being executed at build time
    end)

    on_build_files(function (target, batchjobs, sourcebatch, opt)
        import("verilator").build_cppfiles(target, batchjobs, sourcebatch, opt)
    end, {batch = true, distcc = true})

    before_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        import("verilator").buildcmd_vfiles(target, batchcmds, sourcebatch, opt)
    end)

    on_buildcmd_files(function (target, batchcmds, sourcebatch, opt)
        import("verilator").buildcmd_cppfiles(target, batchcmds, sourcebatch, opt)
    end)

rule("verilator.static")
    add_deps("c++")
    set_extensions(".v", ".sv")
    on_load(function (target)
        target:set("kind", "static")
    end)

    on_config(function (target)
        import("verilator").config(target)
    end)

    before_build_files(function (target, sourcebatch)
        -- Just to avoid before_buildcmd_files being executed at build time
    end)

    on_build_files(function (target, batchjobs, sourcebatch, opt)
        import("verilator").build_cppfiles(target, batchjobs, sourcebatch, opt)
    end, {batch = true, distcc = true})

    before_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        import("verilator").buildcmd_vfiles(target, batchcmds, sourcebatch, opt)
    end)

    on_buildcmd_files(function (target, batchcmds, sourcebatch, opt)
        import("verilator").buildcmd_cppfiles(target, batchcmds, sourcebatch, opt)
    end)

rule("verilator.shared")
    add_deps("c++")
    set_extensions(".v", ".sv")
    on_load(function (target)
        target:set("kind", "shared")
    end)

    on_config(function (target)
        import("verilator").config(target)
    end)

    before_build_files(function (target, sourcebatch)
        -- Just to avoid before_buildcmd_files being executed at build time
    end)

    on_build_files(function (target, batchjobs, sourcebatch, opt)
        import("verilator").build_cppfiles(target, batchjobs, sourcebatch, opt)
    end, {batch = true, distcc = true})

    before_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        import("verilator").buildcmd_vfiles(target, batchcmds, sourcebatch, opt)
    end)

    on_buildcmd_files(function (target, batchcmds, sourcebatch, opt)
        import("verilator").buildcmd_cppfiles(target, batchcmds, sourcebatch, opt)
    end)
