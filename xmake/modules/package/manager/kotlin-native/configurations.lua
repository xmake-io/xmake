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
-- @file        configurations.lua
--

-- get architecture for kotlin-native
function arch(arch)
    local archs = {
        x86_64          = "x64",
        i386            = "x86",
        ["armeabi-v7a"] = "arm32",
        ["arm64-v8a"]   = "arm64",
        armv7           = "arm32",
        armv7s          = "arm32"
    }
    return archs[arch] or arch
end

-- get platform for kotlin-native
function plat(plat)
    local plats = {
        macosx          = "macos",
        iphoneos        = "ios",
        appletvos       = "tvos",
        windows         = "mingw"
    }
    return plats[plat] or plat
end

-- get triplet
function triplet(plat, arch)
    return plat .. arch
end

-- get configurations
function main()
    return {
        repositories = {description = "set the maven repositories", default = {
            "https://repo.maven.apache.org/maven2"
        }}
    }
end

