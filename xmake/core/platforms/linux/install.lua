--!The Automatic Cross-platform Build Tool
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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        install.lua
--

-- define module: install
local install = install or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local rule      = require("base/rule")
local utils     = require("base/utils")
local string    = require("base/string")
local platform  = require("base/platform")

-- install target for the library file
function install._done_library(target)

    -- check
    assert(target and target.name and target.archs)

    -- the output directory
    local outputdir = target.outputdir or "/usr/local"
    assert(outputdir)

    -- get target info
    local info = target.archs[xmake._ARCH] or target.archs["x86_64"] or target.archs["i386"]
    if not info then return -1 end

    -- check
    assert(info.targetdir and info.targetfile)

    -- make the library directory
    local librarydir = outputdir .. "/lib"
    if not os.isdir(librarydir) then
        if not os.mkdir(librarydir) then
            utils.error("create directory %s failed", librarydir)
            return -1
        end
    end

    -- copy the library file to the library directory
    local ok, errors = os.cp(string.format("%s/%s", info.targetdir, info.targetfile), string.format("%s/%s", librarydir, path.filename(info.targetfile))) 
    if not ok then
        utils.error(errors)
        return -1
    end

    -- make the include directory
    local includedir = outputdir .. "/include"
    if not os.isdir(includedir) then
        if not os.mkdir(includedir) then
            utils.error("create directory %s failed", includedir)
            return -1
        end
    end

    -- copy the config.h to the output directory
    if info.config_h then
        local ok, errors = os.cp(string.format("%s/%s", info.targetdir, info.config_h), string.format("%s/%s/%s", includedir, target.name, path.filename(info.config_h))) 
        if not ok then
            utils.error(errors)
            return -1
        end

        -- update the config.h
        info.config_h = string.format("%s/%s/%s", includedir, target.name, path.filename(info.config_h))
    end

    -- copy headers
    if target.headers then
        local srcheaders, dstheaders = rule.headerfiles(target, includedir)
        if srcheaders and dstheaders then
            local i = 1
            for _, srcheader in ipairs(srcheaders) do
                local dstheader = dstheaders[i]
                if dstheader then
                    local ok, errors = os.cp(srcheader, dstheader)
                    if not ok then
                        utils.error(errors)
                        return -1
                    end
                end
                i = i + 1
            end
        end
        
        -- update the headers
        target.headers = dstheaders
    end

    -- update the target directory and file
    info.targetdir = librarydir
    info.targetfile = path.filename(info.targetfile)

    -- ok
    return 1
end

-- install target for the binary file
function install._done_binary(target)

    -- check
    assert(target and target.archs)

    -- the output directory
    local outputdir = target.outputdir or "/usr/local"
    assert(outputdir)

    -- make the binary directory
    local binarydir = outputdir .. "/bin"
    if not os.isdir(binarydir) then
        if not os.mkdir(binarydir) then
            utils.error("create directory %s failed", binarydir)
            return -1
        end
    end

    -- get target info
    local info = target.archs[xmake._ARCH] or target.archs["x86_64"] or target.archs["i386"]
    if not info then return -1 end

    -- check
    assert(info.targetdir and info.targetfile)

    -- copy the binary file to the binary directory
    local ok, errors = os.cp(string.format("%s/%s", info.targetdir, info.targetfile), binarydir) 
    if not ok then
        utils.error(errors)
        return -1
    end

    -- update the target directory and file
    info.targetdir = binarydir
    info.targetfile = path.filename(info.targetfile)

    -- ok
    return 1
end

-- install target 
function install.main(target)

    -- check
    assert(target and target.kind)

    -- the install scripts
    local installscripts = 
    {
        static = install._done_library
    ,   shared = install._done_library
    ,   binary = install._done_binary
    }

    -- install it
    local installscript = installscripts[target.kind]
    if installscript then return installscript(target) end

    -- continue
    return 0
end

-- return module: install
return install
