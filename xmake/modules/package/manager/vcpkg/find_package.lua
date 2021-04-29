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
import("lib.detect.find_library")
import("lib.detect.find_tool")
import("core.project.config")
import("core.project.target")

-- find vcpkg root directory
function _find_vcpkgdir()
    local vcpkgdir = _g.vcpkgdir
    if vcpkgdir == nil then
        local vcpkg = find_tool("vcpkg")
        if vcpkg then
            local dir = path.directory(vcpkg.program)
            if os.isdir(path.join(dir, "installed")) then
                vcpkgdir = dir
            elseif is_host("macosx", "linux") then
                local brew = find_tool("brew")
                if brew then
                    dir = try
                    {
                        function ()
                            return os.iorunv(brew.program, {"--prefix", "vcpkg"})
                        end
                    }
                end
                if dir then
                    dir = path.join(dir:trim(), "libexec")
                    if os.isdir(path.join(dir, "installed")) then
                        vcpkgdir = dir
                    end
                end

            end
        end
        _g.vcpkgdir = vcpkgdir or false
    end
    return vcpkgdir or nil
end

-- find package from the vcpkg package manager
--
-- @param name  the package name, e.g. zlib, pcre
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)

    -- attempt to find vcpkg directory
    local vcpkgdir = _find_vcpkgdir()
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

    -- get the vcpkg installed directory
    local installdir = path.join(vcpkgdir, "installed")

    -- get the vcpkg info directory
    local infodir = path.join(installdir, "vcpkg", "info")

    -- find the package info file, e.g. zlib_1.2.11-3_x86-windows[-static].list
    local triplet = arch .. "-" .. plat
    local pkgconfigs = opt.pkgconfigs
    if plat == "windows" and pkgconfigs and pkgconfigs.shared ~= true then
        triplet = triplet .. "-static"
        if pkgconfigs.vs_runtime and pkgconfigs.vs_runtime:startswith("MD") then
            triplet = triplet .. "-md"
        end
    end
    local infofile = find_file(format("%s_*_%s.list", name, triplet), infodir)

    -- save includedirs, linkdirs and links
    local result = nil
    local info = infofile and io.readfile(infofile) or nil
    if info then
        for _, line in ipairs(info:split('\n')) do
            line = line:trim()
            if plat == "windows" then
                line = line:lower()
            end

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

    -- remove repeat
    if result then
        if result.linkdirs then
            result.linkdirs = table.unique(result.linkdirs)
        end
        if result.includedirs then
            result.includedirs = table.unique(result.includedirs)
        end
    end
    return result
end

