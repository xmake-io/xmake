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
-- @author      ruki, Arthapz
-- @file        xmake.lua
--

-- define rule: c++.build.modules
rule("c++.build.modules")

    -- @note support.contains_modules() need it
    set_extensions(".cppm", ".ccm", ".cxxm", ".c++m", ".mpp", ".mxx", ".ixx")

    add_deps("c++.build.modules.scanner",
             "c++.build.modules.builder",
             "c++.build.modules.install")
    
    on_config(function (target)
        import("config")(target)
    end)

    after_config(function(target)
        import("config").insert_stdmodules(target)
    end)

rule("c++.build.modules.scanner")
    set_sourcekinds("cxx")
    set_extensions(".mpp", ".mxx", ".cppm", ".ixx")

    on_prepare_files(function(target, jobgraph, sourcebatch, opt)
        import("scanner")(target, jobgraph, sourcebatch, opt)
    end, {jobgraph = true})

    after_prepare_files(function(target)
        import("scanner").after_scan(target)
    end)

-- build modules
rule("c++.build.modules.builder")
    set_sourcekinds("cxx")
    set_extensions(".mpp", ".mxx", ".cppm", ".ixx")

    add_orders("c++.build.modules.scanner", "c++.build.modules.builder")
        
    -- parallel build support to accelerate `xmake build` to build modules
    before_build_files(function(target, jobgraph, sourcebatch, opt)
        import("builder").build_bmis(target, jobgraph, sourcebatch, opt)
    end, {jobgraph = true, batch = true})

    on_build_files(function(target, jobgraph, sourcebatch, opt)
        import("builder").build_objectfiles(target, jobgraph, sourcebatch, opt)
    end, {jobgraph = true, batch = true})
    
    -- serial compilation only, usually used to support project generator
    before_buildcmd_files(function(target, batchcmds, sourcebatch)
        import("builder").build_bmis(target, batchcmds, sourcebatch, opt)
    end)
    
    on_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        import("builder").build_objectfiles(target, batchcmds, sourcebatch, opt)
    end)

    after_clean(function (target)
        import("builder").clean(target)
    end)

-- install modules
rule("c++.build.modules.install")
    set_extensions(".mpp", ".mxx", ".cppm", ".ixx")

    before_install(function (target)
        import("install").install(target)
    end)

    before_uninstall(function (target)
        import("install").uninstall(target)
    end)
