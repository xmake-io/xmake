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
function toolchain_gcc(version)
local suffix = ""
if version then
    suffix = suffix .. "-" .. version
end
toolchain("gcc" .. suffix)
    set_kind("standalone")
    set_homepage("https://gcc.gnu.org/")
    set_description("GNU Compiler Collection" .. (version and (" (" .. version .. ")") or ""))
    set_runtimes("stdc++_static", "stdc++_shared")

    -- set g++ first, then package:build_getenv("cxx") is always g++ instead of gcc
    -- see:https://github.com/xmake-io/xmake/issues/5518
    set_toolset("cc", "gcc" .. suffix)
    set_toolset("cxx", "g++" .. suffix, "gcc" .. suffix)
    set_toolset("ld", "g++" .. suffix, "gcc" .. suffix)
    set_toolset("sh", "g++" .. suffix, "gcc" .. suffix)
    set_toolset("ar", "ar")
    set_toolset("strip", "strip")
    set_toolset("objcopy", "objcopy")
    set_toolset("ranlib", "ranlib")
    set_toolset("mm", "gcc" .. suffix)
    set_toolset("mxx", "g++" .. suffix, "gcc" .. suffix)
    set_toolset("as", "gcc" .. suffix)

    on_check(function (toolchain)
        return import("lib.detect.find_tool")("gcc" .. suffix)
    end)

    on_load(function (toolchain)

        -- add march flags
        local march
        if toolchain:is_arch("x86_64", "x64") then
            march = "-m64"
        elseif toolchain:is_arch("i386", "x86") then
            march = "-m32"
        end
        if march then
            toolchain:add("cxflags", march)
            toolchain:add("mxflags", march)
            toolchain:add("asflags", march)
            toolchain:add("ldflags", march)
            toolchain:add("shflags", march)
        end
    end)
end
toolchain_gcc()
