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
-- @file        find_package.lua
--

-- imports
import("core.base.option")
import("core.project.config")

-- get build info file
function _conan_get_buildinfo_file(name)
    return path.absolute(path.join(config.buildir() or os.tmpdir(), ".conan", name, "conanbuildinfo.xmake.lua"))
end

-- get conan platform
function _conan_get_plat(opt)
    local plats = {macosx = "Macos", windows = "Windows", mingw = "Windows", linux = "Linux", cross = "Linux", iphoneos = "iOS", android = "Android"}
    return plats[opt.plat]
end

-- get conan architecture
function _conan_get_arch(opt)
    local archs = {x86_64          = "x86_64",
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
                   mips64          = "mips64"}
    return archs[opt.arch]
end

-- get conan mode
function _conan_get_mode(opt)
    return opt.mode == "debug" and "Debug" or "Release"
end

-- find package using the conan package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)

    -- get the build info
    local buildinfo_file = _conan_get_buildinfo_file(name)
    if not os.isfile(buildinfo_file) then
        return
    end

    -- load build info
    local buildinfo = io.load(buildinfo_file)

    -- get platform, architecture and mode
    local plat = _conan_get_plat(opt)
    local arch = _conan_get_arch(opt)
    local mode = _conan_get_mode(opt)
    if not plat or not arch or not mode then
        return
    end

    -- get the package info of the given platform, architecture and mode
    local found = false
    local result = {}
    for k, v in pairs(buildinfo[plat .. "_" .. arch .. "_" .. mode]) do
        if #table.wrap(v) > 0 then
            result[k] = v
            found = true
        end
    end
    if found then
        for _, linkdir in ipairs(result.linkdirs) do
            if not os.isdir(linkdir) then
                return
            end
        end
        for _, includedir in ipairs(result.includedirs) do
            if not os.isdir(includedir) then
                return
            end
        end
        return result
    end
end
