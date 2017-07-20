--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("core.project.config")
import("core.base.global")
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

    -- copy the symbol file to the output directory
    local symbolfile = target:symbolfile()
    if os.isfile(symbolfile) then
        os.cp(symbolfile, format("%s/%s.pkg/lib/$(mode)/$(plat)/$(arch)/%s", outputdir, targetname, path.filename(symbolfile))) 
    end

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
    add_defines_h("$(prefix)_PACKAGE_HAVE_[TARGETNAME]")

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
function _on_package_target(target)

    -- is phony target?
    if target:isphony() then
        return 
    end

    -- get kind
    local kind = target:targetkind()

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
    local oldir = os.cd(project.directory())

    -- the target scripts
    local scripts =
    {
        target:script("package_before")
    ,   target:script("package", _on_package_target)
    ,   target:script("package_after")
    }

    -- package the target scripts
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end

    -- leave project directory
    os.cd(oldir)
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
    _package(target)

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

    -- build it first
    task.run("build", {target = targetname, all = option.get("all")})

    -- init finished states
    _g.finished = {}

    -- package the given target?
    if targetname then
        _package_target_and_deps(project.target(targetname))
    else
        -- package default or all targets
        for _, target in pairs(project.targets()) do
            local default = target:get("default")
            if default == nil or default == true or option.get("all") then
                _package_target_and_deps(target)
            end
        end
    end
end
