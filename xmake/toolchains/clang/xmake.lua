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
function toolchain_clang(version)
local suffix = ""
if version then
    suffix = suffix .. "-" .. version
end
toolchain("clang" .. suffix)

    set_homepage("https://clang.llvm.org/")
    set_description("A C language family frontend for LLVM" .. (version and (" (" .. version .. ")") or ""))

    set_kind("standalone")

    set_toolset("cc", "clang" .. suffix)
    set_toolset("cxx", "clang" .. suffix, "clang++" .. suffix)
    set_toolset("ld", "clang++" .. suffix, "clang" .. suffix)
    set_toolset("sh", "clang++" .. suffix, "clang" .. suffix)
    set_toolset("ar", "ar")
    set_toolset("strip", "strip")
    set_toolset("mm", "clang" .. suffix)
    set_toolset("mxx", "clang" .. suffix, "clang++" .. suffix)
    set_toolset("as", "clang" .. suffix)
    set_toolset("mrc", "llvm-rc")

    on_check(function (toolchain)
        return import("lib.detect.find_tool")("clang" .. suffix)
    end)

    on_load(function (toolchain)
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

        local cxxstl = get_config("cxxstl")
        if cxxstl then
            assert(cxxstl == "msstl" or cxxstl == "libc++" or cxxstl == "libstdc++", "cxxstl option can only be libc++|libstdc++|msstl")
            assert((not is_plat("windows")) and cxxstl ~= "msstl", "msstl can only be used on windows plat")

            if cxxstl ~= "msstl" then
                toolchain:add("cxxflags", "-stdlib=" .. get_config("cxxstl"))
                toolchain:add("shflags", "-stdlib=" .. get_config("cxxstl"))
                toolchain:add("ldflags", "-stdlib=" .. get_config("cxxstl"))
                toolchain:add("mxxflags", "-stdlib=" .. get_config("cxxstl"))

                local sdkdir = toolchain:sdkdir()
                if cxxstl == "libc++" and sdkdir then
                    toolchain:add("cxxflags", "-isysroot=" .. sdkdir)
                    toolchain:add("mxxflags", "-isysroot=" .. sdkdir)
                end
            end
        end
    end)
end
toolchain_clang()
