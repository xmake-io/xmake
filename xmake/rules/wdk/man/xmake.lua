--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define rule: *.man
rule("wdk.man")

    -- add rule: wdk environment
    add_deps("wdk.env")

    -- set extensions
    set_extensions(".man")

    -- on load
    on_load(function (target)

        -- imports
        import("core.project.config")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")
        
        -- get ctrpp
        local ctrpp = path.join(target:data("wdk").bindir, arch, is_host("windows") and "ctrpp.exe" or "ctrpp")
        assert(ctrpp and os.isexec(ctrpp), "ctrpp not found!")
        
        -- save uic
        target:data_set("wdk.ctrpp", ctrpp)
    end)

    -- before build file
    before_build_file(function (target, sourcefile, opt)

        -- imports
        import("core.base.option")
        import("core.project.depend")

        -- trace progress info
        if option.get("verbose") then
            cprint("${green}[%02d%%]:${dim} compiling.wdk.man %s", opt.progress, sourcefile)
        else
            cprint("${green}[%02d%%]:${clear} compiling.wdk.man %s", opt.progress, sourcefile)
        end

    end)

