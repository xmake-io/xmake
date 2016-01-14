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
-- @file        package.lua
--

-- define module: package
local package = package or {}

-- load modules
local os        = require("base/os")
local io        = require("base/io")
local rule      = require("base/rule")
local path      = require("base/path")
local utils     = require("base/utils")
local config    = require("base/config")
local platform  = require("base/platform")

-- package target for the library file
function package._done_library(target)

    -- check
    assert(target and target.name and target.archs)

    -- the output directory
    local outputdir = target.outputdir
    assert(outputdir)

    -- the plat and mode
    local plat = config.get("plat")
    local mode = config.get("mode")
    assert(plat and mode)

    -- package it
    for arch, info in pairs(target.archs) do
    
        -- check
        assert(info.targetdir and info.targetfile)

        -- copy the library file to the output directory
        local ok, errors = os.cp(string.format("%s/%s", info.targetdir, info.targetfile), string.format("%s/%s.pkg/lib/%s/%s/%s/%s", outputdir, target.name, mode, plat, arch, path.filename(info.targetfile))) 
        if not ok then
            utils.error(errors)
            return -1
        end

        -- copy the config.h to the output directory
        if info.config_h then
            local ok, errors = os.cp(string.format("%s/%s", info.targetdir, info.config_h), string.format("%s/%s.pkg/inc/%s/%s", outputdir, target.name, plat, path.filename(info.config_h))) 
            if not ok then
                utils.error(errors)
                return -1
            end
        end
    end

    -- copy headers
    if target.headers then
        local srcheaders, dstheaders = rule.headerfiles(target, string.format("%s/%s.pkg/inc", outputdir, target.name))
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
    end

    -- make xmake.lua 
    local file = io.open(string.format("%s/%s.pkg/xmake.lua", outputdir, target.name), "w")
    if file then

        -- the xmake.lua template content
        local template = [[ 
-- add [targetname] package
add_option("[targetname]")

    -- show menu
    set_option_showmenu(true)

    -- set category
    set_option_category("package")

    -- set description
    set_option_description("The [targetname] package")

    -- set language: c99, c++11
    set_option_languages("c99", "cxx11")

    -- add defines to config.h if checking ok
    add_option_defines_h_if_ok("$(prefix)_PACKAGE_HAVE_[TARGETNAME]")

    -- add links for checking
    add_option_links("[targetname]")

    -- add link directories
    add_option_linkdirs("lib/$(mode)/$(plat)/$(arch)")

    -- add c includes for checking
    add_option_cincludes("[targetname]/[targetname].h")

    -- add include directories
    add_option_includedirs("inc/$(plat)", "inc")
]]

        -- save file
        file:write((template:gsub("%[targetname%]", target.name):gsub("%[TARGETNAME%]", target.name:upper())))

        -- exit file
        file:close()
    end

    -- ok
    return 1
end

-- package target for the binary file
function package._done_binary(target)

    -- check
    assert(target and target.archs)

    -- the output directory
    local outputdir = target.outputdir
    assert(outputdir)

    -- the count of architectures
    local count = 0
    for _, _ in pairs(target.archs) do count = count + 1 end

    -- package it
    local ok = nil
    local errors = nil 
    for arch, info in pairs(target.archs) do
    
        -- check
        assert(info.targetdir and info.targetfile)

        -- copy the binary file to the output directory
        if count == 1 then
            ok, errors = os.cp(string.format("%s/%s", info.targetdir, info.targetfile), string.format("%s/%s", outputdir, path.filename(info.targetfile))) 
        else
            ok, errors = os.cp(string.format("%s/%s", info.targetdir, info.targetfile), string.format("%s/%s", outputdir, rule.filename(path.basename(info.targetfile) .. "_" .. arch, "binary"))) 
        end

        -- ok?
        if not ok then
            utils.error(errors)
            return -1
        end
    end

    -- ok
    return 1
end

-- package target from the default script
function package._done_from_default(target)

    -- check
    assert(target.kind)

    -- the package scripts
    local packagescripts = 
    {
        static = package._done_library
    ,   shared = package._done_library
    ,   binary = package._done_binary
    }

    -- package it
    local packagescript = packagescripts[target.kind]
    if packagescript then return packagescript(target) end

    -- continue
    return 0
end

-- package target from the project script
function package._done_from_project(target)

    -- check
    assert(target)

    -- package it using the project script first
    local packagescript = target.packagescript
    if type(packagescript) == "function" then

        -- remove it
        target.packagescript = nil

        -- package it
        return packagescript(target)
    end

    -- continue
    return 0
end

-- package target from the platform script
function package._done_from_platform(target)

    -- check
    assert(target)

    -- the platform package script file
    local packagescript = nil
    local scriptfile = platform.directory() .. "/package.lua"
    if os.isfile(scriptfile) then 

        -- load the package script
        local script, errors = loadfile(scriptfile)
        if script then 
            packagescript = script()
            if type(packagescript) == "table" and packagescript.main then 
                packagescript = packagescript.main
            end
        else
            utils.error(errors)
        end
    end

    -- package it
    if type(packagescript) == "function" then
        return packagescript(target)
    end

    -- continue
    return 0
end

-- get the configure file
function package._file()
 
    -- get it
    return config.directory() .. "/package.conf"
end

-- package target from the given target configure
function package._done(target)

    -- check
    assert(target)

    -- package it from the project script
    local ok = package._done_from_project(target)
    if ok ~= 0 then return utils.ifelse(ok == 1, true, false) end

    -- package it from the platform script
    local ok = package._done_from_platform(target)
    if ok ~= 0 then return utils.ifelse(ok == 1, true, false) end

    -- package it from the default script
    local ok = package._done_from_default(target)
    if ok ~= 0 then return utils.ifelse(ok == 1, true, false) end

    -- ok
    return true
end

-- done package from the configure
function package.done(configs)

    -- check
    assert(configs)

    -- package targets
    for _, target in pairs(configs) do

        -- package it
        if not package._done(target) then
            -- errors
            utils.error("package %s failed!", target.name)
            return false
        end

    end

    -- save to the configure file
    return io.save(package._file(), configs) 
end

-- load the package configure
function package.load()

    -- load it
    return io.load(package._file()) 
end

-- return module: package
return package
