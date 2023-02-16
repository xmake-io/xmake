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
import("core.project.config")
import("core.project.target")
import("detect.sdks.find_vcpkgdir")
import("package.manager.vcpkg.configurations")
import("package.manager.pkgconfig.find_package", {alias = "find_package_from_pkgconfig"})

-- we iterate over each pkgconfig file to extract the required data
function _find_package_from_pkgconfig(pkgconfig_files, opt)
    opt = opt or {}
    local foundpc = false
    local result = {includedirs = {}, linkdirs = {}, links = {}}
    for _, pkgconfig_file in ipairs(pkgconfig_files) do
        local pkgconfig_dir = path.join(opt.installdir, path.directory(pkgconfig_file))
        local pkgconfig_name = path.basename(pkgconfig_file)
        local pcresult = find_package_from_pkgconfig(pkgconfig_name, {configdirs = pkgconfig_dir, linkdirs = opt.linkdirs})

        -- the pkgconfig file has been parse successfully
        if pcresult then
            for _, includedir in ipairs(pcresult.includedirs) do
                table.insert(result.includedirs, includedir)
            end
            for _, linkdir in ipairs(pcresult.linkdirs) do
                table.insert(result.linkdirs, linkdir)
            end
            for _, link in ipairs(pcresult.links) do
                table.insert(result.links, link)
            end
            -- version should be the same if a pacman package contains multiples .pc
            result.version = pcresult.version
            foundpc = true
        end
    end

    if foundpc == true then
        result.includedirs = table.unique(result.includedirs)
        result.linkdirs = table.unique(result.linkdirs)
        result.links = table.reverse_unique(result.links)
        return result
    end
end

function _find_package(vcpkgdir, name, opt)

    -- get configs
    local configs = opt.configs or {}

    -- fix name, e.g. ffmpeg[x264] as ffmpeg
    -- @see https://github.com/xmake-io/xmake/issues/925
    name = name:gsub("%[.-%]", "")

    -- init triplet
    local arch = opt.arch
    local plat = opt.plat
    local mode = opt.mode
    plat = configurations.plat(plat)
    arch = configurations.arch(arch)
    local triplet = configurations.triplet(configs, plat, arch)

    -- get the vcpkg info directories
    local infodirs = {}
	if opt.installdir then
        table.join2(infodirs, path.join(opt.installdir, "vcpkg_installed", "vcpkg", "info"))
	end
    table.join2(infodirs, path.join(vcpkgdir, "installed", "vcpkg", "info"))

    -- find the package info file, e.g. zlib_1.2.11-3_x86-windows[-static].list
    local infofile = find_file(format("%s_*_%s.list", name, triplet), infodirs)
    if not infofile then
        return
    end
    local installdir = path.directory(path.directory(path.directory(infofile)))

    -- save includedirs, linkdirs and links
    local result = nil
    local pkgconfig_files = {}
    local info = io.readfile(infofile)
    if info then
        for _, line in ipairs(info:split('\n')) do
            line = line:trim()
            if plat == "windows" then
                line = line:lower()
            end

            -- get pkgconfig files
            if line:find(triplet .. (mode == "debug" and "/debug" or "") .. "/lib/pkgconfig/", 1, true) and line:endswith(".pc") then
                table.insert(pkgconfig_files, line)
            end

            -- get includedirs
            if line:endswith("/include/") then
                result = result or {}
                result.includedirs = result.includedirs or {}
                table.insert(result.includedirs, path.join(installdir, line))
            end

            -- get linkdirs and links
            if (plat == "windows" and line:endswith(".lib")) or line:endswith(".a") or line:endswith(".so") then
                if line:find(triplet .. (mode == "debug" and "/debug" or "") .. "/lib/", 1, true) then
                    result = result or {}
                    result.links = result.links or {}
                    result.linkdirs = result.linkdirs or {}
                    result.libfiles = result.libfiles or {}
                    table.insert(result.linkdirs, path.join(installdir, path.directory(line)))
                    table.insert(result.links, target.linkname(path.filename(line), {plat = plat}))
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

    -- find result from pkgconfig first
    if #pkgconfig_files > 0 then
        local pkgconfig_result = _find_package_from_pkgconfig(pkgconfig_files, {installdir = installdir, linkdirs = result and result.linkdirs})
        if pkgconfig_result then
            result = pkgconfig_result
        end
    end

    -- save version
    if result then
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

-- find package from the vcpkg package manager
--
-- @param name  the package name, e.g. zlib, pcre
-- @param opt   the options, e.g. {verbose = true)
--
function main(name, opt)

    -- attempt to find vcpkg directory
    local vcpkgdir = find_vcpkgdir()
    if not vcpkgdir then
        if option.get("diagnosis") then
            cprint("${color.warning}checkinfo: ${clear dim}vcpkg root directory not found, maybe you need set $VCPKG_ROOT!")
        end
        return
    end

    -- do find package
    return _find_package(vcpkgdir, name, opt)
end
