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
import("core.project.target")
import("lib.detect.find_tool")
import("private.core.base.is_cross")
import("package.manager.pkgconfig.find_package", {alias = "find_package_from_pkgconfig"})
import("get_package_name")

-- find package from list of file inside pacman package
function _find_package_from_list(list, name, pacman, opt)

    -- mingw + pacman = cygpath available
    local cygpath = nil
    local pathtomsys = nil
    local msystem = nil
    if is_subhost("msys") and opt.plat == "mingw" then
        cygpath = find_tool("cygpath")
        if not cygpath then
            return
        end
        pathtomsys = os.iorunv(cygpath.program, {"--windows", "/"})
        pathtomsys = pathtomsys:trim()
        msystem = os.getenv("MSYSTEM")
        if msystem then
            msystem = msystem:lower()
        end
    end

    -- iterate over each file path inside the pacman package
    local result = {}
    for _, line in ipairs(list:split('\n', {plain = true})) do -- on msys cygpath should be used to convert local path to windows path
        line = line:trim():split('%s+')[2]
        if line:find("/include/", 1, true) and (line:endswith(".h") or line:endswith(".hpp")) then
            if not line:startswith("/usr/include/") then
                if not (msystem and line:startswith("/" .. msystem .. "/include/")) then
                    result.includedirs = result.includedirs or {}
                    local hpath = line
                    if is_subhost("msys") and opt.plat == "mingw" then
                        hpath = path.join(pathtomsys, line)
                        local basehpath = path.join(pathtomsys, msystem .. "/include")
                        table.insert(result.includedirs, basehpath)
                    end
                    table.insert(result.includedirs, path.directory(hpath))
                end
            end
        -- remove lib and .a, .dll.a and .so to have the links
        elseif line:endswith(".dll.a") then -- only for mingw
            local apath = path.join(pathtomsys, line)
            apath = apath:trim()
            result.linkdirs = result.linkdirs or {}
            result.links = result.links or {}
            table.insert(result.linkdirs, path.directory(apath))
            table.insert(result.links, target.linkname(path.filename(apath), {plat = opt.plat}))
        elseif line:endswith(".so") then
            result.linkdirs = result.linkdirs or {}
            result.links = result.links or {}
            table.insert(result.linkdirs, path.directory(line))
            table.insert(result.links, target.linkname(path.filename(line), {plat = opt.plat}))
        elseif line:endswith(".a") then
            result.linkdirs = result.linkdirs or {}
            result.links = result.links or {}
            local apath = line
            if is_subhost("msys") and opt.plat == "mingw" then
                apath = path.join(pathtomsys, line)
                apath = apath:trim()
            end
            table.insert(result.linkdirs, path.directory(apath))
            table.insert(result.links, target.linkname(path.filename(apath), {plat = opt.plat}))
        end
    end
    if result.includedirs then
        result.includedirs = table.unique(result.includedirs)
    end
    if result.linkdirs then
        result.linkdirs = table.unique(result.linkdirs)
    end
    if result.links then
        result.links = table.reverse_unique(result.links)
    end

    -- use pacman package version as version
    local version = try { function() return os.iorunv(pacman.program, {"-Q", name}) end }
    if version then
        version = version:trim():split('%s+')[2]
        -- we need strip "1:" prefix, @see https://github.com/xmake-io/xmake/issues/2020
        -- e.g. vulkan-headers 1:1.3.204-1
        if version:startswith("1:") then
            version = version:split(':')[2]
        end
        result.version = version:split('-')[1]
    else
        result = nil
    end
    return result
end

