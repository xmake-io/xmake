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
import("core.project.target")
import("lib.detect.find_tool")
import("private.core.base.is_cross")
import("package.manager.pkgconfig.find_package", {alias = "find_package_from_pkgconfig"})

-- find package
function _find_package(dpkg, name, opt)
    local result = nil
    local pkgconfig_files = {}
    local listinfo = try {function () return os.iorunv(dpkg.program, {"--listfiles", name}) end}
    if listinfo then
        for _, line in ipairs(listinfo:split('\n', {plain = true})) do
            line = line:trim()

            -- get includedirs
            local pos = line:find("include/", 1, true)
            if pos then
                -- we don't need to add includedirs, gcc/clang will use /usr/ as default sysroot
                result = result or {}
            end

            -- get pc files
            if line:find("/pkgconfig/", 1, true) and line:endswith(".pc") then
                table.insert(pkgconfig_files, line)
            end

            -- get linkdirs and links
            if line:endswith(".a") or line:endswith(".so") then
                result = result or {}
                result.links = result.links or {}
                result.linkdirs = result.linkdirs or {}
                result.libfiles = result.libfiles or {}
                if line:endswith(".a") then
                    result.static = true
                else
                    result.shared = true
                end
                table.insert(result.linkdirs, path.directory(line))
                table.insert(result.links, target.linkname(path.filename(line), {plat = opt.plat}))
                table.insert(result.libfiles, path.join(path.directory(line), path.filename(line)))
            end
        end
    end

    -- we iterate over each pkgconfig file to extract the required data
    local foundpc = false
    local pcresult = {includedirs = {}, linkdirs = {}, links = {}, libfiles = {}}
    for _, pkgconfig_file in ipairs(pkgconfig_files) do
        local pkgconfig_dir = path.directory(pkgconfig_file)
        local pkgconfig_name = path.basename(pkgconfig_file)
        local pcinfo = find_package_from_pkgconfig(pkgconfig_name, {configdirs = pkgconfig_dir, linkdirs = linkdirs})

        -- the pkgconfig file has been parse successfully
        if pcinfo then
            for _, includedir in ipairs(pcinfo.includedirs) do
                table.insert(pcresult.includedirs, includedir)
            end
            for _, linkdir in ipairs(pcinfo.linkdirs) do
                table.insert(pcresult.linkdirs, linkdir)
            end
            for _, link in ipairs(pcinfo.links) do
                table.insert(pcresult.links, link)
            end
            if not result or not result.libfiles then
                for _, libfile in ipairs(pcinfo.libfiles) do
                    table.insert(pcresult.libfiles, libfile)
                end
                pcresult.static = pcinfo.static
                pcresult.shared = pcinfo.shared
            end
            -- version should be the same if a pacman package contains multiples .pc
            pcresult.version = pcinfo.version
            foundpc = true
        end
    end
    if foundpc == true then
        pcresult.includedirs = table.unique(pcresult.includedirs)
        pcresult.linkdirs = table.unique(pcresult.linkdirs)
        pcresult.libfiles = table.unique(pcresult.libfiles)
        pcresult.links = table.reverse_unique(pcresult.links)
        result = pcresult
    end

    -- meta/alias package? e.g. libboost-dev -> libboost1.74-dev
    -- @see https://github.com/xmake-io/xmake/issues/1786
    if not result then
        local statusinfo = try {function () return os.iorunv(dpkg.program, {"--status", name}) end}
        if statusinfo then
            for _, line in ipairs(statusinfo:split("\n", {plain = true})) do
                -- parse depends, e.g. Depends: libboost1.74-dev, libomp-14-dev (>= 14~)
                if line:startswith("Depends:") then
                    local depends = line:sub(9):gsub("%(.-%)", ""):split("%s+")
                    if #depends == 1 then
                        return _find_package(dpkg, depends[1], opt)
                    end
                    break
                end
            end
        end
    end

    if result then
        if result.links then
            result.links = table.unique(result.links)
            if #result.links == 0 then
                result.links = nil
            end
        end
        if result.linkdirs then
            result.linkdirs = table.unique(result.linkdirs)
            if #result.linkdirs == 0 then
                result.linkdirs = nil
            end
        end
        if result.includedirs then
            result.includedirs = table.unique(result.includedirs)
            if #result.includedirs == 0 then
                result.includedirs = nil
            end
        end
        if result.libfiles then
            result.libfiles = table.unique(result.libfiles)
            if #result.libfiles == 0 then
                result.libfiles = nil
            end
        end
    end
    return result
end

-- find package using the dpkg package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.0")
--
function main(name, opt)
    opt = opt or {}
    if is_cross(opt.plat, opt.arch) then
        return
    end

    local dpkg = find_tool("dpkg")
    if not dpkg then
        return
    end
    return _find_package(dpkg, name, opt)
end
