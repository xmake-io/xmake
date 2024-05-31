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

toolchain("rust")

    set_homepage("https://www.rust-lang.org/")
    set_description("Rust Programming Language Compiler")

    set_toolset("rc",   "$(env RC)", "rustc")
    set_toolset("rcld", "$(env RC)", "rustc")
    set_toolset("rcsh", "$(env RC)", "rustc")
    set_toolset("rcar", "$(env RC)", "rustc")

    on_load(function (toolchain)

        -- e.g. x86_64-pc-windows-msvc, aarch64-unknown-none
        local arch = toolchain:arch()
        if toolchain:is_plat("android") then
            local targets = {
                ["armv5te"]     = "arm-linux-androideabi" -- deprecated
            ,   ["armv7-a"]     = "arm-linux-androideabi" -- deprecated
            ,   ["armeabi"]     = "arm-linux-androideabi" -- removed in ndk r17
            ,   ["armeabi-v7a"] = "arm-linux-androideabi"
            ,   ["arm64-v8a"]   = "aarch64-linux-android"
            }
            if targets[arch] then
                arch = targets[arch]
            end
        end
        if arch and #arch:split("%-") > 1 then
            toolchain:add("rcflags", "--target=" .. arch)
        else
            toolchain:set("rcshflags", "")
            toolchain:set("rcldflags", "")
        end
    end)
