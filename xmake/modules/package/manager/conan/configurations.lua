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

-- get arch for conan
function arch(arch)
    local map = {x86_64          = "x86_64",
                 x64             = "x86_64",
                 i386            = "x86",
                 x86             = "x86",
                 armv7           = "armv7",
                 ["armv7-a"]     = "armv7",  -- for android, deprecated
                 ["armeabi"]     = "armv7",  -- for android, removed in ndk r17
                 ["armeabi-v7a"] = "armv7",  -- for android
                 armv7s          = "armv7s", -- for iphoneos
                 arm64           = "armv8",  -- for iphoneos
                 ["arm64-v8a"]   = "armv8",  -- for android
                 mips            = "mips",
                 mips64          = "mips64",
                 wasm32          = "wasm"}
    return assert(map[arch], "unknown arch(%s)!", arch)
end

-- get os platform for conan
function plat(plat)
    local map = {macosx   = "Macos",
                 windows  = "Windows",
                 mingw    = "Windows",
                 linux    = "Linux",
                 cross    = "Linux",
                 iphoneos = "iOS",
                 android  = "Android",
                 wasm     = "Emscripten"}
    return assert(map[plat], "unknown os(%s)!", plat)
end

-- get build type
function build_type(mode)
    if mode == "debug" then
        return "Debug"
    else
        return "Release"
    end
end

-- get configurations
function main()
    return
    {
        build           = {description = "Use it to choose if you want to build from sources.", default = "missing", values = {"all", "never", "missing", "outdated"}},
        remote          = {description = "Set the conan remote server."},
        options         = {description = "Set the options values, e.g. shared=True"},
        settings        = {description = "Set the host settings for conan."},
        settings_host   = {description = "Set the host settings for conan."},
        settings_build  = {description = "Set the build settings for conan."},
        imports         = {description = "Set the imports for conan 1.x, it has been deprecated in conan 2.x."},
        build_requires  = {description = "Set the build requires for conan."},
        conf            = {description = "Set the host configurations for conan, e.g. tools.microsoft.bash:subsystem=msys2"},
        conf_host       = {description = "Set the host configurations for conan, e.g. tools.microsoft.bash:subsystem=msys2"},
        conf_build      = {description = "Set the build configurations for conan, e.g. tools.microsoft.bash:subsystem=msys2"},
    }
end

