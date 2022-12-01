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

-- get architecture for vcpkg
function arch(arch)
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
    return archs[arch] or arch
end

-- get platform for vcpkg
function plat(plat)
    local plats = {
        macosx          = "osx",
        bsd             = "freebsd",
    }
    return plats[plat] or plat
end

-- get triplet
function triplet(configs, plat, arch)
    configs = configs or {}
    local triplet = arch .. "-" .. plat
    if plat == "windows" and configs.shared ~= true then
        triplet = triplet .. "-static"
        if configs.vs_runtime and configs.vs_runtime:startswith("MD") then
            triplet = triplet .. "-md"
        end
    elseif plat == "mingw" then
        triplet = triplet .. (configs.shared ~= true and "-static" or "-dynamic")
    end
    return triplet
end

-- get configurations
function main()
    return {
        baseline           = {description = "set the builtin baseline."},
        features           = {description = "set the features of dependency."},
        default_features   = {description = "enables or disables any defaults provided by the dependency.", default = true},
        registries         = {description = "set the registries in vcpkg-configuration.json"},
        default_registries = {description = "set the default registries in vcpkg-configuration.json"}
    }
end

