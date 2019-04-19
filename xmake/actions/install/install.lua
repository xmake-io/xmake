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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        install.lua
--

-- imports
import("core.base.task")
import("core.project.rule")
import("core.project.project")

-- install files
function _install_files(target)

    local srcfiles, dstfiles = target:installfiles()
    if srcfiles and dstfiles then
        local i = 1
        for _, srcfile in ipairs(srcfiles) do
            local dstfile = dstfiles[i]
            if dstfile then
                os.vcp(srcfile, dstfile)
            end
            i = i + 1
        end
    end
end

-- install binary
function _install_binary(target)

    -- is phony target?
    if target:isphony() then
        return 
    end

    -- the binary directory
    local binarydir = path.join(target:installdir(), "bin")

    -- make the binary directory
    os.mkdir(binarydir)

    -- copy the target file
    os.vcp(target:targetfile(), binarydir)
end

-- install library
function _install_library(target)

    -- is phony target?
    if target:isphony() then
        return 
    end

    -- the library directory
    local librarydir = path.join(target:installdir(), "lib")

    -- the include directory
    local includedir = path.join(target:installdir(), "include")

    -- make the library directory
    os.mkdir(librarydir)

    -- make the include directory
    os.mkdir(includedir)

    -- copy the target file
    os.vcp(target:targetfile(), librarydir)

    -- copy headers to the include directory
    local srcheaders, dstheaders = target:headerfiles(includedir)
    if srcheaders and dstheaders then
        local i = 1
        for _, srcheader in ipairs(srcheaders) do
            local dstheader = dstheaders[i]
            if dstheader then
                os.vcp(srcheader, dstheader)
            end
            i = i + 1
        end
    end
end

-- do install target
function _do_install_target(target)

    -- get install directory
    local installdir = target:installdir()
    if not installdir then
        return 
    end

    -- trace
    print("installing to %s ...", installdir)

    -- the scripts
    local scripts =
    {
        binary = _install_binary
    ,   static = _install_library
    ,   shared = _install_library
    }

    -- call script
    local script = scripts[target:targetkind()]
    if script then
        script(target)
    end

    -- install other files
    _install_files(target)
end

-- on install target
function _on_install_target(target)

    -- has been disabled?
    if target:get("enabled") == false then
        return 
    end

    -- trace
    print("installing %s ...", target:name())

    -- build target with rules
    local done = false
    for _, r in ipairs(target:orderules()) do
        local on_install = r:script("install")
        if on_install then
            on_install(target, {origin = _do_install_target})
            done = true
        end
    end
    if done then return end

    -- do install
    _do_install_target(target)
end

-- install the given target 
function _install_target(target)

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- enter the environments of the target packages
    local oldenvs = {}
    for name, values in pairs(target:pkgenvs()) do
        oldenvs[name] = os.getenv(name)
        os.addenv(name, unpack(values))
    end

    -- the target scripts
    local scripts =
    {
        target:script("install_before")
    ,   function (target)

            -- has been disabled?
            if target:get("enabled") == false then
                return 
            end

            -- install rules
            for _, r in ipairs(target:orderules()) do
                local before_install = r:script("install_before")
                if before_install then
                    before_install(target)
                end
            end
        end
    ,   target:script("install", _on_install_target)
    ,   function (target)

            -- has been disabled?
            if target:get("enabled") == false then
                return 
            end

            -- install rules
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
            script(target, {origin = (i == 3 and _do_install_target or nil)})
        end
    end

    -- leave the environments of the target packages
    for name, values in pairs(oldenvs) do
        os.setenv(name, values)
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
function main(targetname)

    -- init finished states
    _g.finished = {}

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
