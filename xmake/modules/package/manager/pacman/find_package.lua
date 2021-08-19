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
    local cygpath = nil
    if opt.plat == "mingw" then
        name = (opt.arch == "x86_64" and "mingw-w64-x86_64-" or "mingw-w64-i686-") .. name
        
        -- mingw + pacman = cygpath available
        cygpath = find_tool("cygpath")
        if not cygpath then
            return
        end
    end

    -- get package files list
    local list = try { function() return os.iorunv(pacman.program, {"-Q", "-l", name}) end }
    if not list then
        return
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
    local result = {}
    local myIncludedirs = {}
    local myLinkdirs = {}
    local myLinks = {}
    myVersion = "0"
    local foundPC = false
    for key, file in pairs(pkgconfig_files) do
        pkgconfig_file = file
        local pkgconfig_dir = path.directory(pkgconfig_file)
        local pkgconfig_name = path.basename(pkgconfig_file)
        linkdirs = table.unique(linkdirs)
        includedirs = table.unique(includedirs)
        local myResult = {}
        myResult = find_package_from_pkgconfig(pkgconfig_name, {configdirs = pkgconfig_dir, linkdirs = linkdirs})
            
        -- the pkgconfig file has been parse successfully
        if myResult ~= nil then
            for _, locIncludeDir in pairs(myResult.includedirs) do
                table.insert(myIncludedirs, locIncludeDir)
            end
                    
            for _, locLinkDir in pairs(myResult.linkdirs) do
                table.insert(myLinkdirs, locLinkDir)
            end
            
            for _, locLink in pairs(myResult.links) do
                table.insert(myLinks, locLink)
            end

            -- version should be the same if a pacman package contains multiples .pc
            myVersion = myResult.version
            
            foundPC = true
        end
    end
        
    if foundPC == true then
        myIncludedirs = table.unique(myIncludedirs)
        myLinkdirs = table.unique(myLinkdirs)
        myLinks = table.unique(myLinks)
        
        result.includedirs = myIncludedirs
        result.linkdirs = myLinkdirs
        result.links = myLinks
        result.version = myVersion
    else -- if there is no .pc, we parse the package content to obtain the data we want
        for _, line in ipairs(list:split('\n', {plain = true})) do -- on msys cygpath should be use to convert local path to windows path
            line = line:trim():split('%s+')[2]
            if line:find("/include/", 1, true) and (line:endswith(".h") or line:endswith(".hpp")) then
                local hPath = line
                if opt.plat == "mingw" then
                    hPath = os.iorunv(cygpath.program, {"--windows", line})
                end
                table.insert(myIncludedirs, path.directory(hPath))
                if(opt.arch == "x86_64") then
                    local baseHPath = os.iorunv(cygpath.program, {"--windows", "/mingw64/include"})
                    table.insert(myIncludedirs, baseHPath)
                else
                    local baseHPath = os.iorunv(cygpath.program, {"--windows", "/mingw32/include"})
                    table.insert(myIncludedirs, baseHPath)
                end
            -- revove lib and .a, .dll.a and .so to have the links
            elseif line:endswith(".dll.a") then
                local aPath = os.iorunv(cygpath.program, {"--windows", line})
                table.insert(myLinkdirs, path.directory(aPath))
                aPath = path.filename(aPath)
                if aPath:startswith("lib") then
                    aPath = aPath:sub(4, aPath:len())
                end
                table.insert(myLinks, aPath:sub(1, aPath:len() - 7))
            elseif line:endswith(".so") then
                local aPath = line
                table.insert(myLinkdirs, path.directory(aPath))
                aPath = path.filename(aPath)
                if aPath:startswith("lib") then
                    aPath = aPath:sub(4, aPath:len())
                end
                table.insert(myLinks, aPath:sub(1, aPath:len() - 4))
            elseif line:endswith(".a") then
                local aPath = line
                if opt.plat == "mingw" then
                    aPath = os.iorunv(cygpath.program, {"--windows", line})
                end
                aPath = path.filename(aPath)
                if aPath:startswith("lib") then
                    aPath = aPath:sub(4, aPath:len())
                end
                table.insert(myLinks, aPath:sub(1, aPath:len() - 3))
            end
        end
        
        myLinkdirs = table.unique(myLinkdirs)
        myLinks = table.unique(myLinks)
        myIncludedirs = table.unique(myIncludedirs)
        
        -- use pacman package version as version
        local myVersion = "0"
        local nameVersion = try { function() return os.iorunv(pacman.program, {"-Q", name}) end }
        if nameVersion then
            myVersion = nameVersion:trim():split('%s+')[2]
        end

        result = {}
        result.includedirs = myIncludedirs
        result.linkdirs    = myLinkdirs
        result.links       = myLinks
        result.version     = myVersion
    end
        
    return result
end
