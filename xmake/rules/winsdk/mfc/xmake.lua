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
-- @author      xigal, ruki
-- @file        xmake.lua
--

-- define rule: the mfc shared library
rule("win.sdk.mfc.shared")

    -- add mfc base rule
    add_deps("win.sdk.mfc.env")

    -- after load
    after_load(function (target)
        import("mfc").library(target, "shared")
    end)

-- define rule: the mfc static library
rule("win.sdk.mfc.static")

    -- add mfc base rule
    add_deps("win.sdk.mfc.env")

    -- after load
    after_load(function (target)
        import("mfc").library(target, "static")
    end)

-- define rule: the application with shared mfc libraries
rule("win.sdk.mfc.shared_app")

    -- add mfc base rule
    add_deps("win.sdk.mfc.env")

    -- after load
    after_load(function (target)
        import("mfc").application(target, "shared")
    end)

-- define rule: the application with static mfc libraries
rule("win.sdk.mfc.static_app")

    -- add mfc base rule
    add_deps("win.sdk.mfc.env")

    -- after load
    after_load(function (target)
        import("mfc").application(target, "static")
    end)
