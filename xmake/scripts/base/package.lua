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
local rule      = require("base/rule")
local path      = require("base/path")
local utils     = require("base/utils")
local config    = require("base/config")
local platform  = require("platform/platform")

-- package target for the static library
function package._done_static(target)

    -- check
    assert(target and target.name and target.archs)

    -- the plat and mode
    local plat = config.get("plat")
    local mode = config.get("mode")
    assert(plat and mode)

    -- package it
    for arch, info in pairs(target.archs) do
    
        -- check
        assert(info.targetdir and info.targetfile and info.outputdir)

        -- copy the static library file to the output directory
        local ok, errors = os.cp(string.format("%s/%s", info.targetdir, info.targetfile), string.format("%s/%s.pkg/lib/%s/%s/%s/%s", info.outputdir, target.name, mode, plat, arch, path.filename(info.targetfile))) 

        -- ok?
        if not ok then
            utils.error(errors)
            return -1
        end
    end

    -- ok
    return 1
end

-- package target for the shared library
function package._done_shared(target)


    -- continue
    return 0
end

-- package target for the binary library
function package._done_binary(target)

    -- check
    assert(target and target.archs)

    -- the count of architectures
    local count = 0
    for _, _ in pairs(target.archs) do count = count + 1 end

    -- package it
    local ok = nil
    local errors = nil 
    for arch, info in pairs(target.archs) do
    
        -- check
        assert(info.targetdir and info.targetfile and info.outputdir)

        -- copy the binary file to the output directory
        if count == 1 then
            ok, errors = os.cp(string.format("%s/%s", info.targetdir, info.targetfile), info.outputdir) 
        else
            ok, errors = os.cp(string.format("%s/%s", info.targetdir, info.targetfile), string.format("%s/%s", info.outputdir, rule.filename(path.basename(info.targetfile) .. "_" .. arch, "binary"))) 
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
    local pkgscripts = 
    {
        static = package._done_static
    ,   shared = package._done_shared
    ,   binary = package._done_binary
    }

    -- package it
    local pkgscript = pkgscripts[target.kind]
    if pkgscript then return pkgscript(target) end

    -- continue
    return 0
end

-- package target from the project script
function package._done_from_project(target)

    -- check
    assert(target)

    -- package it using the project script first
    local pkgscript = target.pkgscript
    if type(pkgscript) == "function" then

        -- remove it
        target.pkgscript = nil

        -- package it
        return pkgscript(target)
    end

    -- continue
    return 0
end

-- package target from the platform script
function package._done_from_platform(target)

    -- check
    assert(target)

    -- the platform package script file
    local pkgscript = nil
    local scriptfile = platform.directory() .. "/package.lua"
    if os.isfile(scriptfile) then 

        -- load the package script
        local script, errors = loadfile(scriptfile)
        if script then pkgscript = script()
        else
            utils.error(errors)
        end
    end

    -- package it
    if type(pkgscript) == "function" then
        return pkgscript(target)
    end

    -- continue
    return 0
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

    -- ok
    return true
end

-- return module: package
return package
