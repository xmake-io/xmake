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

-- define platform
platform("wasm")

    -- set os
    set_os("web")

    -- set hosts
    set_hosts("macosx", "linux", "windows", "bsd")

    -- set archs
    set_archs("wasm32")

    -- set formats
    set_formats("static", "lib$(name).a")
    set_formats("object", "$(name).o")
    set_formats("shared", "lib$(name).so")
    set_formats("binary", "$(name).html")
    set_formats("symbol", "$(name).sym")

    -- set toolchains
    set_toolchains("emcc")

    -- set menu
    set_menu {
        config =
        {
            {category = "Emscripten Configuration"          }
        ,   {nil, "emsdk", "kv", nil, "The emsdk directory" }
        }
    ,   global =
        {
            {category = "Emscripten Configuration"          }
        ,   {nil, "emsdk", "kv", nil, "The emsdk directory" }
        }
    }


