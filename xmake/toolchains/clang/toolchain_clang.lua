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
-- @author      ruki, romeoxbm
-- @file        toolchain_clang.lua
--

-- define toolchain
function toolchain_clang(version)
    local suffix = version and ("-" .. version) or ""

    toolchain("clang" .. suffix)
        set_kind("standalone")
        set_homepage("https://clang.llvm.org/")
        set_description("A C language family frontend for LLVM" .. (version and (" (" .. version .. ")") or ""))

        set_toolset("cc",      "clang" .. suffix)
        set_toolset("cxx",     "clang++" .. suffix, "clang" .. suffix)
        set_toolset("ld",      "clang++" .. suffix, "clang" .. suffix)
        set_toolset("sh",      "clang++" .. suffix, "clang" .. suffix)
        set_toolset("ar",      "llvm-ar" .. suffix, "ar")
        set_toolset("strip",   "llvm-strip" .. suffix, "strip")
        set_toolset("ranlib",  "llvm-ranlib" .. suffix, "ranlib")
        set_toolset("objcopy", "llvm-objcopy" .. suffix, "objcopy")
        set_toolset("nm",      "llvm-nm" .. suffix, "nm")
        set_toolset("mm",      "clang" .. suffix)
        set_toolset("mxx",     "clang++" .. suffix, "clang" .. suffix)
        set_toolset("as",      "clang" .. suffix)
        set_toolset("mrc",     "llvm-rc" .. suffix)
        set_toolset("dlltool", "llvm-dlltool" .. suffix)
        if is_host("macosx") then
            set_toolset("dsymutil", "dsymutil")
        end

        on_check(function (toolchain)
            return import("check")(toolchain, suffix)
        end)

        on_load(function (toolchain)
            import("load")(toolchain, suffix)
        end)
end