-- find libfiles from list of file inside pacman package
function _find_libfiles_from_list(list, name, pacman, opt)

    -- mingw + pacman = cygpath available
    local cygpath = nil
    local pathtomsys = nil
    if is_subhost("msys") and opt.plat == "mingw" then
        cygpath = find_tool("cygpath")
        if not cygpath then
            return
        end
        pathtomsys = os.iorunv(cygpath.program, {"--windows", "/"})
        pathtomsys = pathtomsys:trim()
    end

    -- iterate over each file path inside the pacman package
    local libfiles
    for _, line in ipairs(list:split('\n', {plain = true})) do -- on msys cygpath should be used to convert local path to windows path
        line = line:trim():split('%s+')[2]
        if line:endswith(".dll.a") then -- only for mingw
            local apath = path.join(pathtomsys, line)
            apath = apath:trim()
            libfiles = libfiles or {}
            table.insert(libfiles, apath)
        elseif line:endswith(".so") then
            libfiles = libfiles or {}
            table.insert(libfiles, line)
        elseif line:endswith(".a") then
            local apath = line
            if is_subhost("msys") and opt.plat == "mingw" then
                apath = path.join(pathtomsys, line)
                apath = apath:trim()
            end
            libfiles = libfiles or {}
            table.insert(libfiles, apath)
        end
    end
    return libfiles
end

-- find package from the system directories
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)
    opt = opt or {}
    if is_cross(opt.plat, opt.arch) then
        return
    end

    -- find pacman
    local pacman = find_tool("pacman")
    if not pacman then
        return
    end

    -- get package name
    name = get_package_name(name, opt)

    -- get package files list
    local list = name and try { function() return os.iorunv(pacman.program, {"-Q", "-l", name}) end }
    if not list then
        return
    end

    -- parse package files list
    local linkdirs = {}
    local pkgconfig_files = {}
    for _, line in ipairs(list:split('\n', {plain = true})) do
        line = line:trim():split('%s+')[2]
        if line:find("/pkgconfig/", 1, true) and line:endswith(".pc") then
            table.insert(pkgconfig_files, line)
        end
        if line:endswith(".so") or line:endswith(".a") or line:endswith(".lib") then
            table.insert(linkdirs, path.directory(line))
        end
    end
    linkdirs = table.unique(linkdirs)

    -- we iterate over each pkgconfig file to extract the required data
    local result
    for _, pkgconfig_file in ipairs(pkgconfig_files) do
        local pkgconfig_dir = path.directory(pkgconfig_file)
        local pkgconfig_name = path.basename(pkgconfig_file)
        local pcresult = find_package_from_pkgconfig(pkgconfig_name, {configdirs = pkgconfig_dir, linkdirs = linkdirs})
        if pcresult then
            result = result or {}
            for _, includedir in ipairs(pcresult.includedirs) do
                result.includedirs = result.includedirs or {}
                table.insert(result.includedirs, includedir)
            end
            for _, linkdir in ipairs(pcresult.linkdirs) do
                result.linkdirs = result.linkdirs or {}
                table.insert(result.linkdirs, linkdir)
            end
            for _, link in ipairs(pcresult.links) do
                result.links = result.links or {}
                table.insert(result.links, link)
            end
            for _, libfile in ipairs(pcresult.libfiles) do
                result.libfiles = result.libfiles or {}
                table.insert(result.libfiles, libfile)
            end
            -- version should be the same if a pacman package contains multiples .pc
            result.version = pcresult.version
            result.shared = pcresult.shared
            result.static = pcresult.static
        end
    end

    if result then
        if result.includedirs then
            result.includedirs = table.unique(result.includedirs)
        end
        if result.linkdirs then
            result.linkdirs = table.unique(result.linkdirs)
        end
        if result.libfiles then
            result.libfiles = table.unique(result.libfiles)
        end
        if result.links then
            result.links = table.reverse_unique(result.links)
        end
    else
        -- if there is no .pc, we parse the package content to obtain the data we want
        result = _find_package_from_list(list, name, pacman, opt)
    end
    if result then
        -- we give priority to libfiles in the list
        local libfiles = _find_libfiles_from_list(list, name, pacman, opt)
        if libfiles then
            result.shared = nil
            result.static = nil
            result.libfiles = libfiles
            for _, libfile in ipairs(libfiles) do
                if libfile:endswith(".so") then
                    result.shared = true
                elseif libfile:endswith(".a") then
                    result.static = true
                end
            end
        end
    end
    return result
end
