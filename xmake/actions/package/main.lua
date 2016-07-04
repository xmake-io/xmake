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
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.task")
import("core.project.config")
import("core.project.global")
import("core.project.project")
import("core.platform.platform")

-- package library 
function _package_library(target)

    -- the output directory
    local outputdir = option.get("outputdir") or config.get("buildir")

    -- the target name
    local targetname = target:name()

    -- copy the library file to the output directory
    os.cp(target:targetfile(), format("%s/%s.pkg/lib/$(mode)/$(plat)/$(arch)/%s", outputdir, targetname, path.filename(target:targetfile()))) 

    -- copy the config.h to the output directory
    local configheader = target:configheader()
    if configheader then
        os.cp(configheader, format("%s/%s.pkg/inc/$(plat)/%s", outputdir, targetname, path.filename(configheader))) 
    end

    -- copy headers
    local srcheaders, dstheaders = target:headerfiles(format("%s/%s.pkg/inc", outputdir, targetname))
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

    -- make xmake.lua 
    local file = io.open(format("%s/%s.pkg/xmake.lua", outputdir, targetname), "w")
    if file then

        -- the xmake.lua content
        local content = [[ 
-- the [targetname] package
option("[targetname]")

    -- show menu
    set_showmenu(true)

    -- set category
    set_category("package")

    -- set description
    set_description("The [targetname] package")

    -- set language: c99, c++11
    set_languages("c99", "cxx11")

    -- add defines to config.h if checking ok
    add_defines_h_if_ok("$(prefix)_PACKAGE_HAVE_[TARGETNAME]")

    -- add links for checking
    add_links("[targetname]")

    -- add link directories
    add_linkdirs("lib/$(mode)/$(plat)/$(arch)")

    -- add c includes for checking
    add_cincludes("[targetname]/[targetname].h")

    -- add include directories
    add_includedirs("inc/$(plat)", "inc")
]]

        -- save file
        file:write((content:gsub("%[targetname%]", targetname):gsub("%[TARGETNAME%]", targetname:upper())))

        -- exit file
        file:close()
    end
end

-- package target 
function _package_target(target)

    -- get kind
    local kind = target:get("kind")

    -- get script 
    local scripts =
    {
        binary = function (target) end
    ,   static = _package_library
    ,   shared = _package_library
    }

    -- check
    assert(scripts[kind], "this target(%s) with kind(%s) can not be packaged!", target:name(), kind)

    -- package it
    scripts[kind](target) 
end

-- package the given target 
function _package(target)

    -- enter project directory
    os.cd(project.directory())

    -- the target scripts
    local scripts =
    {
        target:get("package_before")
    ,   target:get("package") or _package_target
    ,   target:get("package_after")
    }

    -- package the target scripts
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end

    -- leave project directory
    os.cd("-")
end

-- package the given target and deps
function _package_target_and_deps(target)

    -- this target have been finished?
    if _g.finished[target:name()] then
        return 
    end

    -- package for all dependent targets
    for _, depname in ipairs(target:get("deps")) do
        _package_target_and_deps(project.target(depname)) 
    end

    -- package target
    _package_target(target)

    -- finished
    _g.finished[target:name()] = true
end

-- main
function main()

    -- --archs? deprecated 
    if option.get("archs") then

        -- load config
        config.load()
            
        -- deprecated
        raise("please run \"xmake m package %s\" instead of \"xmake p --archs=%s\"", config.get("plat"), option.get("archs"))
    end

    -- get the target name
    local targetname = option.get("target")

    -- init finished states
    _g.finished = {}

    -- build it first
    task.run("build", {target = targetname})

    -- package all?
    if targetname == "all" then
        for _, target in pairs(project.targets()) do
            _package_target_and_deps(target)
        end
    else
        _package_target_and_deps(project.target(targetname))
    end

    -- trace
    print("package ok!")
end
