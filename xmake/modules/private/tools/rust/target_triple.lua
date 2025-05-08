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
-- @author      SirLynix
-- @file        target_triple.lua
--

-- get arch part
function _translate_arch(arch, opt)
    local maps =
    {
        ["aarch64"]     = "aarch64"
    ,   ["armv5te"]     = "arm"
    ,   ["armeabi"]     = "arm"
    ,   ["armeabi-v7a"] = "armv7"
    ,   ["armv7-a"]     = "armv7"
    ,   ["arm64"]       = "aarch64"
    ,   ["arm64-v8a"]   = "aarch64"
    ,   ["i386"]        = "i686"
    ,   ["i686"]        = "i686"
    ,   ["x86"]         = "i686"
    ,   ["x86_64"]      = "x86_64"
    ,   ["x64"]         = "x86_64"
    ,   ["wasm32"]      = "wasm32"
    ,   ["wasm64"]      = "wasm64"
    }
    return maps[arch]
end

-- get platform part
function _translate_plat(plat, arch, opt)
    if plat == "windows" then
        return "-pc-windows-msvc"
    elseif plat == "mingw" then
        return "-pc-windows-gnu"
    elseif plat == "linux" then
        return "-unknown-linux-gnu"
    elseif plat == "macosx" then
        return "-apple-darwin"
    elseif plat == "android" then
        if arch == "armeabi-v7a" or arch == "armeabi" or arch == "armv7-a" or arch == "armv5te" then
            return "-linux-androideabi"
        else
            return "-linux-android"
        end
    elseif plat == "iphoneos" or plat == "appletvos" or plat == "watchos" then
        local suffix = opt and opt.apple_sim and "-sim" or ""
        if plat == "iphoneos" then
            return "-apple-ios" .. suffix
        elseif plat == "appletvos" then
            return "-apple-tvos" .. suffix
        elseif plat == "watchos" then
            return "-apple-watchos" .. suffix
        end
    elseif plat == "bsd" then
        return "-unknown-freebsd"
    elseif plat == "wasm" then
        return "-unknown-unknown"
    end
end

-- gets the rustc compatible target triple (e.g. x86_64-pc-windows-msvc) for a set plat/arch
--
-- @param plat      the target plat, e.g. windows, android, macosx, ...
-- @param arch      the target name, e.g. arm64, x86_64, wasm64, ...
-- @param opt       the options, e.g. {apple_sim = true)
--
-- @return          a valid rustc triple if plat and arch are recognized, nil otherwise
function main(plat, arch, opt)

    local target_arch = _translate_arch(arch, opt)
    if not target_arch then
        return
    end

    local target_plat = _translate_plat(plat, arch, opt)
    if not target_plat then
        return
    end

    return target_arch .. target_plat
end
