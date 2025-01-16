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
import("lib.detect.find_file")
import("lib.detect.find_tool")
import("core.base.option")
import("core.base.json")
import("core.tool.toolchain")
import("core.project.config")
import("core.project.target")
import("private.utils.toolchain", {alias = "toolchain_utils"})

-- find native package files
-- e.g.
--[[
    "build/native/include/crc32.h",
    "build/native/include/deflate.h",
    "build/native/include/gzguts.h",
    "build/native/include/inffast.h",
    "build/native/include/inffixed.h",
    "build/native/include/inflate.h",
    "build/native/include/inftrees.h",
    "build/native/include/trees.h",
    "build/native/include/zconf.h",
    "build/native/include/zlib.h",
    "build/native/include/zutil.h",
    "build/native/lib/Win32/v140/Debug/zlib.lib",
    "build/native/lib/Win32/v140/Release/zlib.lib",
    "build/native/lib/Win32/v141/Debug/zlib.lib",
    "build/native/lib/Win32/v141/Release/zlib.lib",
    "build/native/lib/Win32/v142/Debug/MultiThreadedDebug/zlib.lib",
    "build/native/lib/Win32/v142/Debug/MultiThreadedDebugDLL/zlib.lib",
    "build/native/lib/Win32/v142/Release/MultiThreaded/zlib.lib",
    "build/native/lib/Win32/v142/Release/MultiThreadedDLL/zlib.lib",
    "build/native/lib/x64/v140/Debug/zlib.lib",
    "build/native/lib/x64/v140/Release/zlib.lib",
    "build/native/lib/x64/v141/Debug/zlib.lib",
    "build/native/lib/x64/v141/Release/zlib.lib",
    "build/native/lib/x64/v142/Debug/MultiThreadedDebug/zlib.lib",
    "build/native/lib/x64/v142/Debug/MultiThreadedDebugDLL/zlib.lib",
    "build/native/lib/x64/v142/Release/MultiThreaded/zlib.lib",
    "build/native/lib/x64/v142/Release/MultiThreadedDLL/zlib.lib",
]]
function _find_package(name, result, opt)
    local arch = opt.arch
    local plat = opt.plat
    local configs = opt.configs or {}
    local libinfo = opt.libraries[name]
    if libinfo then
        local libarchs = {x64 = "x64", x86 = "Win32", arm64 = "arm64"}
        local runtimes = {
            MT = "MultiThreaded",
            MTd = "MultiThreadedDebug",
            MD = "MultiThreadedDLL",
            MDd = "MultiThreadedDebugDLL"}
        local installdir = path.join(opt.packagesdir, name)
        local libdir = "build/native/lib"
        local runtime = assert(runtimes[configs.runtimes], "unknown runtimes %s", configs.runtimes)
        local toolset = toolchain_utils.get_vs_toolset_ver(toolchain.load("msvc", {plat = plat, arch = arch}):config("vs_toolset") or config.get("vs_toolset"))
        local libarch = libarchs[arch] or "x64"
        local libmode = configs.debug and "Debug" or "Release"
        for _, file in ipairs(libinfo.files) do
            local filepath = path.join(installdir, file)
            file = file:trim()

            -- get includedirs
            if file:find("/include/", 1, true) or file:startswith("include/") then
                result.includedirs = result.includedirs or {}
                table.insert(result.includedirs, path.join(installdir, "include"))
            end

            -- get linkdirs and links
            if file:endswith(".lib") then
                local searchdirs = {}
                table.insert(searchdirs, path.unix(path.join(libdir, libarch, toolset, libmode, runtime)))
                table.insert(searchdirs, path.unix(path.join(libdir, libarch)))
                for _, searchdir in ipairs(searchdirs) do
                    if file:startswith(searchdir .. "/") then
                        result.links = result.links or {}
                        result.linkdirs = result.linkdirs or {}
                        result.libfiles = result.libfiles or {}
                        table.insert(result.linkdirs, path.directory(filepath))
                        table.insert(result.links, target.linkname(path.filename(filepath), {plat = plat}))
                        table.insert(result.libfiles, filepath)
                    end
                end
            end
        end
    end
    local targetinfo = opt.targets[name]
    if targetinfo then
        local dependencies = targetinfo.dependencies
        if dependencies then
            for k, v in pairs(dependencies) do
                _find_package(k .. "/" .. v, result, opt)
            end
        end
    end
end

-- find package from the nuget package manager
--
-- @param name  the package name, e.g. zlib, pcre
-- @param opt   the options, e.g. {verbose = true)
--
function main(name, opt)
    opt = opt or {}

    -- load manifest info
    local installdir = assert(opt.installdir, "installdir not found!")
    local stubdir = path.join(installdir, "stub")
    local manifestfile = path.join(stubdir, "obj", "project.assets.json")
    if not os.isfile(manifestfile) then
        return
    end
    local manifest = json.loadfile(manifestfile)
    local targets
    for k, v in pairs(manifest.targets) do
        targets = v
        break
    end
    local target_root
    if targets then
        for k, v in pairs(targets) do
            if k:startswith(name) then
                target_root = k
                break
            end
        end
    end
    local metainfo = {}
    metainfo.plat = opt.plat
    metainfo.arch = opt.arch
    metainfo.mode = opt.mode
    metainfo.configs = opt.configs
    metainfo.targets = targets
    metainfo.libraries = manifest.libraries
    if manifest.project and manifest.project.restore then
        metainfo.packagesdir = manifest.project.restore.packagesPath
    end
    if target_root and metainfo.targets and metainfo.libraries and metainfo.packagesdir then
        local result = {}
        _find_package(target_root, result, metainfo)
        if result.links or result.includedirs then
            return result
        end
    end
end


