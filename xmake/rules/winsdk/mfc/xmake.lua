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
-- @author      xigal
-- @file        xmake.lua
--

-- define rule: shared
rule("win.sdk.mfc.shared")

    -- add mfc base rule
    add_deps("win.sdk.mfc.env")

    -- after load
    after_load(function (target)

        -- apply mfc settings
        import("mfc").mfc_shared(target)
    end)

-- define rule: static
rule("win.sdk.mfc.static")

    -- add mfc base rule
    add_deps("win.sdk.mfc.env")

    -- after load
    after_load(function (target)

        -- apply mfc settings
        import("mfc").mfc_static(target)
    end)

-- define rule: sharedcapp
rule("win.sdk.mfc.shared_app")

    -- add mfc base rule
    add_deps("win.sdk.mfc.shared")

    -- after load
    after_load(function (target)

        -- set kind: binary
        target:set("kind", "binary")

        -- set entry
        target:add("ldflags", import("mfc").mfc_application_entry(target), {force = true})       
    end)

-- define rule: staticapp
rule("win.sdk.mfc.static_app")

    -- add mfc base rule
    add_deps("win.sdk.mfc.static")

    -- after load
    after_load(function (target)

        -- set kind: binary
        target:set("kind", "binary")

        -- set entry
        target:add("ldflags", import("mfc").mfc_application_entry(target), {force = true})
    end)