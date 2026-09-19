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
-- @author      karurochari
-- @file        xmake.lua
--

-- WASI (WebAssembly System Interface) target, distinct from the web/Emscripten
-- `wasm` platform: produces plain `.wasm` modules (command `_start` or reactor)
-- instead of Emscripten's HTML/JS harness.
platform("wasi")
    set_os("wasi")
    set_hosts("macosx", "linux", "windows", "bsd")
    set_archs("wasm32", "wasm64")

    set_formats("static", "lib$(name).a")
    set_formats("object", "$(name).o")
    set_formats("shared", "lib$(name).wasm")
    set_formats("binary", "$(name).wasm")
    set_formats("symbol", "$(name).sym")

    set_toolchains("zigcc")
