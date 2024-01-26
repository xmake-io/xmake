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

toolchain("xcode")
    set_kind("standalone")
    set_homepage("https://developer.apple.com/xcode/")
    set_description("Xcode IDE")
    set_runtimes("c++_static", "c++_shared", "stdc++_static", "stdc++_shared")

    on_check("check")
    on_load(function (toolchain)

        -- set toolset
        local arch              = toolchain:arch()
        local bindir            = toolchain:bindir()
        local appledev          = toolchain:config("appledev")
        local xc_clang          = bindir and path.join(bindir, "clang") or "clang"
        local xc_clangxx        = bindir and path.join(bindir, "clang++") or "clang++"
        local xc_ar             = bindir and path.join(bindir, "ar") or "ar"
        local xc_strip          = bindir and path.join(bindir, "strip") or "strip"
        local xc_swift_frontend = bindir and path.join(bindir, "swift-frontend") or "swift-frontend"
        local xc_swiftc         = bindir and path.join(bindir, "swiftc") or "swiftc"
        local xc_dsymutil       = bindir and path.join(bindir, "dsymutil") or "dsymutil"

        toolchain:set("toolset", "cc", xc_clang)
        toolchain:set("toolset", "cxx", xc_clang, xc_clangxx)
        toolchain:set("toolset", "ld", xc_clangxx, xc_clang)
        toolchain:set("toolset", "sh", xc_clangxx, xc_clang)
        toolchain:set("toolset", "ar", xc_ar)
        toolchain:set("toolset", "strip", xc_strip)
        toolchain:set("toolset", "dsymutil", xc_dsymutil, "dsymutil")
        toolchain:set("toolset", "mm", xc_clang)
        toolchain:set("toolset", "mxx", xc_clang, xc_clangxx)
        toolchain:set("toolset", "sc", xc_swift_frontend, "swift_frontend", xc_swiftc, "swiftc")
        toolchain:set("toolset", "scld", xc_swiftc, "swiftc")
        toolchain:set("toolset", "scsh", xc_swiftc, "swiftc")
        if arch then
            toolchain:set("toolset", "cpp", xc_clang .. " -arch " .. arch .. " -E")
        end
        if toolchain:is_plat("macosx") then
            toolchain:set("toolset", "as", xc_clang)
        elseif appledev == "simulator" or appledev == "catalyst" then
            toolchain:set("toolset", "as", xc_clang)
        else
            toolchain:set("toolset", "as", path.join(os.programdir(), "scripts", "gas-preprocessor.pl " .. xc_clang))
        end

        -- load configurations
        import("load_" .. toolchain:plat())(toolchain)
    end)
