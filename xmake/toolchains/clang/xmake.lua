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
    set_kind("standalone")
    set_homepage("https://clang.llvm.org/")
    set_description("A C language family frontend for LLVM" .. (version and (" (" .. version .. ")") or ""))
    set_runtimes("c++_static", "c++_shared", "stdc++_static", "stdc++_shared")

    set_toolset("cc", "clang" .. suffix)
    set_toolset("cxx", "clang" .. suffix, "clang++" .. suffix)
    set_toolset("ld", "clang++" .. suffix, "clang" .. suffix)
    set_toolset("sh", "clang++" .. suffix, "clang" .. suffix)
    set_toolset("ar", "ar", "llvm-ar")
    set_toolset("strip", "strip", "llvm-strip")
    set_toolset("ranlib", "ranlib", "llvm-ranlib")
    set_toolset("objcopy", "objcopy", "llvm-objcopy")
    set_toolset("mm", "clang" .. suffix)
    set_toolset("mxx", "clang" .. suffix, "clang++" .. suffix)
    set_toolset("as", "clang" .. suffix)
    set_toolset("mrc", "llvm-rc")

    on_check(function (toolchain)
        if toolchain:is_plat("windows") then
            local rootdir = path.join(path.directory(os.scriptdir()), "clang")
            local result = import("check", {rootdir = rootdir})(toolchain, suffix)
            if result then
                return result
            end
        end

        return import("lib.detect.find_tool")("clang" .. suffix)
    end)

    on_load(function (toolchain)
        import("core.project.project")

        if project.policy("build.optimization.lto") then
            toolchain:set("toolset", "ar",  "llvm-ar" .. suffix)
            toolchain:set("toolset", "ranlib",  "llvm-ranlib" .. suffix)
        end

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
        if toolchain:is_plat("windows") then
            toolchain:add("runtimes", "MT", "MTd", "MD", "MDd")
        end
        if toolchain:is_plat("windows", "mingw") then
            local rootdir = path.join(path.directory(os.scriptdir()), "clang")
            import("load", {rootdir = rootdir})(toolchain, suffix)
        end
    end)
end
toolchain_clang()
