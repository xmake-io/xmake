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

-- define rule: umdf driver
rule("wdk.umdf.driver")

    -- add rules
    add_deps("wdk.inf", "wdk.man")

    -- on load
    on_load(function (target)
        import("load").umdf_driver(target)
    end)

-- define rule: umdf binary
rule("wdk.umdf.binary")

    -- add rules
    add_deps("wdk.inf", "wdk.man")

    -- on load
    on_load(function (target)
        import("load").umdf_binary(target)
    end)

-- define rule: kmdf driver
rule("wdk.kmdf.driver")

    -- add rules
    add_deps("wdk.inf", "wdk.man")

    -- on load
    on_load(function (target)
        import("load").kmdf_driver(target)
    end)

-- define rule: kmdf binary
rule("wdk.kmdf.binary")

    -- add rules
    add_deps("wdk.inf", "wdk.man")

    -- on load
    on_load(function (target)
        import("load").kmdf_binary(target)
    end)

    -- after build
    after_build(function (target)

        -- imports
        import("core.project.config")

        -- get wdk
        local wdk = target:data("wdk")

        -- copy wdf redist dll libraries (WdfCoInstaller01011.dll, ..) to the target directory
        os.cp(path.join(wdk.sdkdir, "Redist", "wdf", config.arch(), "*.dll"), target:targetdir())

        -- add clean files
        target:data_add("wdk.cleanfiles", os.files(path.join(target:targetdir(), "*.dll")))
    end)

