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
import("lib.detect.find_file")
import("lib.detect.find_library")
import("detect.sdks.find_vcpkgdir")
import("core.project.config")
import("core.project.target")

-- find package from the brew package manager
--
-- @param name  the package name, e.g. zlib, pcre
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)

    -- attempt to find the vcpkg root directory
    local vcpkgdir = find_vcpkgdir(opt.vcpkgdir)
    if not vcpkgdir then
        return
    end

    -- fix name, e.g. ffmpeg[x264] as ffmpeg
    -- @see https://github.com/xmake-io/xmake/issues/925
    name = name:gsub("%[.-%]", "")

    -- get arch, plat and mode
    local arch = opt.arch
    local plat = opt.plat
    local mode = opt.mode
    if plat == "macosx" then
        plat = "osx"
    end
    if arch == "x86_64" then
        arch = "x64"
    end

    -- get the vcpkg installed directory
    local installdir = path.join(vcpkgdir, "installed")

    -- get the vcpkg info directory
    local infodir = path.join(installdir, "vcpkg", "info")

    -- find the package info file, e.g. zlib_1.2.11-3_x86-windows[-static].list
    local triplet = arch .. "-" .. plat
    local pkgconfigs = opt.pkgconfigs
    if plat == "windows" and pkgconfigs and pkgconfigs.shared ~= true then
        triplet = triplet .. "-static"
        assert(not pkgconfigs.vs_runtime or pkgconfigs.vs_runtime:startswith("MT"), "only support static libraries with /MT[d] for vcpkg!")
    end
    local infofile = find_file(format("%s_*_%s.list", name, triplet), infodir)

    -- save includedirs, linkdirs and links
    local result = nil
    local info = infofile and io.readfile(infofile) or nil
    if info then
        for _, line in ipairs(info:split('\n')) do
            line = line:trim()

            -- get includedirs
            if line:endswith("/include/") then
                result = result or {}
                result.includedirs = result.includedirs or {}
                table.insert(result.includedirs, path.join(installdir, line))
            end

            -- get linkdirs and links
            if (plat == "windows" and line:endswith(".lib")) or line:endswith(".a") then
                if line:find(triplet .. (mode == "debug" and "/debug" or "") .. "/lib/", 1, true) then
                    result = result or {}
                    result.links = result.links or {}
                    result.linkdirs = result.linkdirs or {}
                    result.libfiles = result.libfiles or {}
                    table.insert(result.linkdirs, path.join(installdir, path.directory(line)))
                    table.insert(result.links, target.linkname(path.filename(line)))
                    table.insert(result.libfiles, path.join(installdir, path.directory(line), path.filename(line)))
                end
            end

            -- add shared library directory (/bin/) to linkdirs for running with PATH on windows
            if plat == "windows" and line:endswith(".dll") then
                if line:find(plat .. (mode == "debug" and "/debug" or "") .. "/bin/", 1, true) then
                    result = result or {}
                    result.linkdirs = result.linkdirs or {}
                    result.libfiles = result.libfiles or {}
                    table.insert(result.linkdirs, path.join(installdir, path.directory(line)))
                    table.insert(result.libfiles, path.join(installdir, path.directory(line), path.filename(line)))
                end
            end
        end
    end

    -- save version
    if result and infofile then
        local infoname = path.basename(infofile)
        result.version = infoname:match(name .. "_(%d+%.?%d*%.?%d*.-)_" .. arch)
        if not result.version then
            result.version = infoname:match(name .. "_(%d+%.?%d*%.-)_" .. arch)
        end
    end
    return result
end

