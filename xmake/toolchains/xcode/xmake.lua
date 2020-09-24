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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define toolchain
toolchain("xcode")

    -- set homepage
    set_homepage("https://developer.apple.com/xcode/")
    set_description("Xcode IDE")

    -- mark as standalone toolchain
    set_kind("standalone")

    -- check toolchain
    on_check("check")

    -- load toolchain
    on_load(function (toolchain)

        -- get cross
        local cross, arch, simulator
        if toolchain:is_plat("macosx") then
            cross = "xcrun -sdk macosx "
        elseif toolchain:is_plat("iphoneos") then
            arch = toolchain:arch()
            simulator = (arch == "i386" or arch == "x86_64")
            cross = simulator and "xcrun -sdk iphonesimulator " or "xcrun -sdk iphoneos "
        elseif toolchain:is_plat("watchos") then
            arch = toolchain:arch()
            simulator = (arch == "i386")
            cross = simulator and "xcrun -sdk watchsimulator " or "xcrun -sdk watchos "
        else
            raise("unknown platform for xcode!")
        end

        -- set toolset
        toolchain:set("toolset", "cc", cross .. "clang")
        toolchain:set("toolset", "cxx", cross .. "clang", cross .. "clang++")
        toolchain:set("toolset", "ld", cross .. "clang++", cross .. "clang")
        toolchain:set("toolset", "sh", cross .. "clang++", cross .. "clang")
        toolchain:set("toolset", "ar", cross .. "ar")
        toolchain:set("toolset", "ex", cross .. "ar")
        toolchain:set("toolset", "strip", cross .. "strip")
        toolchain:set("toolset", "dsymutil", cross .. "dsymutil", "dsymutil")
        toolchain:set("toolset", "mm", cross .. "clang")
        toolchain:set("toolset", "mxx", cross .. "clang", cross .. "clang++")
        toolchain:set("toolset", "sc", cross .. "swiftc", "swiftc")
        toolchain:set("toolset", "scld", cross .. "swiftc", "swiftc")
        toolchain:set("toolset", "scsh", cross .. "swiftc", "swiftc")
        if arch then
            toolchain:set("toolset", "cpp", cross .. "clang -arch " .. arch .. " -E")
        end
        if toolchain:is_plat("macosx") then
            toolchain:set("toolset", "as", cross .. "clang")
        elseif simulator then
            toolchain:set("toolset", "as", cross .. "clang")
        else
            toolchain:set("toolset", "as", path.join(os.programdir(), "scripts", "gas-preprocessor.pl " .. cross) .. "clang")
        end

        -- load configurations
        import("load_" .. toolchain:plat())(toolchain)
    end)
