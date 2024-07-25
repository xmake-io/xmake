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
-- @file        find_package.lua
--

-- imports
import("core.base.option")
import("core.project.config")

-- get build info file
function _conan_get_buildinfo_file(name, dep_name)
    local filename = "conanbuildinfo.xmake.lua"
    if dep_name then
        filename = "conanbuildinfo_" .. dep_name .. ".xmake.lua"
    end
    return path.absolute(path.join(config.buildir() or os.tmpdir(), ".conan", name, filename))
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

-- get info key
function _conan_get_infokey(opt)
    local plat = _conan_get_plat(opt)
    local arch = _conan_get_arch(opt)
    local mode = _conan_get_mode(opt)
    if plat and arch and mode then
        return plat .. "_" .. arch .. "_" .. mode
    end
end

-- get build info
function _conan_get_buildinfo(name, opt)
    opt = opt or {}
    local buildinfo_file = _conan_get_buildinfo_file(name, opt.dep_name)
    if not os.isfile(buildinfo_file) then
        return
    end

    -- load build info
    local infokey = _conan_get_infokey(opt)
    if not infokey then
        return
    end
    local buildinfo = io.load(buildinfo_file)
    if buildinfo then
        buildinfo = buildinfo[infokey]
    end

    -- get the package info of the given platform, architecture and mode
    local found = false
    local result = {}
    local dep_names
    for k, v in pairs(buildinfo) do
        if not k:startswith("__") then
            if #table.wrap(v) > 0 then
                result[k] = v
                found = true
            end
        end
    end

    -- remove unused frameworks for linux
    -- @see https://github.com/xmake-io/xmake/issues/5358
    local plat = opt.plat
    if found and result and plat ~= "macosx" and plat ~= "iphoneos" then
        result.frameworks = nil
        result.frameworkdirs = nil
    end

    if found then
        return buildinfo, result
    end
end

-- find conan library
function _conan_find_library(name, opt)
    opt = opt or {}
    local buildinfo, result = _conan_get_buildinfo(name, opt)
    if result then
        local libfiles = {}
        for _, linkdir in ipairs(result.linkdirs) do
            for _, file in ipairs(os.files(path.join(linkdir, "*"))) do
                if file:endswith(".lib") or file:endswith(".a") then
                    result.static = true
                    table.insert(libfiles, file)
                elseif file:endswith(".so") or file:match(".+%.so%..+$") or file:endswith(".dylib") or file:endswith(".dll") then -- maybe symlink to libxxx.so.1
                    result.shared = true
                    table.insert(libfiles, file)
                end
            end
        end
        if opt.plat == "windows" or opt.plat == "mingw" then
            for _, bindir in ipairs(buildinfo.__bindirs) do
                for _, file in ipairs(os.files(path.join(bindir, "*.dll"))) do
                    result.shared = true
                    table.insert(libfiles, file)
                end
            end
        end
        for _, includedir in ipairs(result.includedirs) do
            if not os.isdir(includedir) then
                return
            end
        end
        local require_version = opt.require_version
        if require_version ~= nil and require_version ~= "latest" then
            result.version = opt.require_version
        end
        result.libfiles = table.unique(libfiles)
        return result, buildinfo.__dep_names
    end
end

-- find package using the conan package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true)
--
function main(name, opt)
    local result, dep_names = _conan_find_library(name, opt)
    if result and dep_names then
        for _, dep_name in ipairs(dep_names) do
            local depinfo = _conan_find_library(name, table.join(opt, {dep_name = dep_name}))
            for k, v in pairs(depinfo) do
                result[k] = table.join(result[k] or {}, v)
            end
        end
        for k, v in pairs(result) do
            if k == "links" or k == "syslinks" or k == "frameworks" then
                result[k] = table.unwrap(table.reverse_unique(v))
            else
                result[k] = table.unwrap(table.unique(v))
            end
        end
    end
    return result
end
