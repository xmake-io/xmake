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
-- @file        install_package.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- install package
--
-- @param name  the package name, e.g. pcre2, pcre2/libpcre2-8
-- @param opt   the options, e.g. {verbose = true}
--
-- @return      true or false
--
function main(name, opt)

    -- attempt to find vcpkg
    local vcpkg = find_tool("vcpkg")
    if not vcpkg then
        raise("vcpkg not found!")
    end

    -- get arch, plat and mode
    local arch = opt.arch
    local plat = opt.plat
    local mode = opt.mode

    -- mapping plat
    if plat == "macosx" then
        plat = "osx"
    end

    -- archs mapping for vcpkg
    local archs = {
        x86_64          = "x64",
        i386            = "x86",

        -- android: armeabi armeabi-v7a arm64-v8a x86 x86_64 mips mip64
        -- Offers a doc: https://github.com/microsoft/vcpkg/blob/master/docs/users/android.md
        ["armeabi-v7a"] = "arm",
        ["arm64-v8a"]   = "arm64",

        -- ios: arm64 armv7 armv7s i386
        armv7           = "arm",
        armv7s          = "arm",
        arm64           = "arm64",
    }
    -- mapping arch
    arch = archs[arch] or arch

    -- init triplet
    local triplet = arch .. "-" .. plat
    if opt.plat == "windows" and opt.shared ~= true then
        triplet = triplet .. "-static"
        if opt.vs_runtime and opt.vs_runtime:startswith("MD") then
            triplet = triplet .. "-md"
        end
    end

    -- init argv
    local argv = {"install", name .. ":" .. triplet}
    if option.get("diagnosis") then
        table.insert(argv, "--debug")
    end

    -- install package
    os.vrunv(vcpkg.program, argv)
end
