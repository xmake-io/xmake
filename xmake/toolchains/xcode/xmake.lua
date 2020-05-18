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

    -- check toolchain
    on_check("check")

    -- load toolchain
    on_load(function (toolchain)

        -- get cross
        local cross, arch, simulator
        if is_plat("macosx") then
            cross = "xcrun -sdk macosx "
        elseif is_plat("iphoneos") then
            arch = get_config("arch") or os.arch()
            simulator = (arch == "i386" or arch == "x86_64")
            cross = simulator and "xcrun -sdk iphonesimulator " or "xcrun -sdk iphoneos "
        elseif is_plat("watchos") then
            arch = get_config("arch") or os.arch()
            simulator = (arch == "i386")
            cross = simulator and "xcrun -sdk watchsimulator " or "xcrun -sdk watchos "
        else
            raise("unknown platform for xcode!")
        end

        -- set toolsets
        toolchain:set("toolsets", "cc", cross .. "clang")
        toolchain:set("toolsets", "cxx", cross .. "clang", cross .. "clang++")
        toolchain:set("toolsets", "ld", cross .. "clang++", cross .. "clang")
        toolchain:set("toolsets", "sh", cross .. "clang++", cross .. "clang")
        toolchain:set("toolsets", "ar", cross .. "ar")
        toolchain:set("toolsets", "ex", cross .. "ar")
        toolchain:set("toolsets", "strip", cross .. "strip")
        toolchain:set("toolsets", "dsymutil", cross .. "dsymutil", "dsymutil")
        toolchain:set("toolsets", "mm", cross .. "clang")
        toolchain:set("toolsets", "mxx", cross .. "clang", cross .. "clang++")
        toolchain:set("toolsets", "sc", cross .. "swiftc", "swiftc")
        toolchain:set("toolsets", "scld", cross .. "swiftc", "swiftc")
        toolchain:set("toolsets", "scsh", cross .. "swiftc", "swiftc")
        if arch then
            toolchain:set("toolsets", "cpp", cross .. "clang -arch " .. arch .. " -E")
        end
        if is_plat("macosx") then
            toolchain:set("toolsets", "as", cross .. "clang")
        elseif simulator then
            toolchain:set("toolsets", "as", cross .. "clang")
        else
            toolchain:set("toolsets", "as", path.join(os.programdir(), "scripts", "gas-preprocessor.pl " .. cross) .. "clang")
        end

        -- load configurations
        import("load_" .. get_config("plat"))(toolchain)
    end)
