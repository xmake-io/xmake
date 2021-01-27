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

-- define toolchain
toolchain("zig")

    -- set homepage
    set_homepage("https://ziglang.org/")
    set_description("Zig Programming Language Compiler")

    -- mark as standalone toolchain
    set_kind("standalone")

    -- on load
    on_load(function (toolchain)

        -- set toolset
        -- we patch target to `zig cc` to fix has_flags. see https://github.com/xmake-io/xmake/issues/955#issuecomment-766929692
        local zig = get_config("zc") or "zig"
        toolchain:set("toolset", "cc",    zig .. " cc")
        toolchain:set("toolset", "cxx",   zig .. " c++")
        toolchain:set("toolset", "ld",    zig .. " c++")
        toolchain:set("toolset", "sh",    zig .. " c++")
        toolchain:set("toolset", "zc",   "$(env ZC)", zig)
        toolchain:set("toolset", "zcar", "$(env ZC)", zig)
        toolchain:set("toolset", "zcld", "$(env ZC)", zig)
        toolchain:set("toolset", "zcsh", "$(env ZC)", zig)

        -- init arch
        if toolchain:is_arch("arm64") then
            arch = "aarch64"
        elseif toolchain:is_arch("i386", "x86") then
            arch = "i386"
        else
            arch = "x86_64"
        end

        -- init target
        local target
        if toolchain:is_plat("macosx") then
            target = arch .. "-macos-gnu"
        elseif toolchain:is_plat("linux") then
            target = arch .. "-linux-gnu"
        elseif toolchain:is_plat("windows") then
            target = arch .. "-windows-msvc"
        elseif toolchain:is_plat("mingw") then
            target = arch .. "-windows-gnu"
        end
        if target then
            toolchain:add("cxflags", "-target", target)
            toolchain:add("shflags", "-target", target)
            toolchain:add("ldflags", "-target", target)
            toolchain:add("zcflags", "-target", target)
            toolchain:add("zcldflags", "-target", target)
            toolchain:add("zcshflags", "-target", target)
        end

        -- @see https://github.com/ziglang/zig/issues/5825
        if toolchain:is_plat("windows") then
            toolchain:add("zcldflags", "--subsystem console")
            toolchain:add("syslinks", "kernel32", "ntdll")
        end
    end)
