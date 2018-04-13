--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        install.lua
--

-- imports
import("core.base.task")
import("core.project.rule")
import("core.project.project")

-- install binary
function _install_binary(target)

    -- is phony target?
    if target:isphony() then
        return 
    end

    -- the binary directory
    local binarydir = path.join(_g.installdir, "bin")

    -- make the binary directory
    os.mkdir(binarydir)

    -- copy the target file
    os.cp(target:targetfile(), binarydir)
end

-- install library
function _install_library(target)

    -- is phony target?
    if target:isphony() then
        return 
    end

    -- the library directory
    local librarydir = path.join(_g.installdir, "lib")

    -- the include directory
    local includedir = path.join(_g.installdir, "include")

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

-- on install
function _on_install(target)

    -- build target with rules
    local done = false
    for _, r in ipairs(target:orderules()) do
        local on_install = r:script("install")
        if on_install then
            on_install(target)
            done = true
        end
    end
    if done then return end

    -- the scripts
    local scripts =
    {
        binary = _install_binary
    ,   static = _install_library
    ,   shared = _install_library
    }

    -- call script
    local script = scripts[target:get("kind")]
    if script then
        script(target)
    end
end

-- install the given target 
function _install_target(target)

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- the target scripts
    local scripts =
    {
        target:script("install_before")
    ,   function (target)
            for _, r in ipairs(target:orderules()) do
                local before_install = r:script("install_before")
                if before_install then
                    before_install(target)
                end
            end
        end
    ,   target:script("install", _on_install)
    ,   function (target)
            for _, r in ipairs(target:orderules()) do
                local after_install = r:script("install_after")
                if after_install then
                    after_install(target)
                end
            end
        end
    ,   target:script("install_after")
    }

    -- install the target scripts
    for i = 1, 5 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end

    -- leave project directory
    os.cd(oldir)
end

-- install the given target and deps
function _install_target_and_deps(target)

    -- this target have been finished?
    if _g.finished[target:name()] then
        return 
    end

    -- install for all dependent targets
    for _, depname in ipairs(target:get("deps")) do
        _install_target_and_deps(project.target(depname)) 
    end

    -- install target
    _install_target(target)

    -- finished
    _g.finished[target:name()] = true
end

-- install targets
function main(targetname, installdir)

    -- init finished states
    _g.finished = {}

    -- init install directory
    _g.installdir = installdir

    -- install the given target?
    if targetname and not targetname:startswith("__") then
        _install_target_and_deps(project.target(targetname))
    else
        -- install default or all targets
        for _, target in pairs(project.targets()) do
            local default = target:get("default")
            if default == nil or default == true or targetname == "__all" then
                _install_target_and_deps(target)
            end
        end
    end
end
