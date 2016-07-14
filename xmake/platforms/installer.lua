--!The Make-like Build Utility based on Lua
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        installer.lua
--

-- imports
import("core.base.option")

-- install binary
function install_binary_on_unix(target)

    -- the install directory
    local installdir = option.get("installdir") or "/usr/local"

    -- the binary directory
    local binarydir = path.join(installdir, "bin")

    -- make the binary directory
    os.mkdir(binarydir)

    -- copy the target file
    os.cp(target:targetfile(), binarydir)
end

-- install library
function install_library_on_unix(target)

    -- the install directory
    local installdir = option.get("installdir") or "/usr/local"

    -- the library directory
    local librarydir = path.join(installdir, "lib")

    -- the include directory
    local includedir = path.join(installdir, "include")

    -- make the library directory
    os.mkdir(librarydir)

    -- make the include directory
    os.mkdir(includedir)

    -- copy the target file
    os.cp(target:targetfile(), librarydir)

    -- copy the config.h to the include directory
    local configheader, configoutput = target:configheader(includedir)
    if configheader and configoutput then
        os.cp(configheader, configoutput) 
    end

    -- copy headers to the include directory
    local srcheaders, dstheaders = target:headerfiles(includedir)
    if srcheaders and dstheaders then
        local i = 1
        for _, srcheader in ipairs(srcheaders) do
            local dstheader = dstheaders[i]
            if dstheader then
                os.cp(srcheader, dstheader)
            end
            i = i + 1
        end
    end
end

-- uninstall binary
function uninstall_binary_on_unix(target)

    -- the install directory
    local installdir = option.get("installdir") or "/usr/local"

    -- the binary directory
    local binarydir = path.join(installdir, "bin")

    -- remove the target file
    os.rm(path.join(binarydir, path.filename(target:targetfile())))
end

-- uninstall library
function uninstall_library_on_unix(target)

    -- the install directory
    local installdir = option.get("installdir") or "/usr/local"

    -- the library directory
    local librarydir = path.join(installdir, "lib")

    -- the include directory
    local includedir = path.join(installdir, "include")

    -- remove the target file
    os.rm(path.join(librarydir, path.filename(target:targetfile())))

    -- reove the config.h from the include directory
    local _, configoutput = target:configheader(includedir)
    if configoutput then
        os.rm(configoutput, true) 
    end

    -- remove headers from the include directory
    local _, dstheaders = target:headerfiles(includedir)
    for _, dstheader in ipairs(dstheaders) do
        os.rm(dstheader, true)
    end
end
