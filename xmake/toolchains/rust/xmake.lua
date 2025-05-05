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
        local target
        if toolchain:is_arch("x86_64", "x64") then
            target = "x86_64"
        elseif toolchain:is_arch("i386", "x86", "i686") then
            target = "i686"
        elseif toolchain:is_arch("arm64", "aarch64", "arm64-v8a") then
            target = "aarch64"
        elseif toolchain:is_arch("armeabi-v7a", "armv7-a") then
            target = "armv7"
        elseif toolchain:is_arch("armeabi", "armv5te") then
            target = "arm"
        elseif toolchain:is_arch("wasm32") then
            target = "wasm32"
        elseif toolchain:is_arch("wasm64") then
            target = "wasm64"
        end

        if target then
            if toolchain:is_plat("windows") then
                target = target .. "-pc-windows-msvc"
            elseif toolchain:is_plat("mingw") then
                target = target .. "-pc-windows-gnu"
            elseif toolchain:is_plat("linux") then
                target = target .. "-unknown-linux-gnu"
            elseif toolchain:is_plat("macosx") then
                target = target .. "-apple-darwin"
            elseif toolchain:is_plat("android") then
                target = target .. "-linux-"
                if toolchain:is_arch("armeabi-v7a", "armeabi", "armv7-a", "armv5te") then
                    target = target .. "androideabi"
                else
                    target = target .. "android"
                end
            elseif toolchain:is_plat("iphoneos", "appletvos", "watchos") then
                if toolchain:is_plat("iphoneos") then
                    target = target .. "-apple-ios"
                elseif toolchain:is_plat("appletvos") then
                    target = target .. "-apple-tvos"
                elseif toolchain:is_plat("watchos") then
                    target = target .. "-apple-watchos"
                end
                if toolchain:config("appledev") == "simulator" then
                    target = target .. "-sim"
                end
            elseif toolchain:is_plat("bsd") then
                target = target .. "-unknown-freebsd"
            elseif toolchain:is_plat("wasm") then
                target = target .. "-unknown-unknown"
            end 
        end

        if target then
            toolchain:add("rcflags", "--target=" .. target)
        else
            toolchain:set("rcshflags", "")
            toolchain:set("rcldflags", "")
        end
    end)
