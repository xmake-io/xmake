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
import("lib.detect.find_tool")
import("package.manager.pkgconfig.find_package", {alias = "find_package_from_pkgconfig"})

-- get result from list of file inside pacman package
function _find_package_from_list(list, opt, name, pacman)
    local result = {
        includedirs = {},
        linkdirs = {},
        links = {},
        version = nil
    }
    
    local cygpath = nil
    -- mingw + pacman = cygpath available
    if is_subhost("msys") and opt.plat == "mingw" then
        cygpath = find_tool("cygpath")
        if not cygpath then
            return nil
        end
    end

    -- iterate over each file path inside the pacman package
    for _, line in ipairs(list:split('\n', {plain = true})) do -- on msys cygpath should be used to convert local path to windows path
        line = line:trim():split('%s+')[2]
        if line:find("/include/", 1, true) and (line:endswith(".h") or line:endswith(".hpp")) then
            local hpath = line
            if is_subhost("msys") and opt.plat == "mingw" then
                hpath = os.iorunv(cygpath.program, {"--windows", line})
                
                if opt.arch == "x86_64" then
                local basehpath = os.iorunv(cygpath.program, {"--windows", "/mingw64/include"})
                    table.insert(result.includedirs, basehpath)
                else
                    local basehpath = os.iorunv(cygpath.program, {"--windows", "/mingw32/include"})
                    table.insert(result.includedirs, basehpath)
                end
            end
            table.insert(result.includedirs, path.directory(hpath))
        -- revove lib and .a, .dll.a and .so to have the links
        elseif line:endswith(".dll.a") then -- only for mingw
            local apath = os.iorunv(cygpath.program, {"--windows", line})
            table.insert(result.linkdirs, path.directory(apath))
            apath = path.filename(apath)
            if apath:startswith("lib") then
                apath = apath:sub(4, apath:len())
            end
            table.insert(result.links, apath:sub(1, apath:len() - 7))
        elseif line:endswith(".so") then
            local apath = line
            table.insert(result.linkdirs, path.directory(apath))
            apath = path.filename(apath)
            if apath:startswith("lib") then
                apath = apath:sub(4, apath:len())
            end
            table.insert(result.links, apath:sub(1, apath:len() - 4))
        elseif line:endswith(".a") then
            local apath = line
            if is_subhost("msys") and opt.plat == "mingw" then
                apath = os.iorunv(cygpath.program, {"--windows", line})
            end
            table.insert(result.linkdirs, path.directory(apath))
            apath = path.filename(apath)
            if apath:startswith("lib") then
                apath = apath:sub(4, apath:len())
            end
            table.insert(result.links, apath:sub(1, apath:len() - 3))
        end
    end

    result.includedirs = table.unique(result.includedirs)
    result.linkdirs = table.unique(result.linkdirs)
    result.links = table.unique(result.links)

    -- use pacman package version as version
    local pacmanversion = try { function() return os.iorunv(pacman.program, {"-Q", name}) end }
    if pacmanversion then
        pacmanversion = pacmanversion:trim():split('%s+')[2]
        result.version = pacmanversion:split('-')[1]
    else
        result = nil
    end
    
    return result
end

-- find package from the system directories
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)

    -- init options
    opt = opt or {}

    -- find pacman
    local pacman = find_tool("pacman")
    if not pacman then
        return
    end

    -- for msys2/mingw? mingw-w64-[i686|x86_64]-xxx
    if is_subhost("msys") and opt.plat == "mingw" then
        name = (opt.arch == "x86_64" and "mingw-w64-x86_64-" or "mingw-w64-i686-") .. name
    end

    -- get package files list
    local list = try { function() return os.iorunv(pacman.program, {"-Q", "-l", name}) end }
    if not list then
        return nil
    end

    -- parse package files list
    local linkdirs = {}
    local has_includes = false
    local pkgconfig_files = {}
    for _, line in ipairs(list:split('\n', {plain = true})) do
        line = line:trim():split('%s+')[2]
        if line:find("/pkgconfig/", 1, true) and line:endswith(".pc") then
            pkgconfig_files[path.basename(line)] = line
        end
        if line:endswith(".so") or line:endswith(".a") or line:endswith(".lib") then
            table.insert(linkdirs, path.directory(line))
        elseif line:find("/include/", 1, true) and (line:endswith(".h") or line:endswith(".hpp")) then
            has_includes = true
        end
    end
    
    -- we iterate over each pkgconfig file to extract the required data
    local result = {
        includedirs = {},
        linkdirs = {},
        links = {},
        version = nil
    }

    local foundpc = false

    for key, file in pairs(pkgconfig_files) do
        local pkgconfig_file = file
        local pkgconfig_dir = path.directory(pkgconfig_file)
        local pkgconfig_name = path.basename(pkgconfig_file)
        linkdirs = table.unique(linkdirs)
        local pcresult = find_package_from_pkgconfig(pkgconfig_name, {configdirs = pkgconfig_dir, linkdirs = linkdirs})
            
        -- the pkgconfig file has been parse successfully
        if pcresult ~= nil then
            for _, locincludedir in ipairs(pcresult.includedirs) do
                table.insert(result.includedirs, locincludedir)
            end
                    
            for _, loclinkdir in ipairs(pcresult.linkdirs) do
                table.insert(result.linkdirs, loclinkdir)
            end
            
            for _, loclink in ipairs(pcresult.links) do
                table.insert(result.links, loclink)
            end

            -- version should be the same if a pacman package contains multiples .pc
            result.version = pcresult.version
            
            foundpc = true
        end
    end

    if foundpc == true then
        result.includedirs = table.unique(result.includedirs)
        result.linkdirs = table.unique(result.linkdirs)
        result.links = table.unique(result.links)
    else -- if there is no .pc, we parse the package content to obtain the data we want
        result = _find_package_from_list(list, opt, name, pacman)
    end
        
    return result
end
