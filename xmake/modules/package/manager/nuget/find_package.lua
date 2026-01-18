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
-- Copyright (C) 2015-present, Xmake Open Source Community.
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

-- check if pattern matches as a complete path component
-- e.g. "x86" should match "/x86/" but not "/x86_64/"
function _match_path_component(file_lower, pattern)
    local s, e = file_lower:find(pattern, 1, true)
    while s do
        -- check boundary: start of string or path separator before
        local before_ok = (s == 1) or file_lower:sub(s - 1, s - 1):match("[/\\]")
        -- check boundary: end of string or path separator after
        local after_ok = (e == #file_lower) or file_lower:sub(e + 1, e + 1):match("[/\\]")
        if before_ok and after_ok then
            return true
        end
        -- continue searching from next position
        s, e = file_lower:find(pattern, e + 1, true)
    end
    return false
end

-- match library file by analyzing path components
-- returns match score (higher is better), 0 means no match
function _match_libfile(file, libarch, toolset, libmode, runtime)
    -- architecture aliases for matching
    local arch_patterns = {
        x64 = {"x64", "amd64", "x86_64"},
        Win32 = {"win32", "x86", "i386", "i686"},
        arm64 = {"arm64", "aarch64"},
    }
    local target_archs = arch_patterns[libarch] or {libarch:lower()}

    -- check if file path contains target architecture
    local file_lower = file:lower()
    local has_arch = false
    for _, arch_name in ipairs(target_archs) do
        if _match_path_component(file_lower, arch_name) then
            has_arch = true
            break
        end
    end

    -- check if file contains other architecture (should exclude)
    for arch, patterns in pairs(arch_patterns) do
        if arch ~= libarch then
            for _, p in ipairs(patterns) do
                if _match_path_component(file_lower, p) then
                    return 0 -- contains wrong architecture
                end
            end
        end
    end

    -- calculate match score based on path components
    local score = has_arch and 10 or 1
    if toolset and file_lower:find(toolset:lower(), 1, true) then
        score = score + 4
    end
    if file_lower:find(libmode:lower(), 1, true) then
        score = score + 2
    end
    if file_lower:find(runtime:lower(), 1, true) then
        score = score + 1
    end
    return score
end

-- find native package files
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
        local runtime = assert(runtimes[configs.runtimes], "unknown runtimes %s", configs.runtimes)
        local toolset = toolchain_utils.get_vs_toolset_ver(toolchain.load("msvc", {plat = plat, arch = arch}):config("vs_toolset") or config.get("vs_toolset"))
        local libarch = libarchs[arch] or "x64"
        local libmode = configs.debug and "Debug" or "Release"
        for _, file in ipairs(libinfo.files) do
            local filepath = path.join(installdir, file)
            file = file:trim()

            -- get includedirs
            -- support multiple include directory patterns:
            -- e.g. build/native/include/*.h, build/native/include-winrt/*.h
            if file:endswith(".h") or file:endswith(".hpp") or file:endswith(".hxx") then
                local dir = path.directory(file)
                if dir and (dir:find("include", 1, true) or dir:find("inc", 1, true)) then
                    result.includedirs = result.includedirs or {}
                    table.insert(result.includedirs, path.join(installdir, dir))
                end
            end

            -- get linkdirs and links
            -- use score-based matching to support various directory structures
            if file:endswith(".lib") then
                local score = _match_libfile(file, libarch, toolset, libmode, runtime)
                if score > 0 then
                    local libname = path.filename(filepath)
                    -- check if we already have this lib with a better match
                    result._libscores = result._libscores or {}
                    local existing_score = result._libscores[libname] or 0
                    if score > existing_score then
                        -- remove old entry if exists
                        if existing_score > 0 then
                            for i, v in ipairs(result.links or {}) do
                                if target.linkname(libname, {plat = plat}) == v then
                                    table.remove(result.links, i)
                                    table.remove(result.linkdirs, i)
                                    table.remove(result.libfiles, i)
                                    break
                                end
                            end
                        end
                        result.links = result.links or {}
                        result.linkdirs = result.linkdirs or {}
                        result.libfiles = result.libfiles or {}
                        table.insert(result.linkdirs, path.directory(filepath))
                        table.insert(result.links, target.linkname(libname, {plat = plat}))
                        table.insert(result.libfiles, filepath)
                        result._libscores[libname] = score
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
        -- clean up internal scoring data
        result._libscores = nil
        if result.links or result.includedirs then
            -- deduplicate paths
            if result.includedirs then
                result.includedirs = table.unique(result.includedirs)
            end
            if result.linkdirs then
                result.linkdirs = table.unique(result.linkdirs)
            end
            return result
        end
    end
end


