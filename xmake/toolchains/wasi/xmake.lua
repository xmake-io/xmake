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
-- @author      wsw0108
-- @file        xmake.lua
--

-- define toolchain
toolchain("wasi")

    -- set homepage
    set_homepage("https://github.com/WebAssembly/wasi-sdk")
    set_description("WASI-enabled WebAssembly C/C++ toolchain.")

    -- mark as standalone toolchain
    set_kind("standalone")

    -- set toolset
    set_toolset("cc",     "clang")
    set_toolset("cxx",    "clang", "clang++")
    set_toolset("cpp",    "clang -E")
    set_toolset("as",     "clang")
    set_toolset("ld",     "clang++", "clang")
    set_toolset("sh",     "clang++", "clang")
    set_toolset("ar",     "llvm-ar")
    set_toolset("ranlib", "llvm-ranlib")
    set_toolset("strip",  "llvm-strip")

    -- check toolchain
    on_check(function (toolchain)
        return import("lib.detect.find_tool")("clang", {paths = toolchain:bindir()})
    end)

    -- on load
    on_load(function (toolchain)

        local sdkdir = toolchain:sdkdir()
        local sysroot = path.join(sdkdir, "share", "wasi-sysroot")
        toolchain:add("cxflags", "--sysroot=" .. sysroot)
        toolchain:add("mxflags", "--sysroot=" .. sysroot)
        toolchain:add("ldflags", "--sysroot=" .. sysroot)
        toolchain:add("shflags", "--sysroot=" .. sysroot)

        -- add bin search library for loading some dependent .dll files windows
        local bindir = toolchain:bindir()
        if bindir and is_host("windows") then
            toolchain:add("runenvs", "PATH", bindir)
        end
    end)
