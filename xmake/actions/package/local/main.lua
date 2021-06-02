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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("core.project.rule")
import("core.project.config")
import("core.project.project")
import("lib.luajit.bit")

-- package binary
function _package_binary(target)

    -- get the output directory
    local outputdir   = option.get("outputdir") or config.buildir()
    local packagename = target:name():lower()
    if bit.band(packagename:byte(2), 0xc0) == 0x80 then
        wprint("package(%s): cannot generate package, becauese it contains unicode characters!", packagename)
        return
    end
    local packagedir  = path.join(outputdir, "packages", packagename:sub(1, 1), packagename)
    local binarydir   = path.join(packagedir, target:plat(), target:arch(), config.mode(), "bin")

    -- copy the binary file to the output directory
    local targetfile = target:targetfile()
    os.mkdir(binarydir)
    os.vcp(targetfile, binarydir)
    os.trycp(target:symbolfile(), binarydir)

    -- generate xmake.lua
    local file = io.open(path.join(packagedir, "xmake.lua"), "w")
    if file then
        file:print([[package("%s")
    set_kind("binary")
    set_description("%s")
    on_load(function (package)
        package:set("installdir", path.join(os.scriptdir(), package:plat(), package:arch(), package:mode()))
    end)
    on_fetch(function (package)
        return {program = path.join(package:installdir("bin"), "%s")}
    end)]], packagename,
            "The " .. packagename .. " package",
            path.filename(targetfile))
        file:close()
    end
end

-- package library
function _package_library(target)

    -- get the output directory
    local outputdir   = option.get("outputdir") or config.buildir()
    local packagename = target:name():lower()
    if bit.band(packagename:byte(2), 0xc0) == 0x80 then
        wprint("package(%s): cannot generate package, becauese it contains unicode characters!", packagename)
        return
    end
    local packagedir  = path.join(outputdir, "packages", packagename:sub(1, 1), packagename)
    local binarydir   = path.join(packagedir, target:plat(), target:arch(), config.mode(), "bin")
    local librarydir  = path.join(packagedir, target:plat(), target:arch(), config.mode(), "lib")
    local headerdir   = path.join(packagedir, target:plat(), target:arch(), config.mode(), "include")

    -- copy the library file to the output directory
    local targetfile = target:targetfile()
    if target:is_shared() and target:is_plat("windows", "mingw") then
        os.mkdir(binarydir)
        os.vcp(targetfile, binarydir)
        os.trycp(target:symbolfile(), binarydir)
        local targetfile_lib = path.join(path.directory(targetfile), path.basename(targetfile) .. ".lib")
        if os.isfile(targetfile_lib) then
            os.mkdir(librarydir)
            os.vcp(targetfile_lib, librarydir)
        end
    else
        os.mkdir(librarydir)
        os.vcp(targetfile, librarydir)
        os.trycp(target:symbolfile(), librarydir)
    end

    -- copy headers
    local srcheaders, dstheaders = target:headerfiles(headerdir)
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

    -- generate xmake.lua
    local file = io.open(path.join(packagedir, "xmake.lua"), "w")
    if file then
        file:print([[package("%s")
    set_description("%s")
    on_load(function (package)
        package:set("installdir", path.join(os.scriptdir(), package:plat(), package:arch(), package:mode()))
    end)
    on_fetch(function (package)
        local result = {}
        result.links = "%s"
        result.linkdirs = package:installdir("lib")
        result.includedirs = package:installdir("include")
        return result
    end)]], packagename,
            "The " .. packagename .. " package",
            target:linkname(),
            path.filename(targetfile))
        file:close()
    end
end

-- do package target
function _do_package_target(target)
    if not target:is_phony() then
        local scripts =
        {
            binary = _package_binary
        ,   static = _package_library
        ,   shared = _package_library
        }
        local kind = target:kind()
        assert(scripts[kind], "this target(%s) with kind(%s) can not be packaged!", target:name(), kind)
        scripts[kind](target)
    end
end

-- package target
function _on_package_target(target)
    local done = false
    for _, r in ipairs(target:orderules()) do
        local on_package = r:script("package")
        if on_package then
            on_package(target)
            done = true
        end
    end
    if done then return end
    _do_package_target(target)
end

-- package the given target
function _package_target(target)

    -- has been disabled?
    if not target:is_enabled() then
        return
    end

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- enter the environments of the target packages
    local oldenvs = os.addenvs(target:pkgenvs())

    -- the target scripts
    local scripts =
    {
        target:script("package_before")
    ,   function (target)
            for _, r in ipairs(target:orderules()) do
                local before_package = r:script("package_before")
                if before_package then
                    before_package(target)
                end
            end
        end
    ,   target:script("package", _on_package_target)
    ,   function (target)
            for _, r in ipairs(target:orderules()) do
                local after_package = r:script("package_after")
                if after_package then
                    after_package(target)
                end
            end
        end
    ,   target:script("package_after")
    }

    -- package the target scripts
    for i = 1, 5 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end

    -- leave the environments of the target packages
    os.setenvs(oldenvs)

    -- leave project directory
    os.cd(oldir)
end

-- package the given targets
function _package_targets(targets)
    for _, target in ipairs(targets) do
        _package_target(target)
    end
end

-- main
function main()

    -- lock the whole project
    project.lock()

    -- get the target name
    local targetname = option.get("target")

    -- build it first
    task.run("build", {target = targetname, all = option.get("all")})

    -- package the given target?
    if targetname then
        local target = project.target(targetname)
        _package_targets(target:orderdeps())
        _package_target(target)
    else
        -- package default or all targets
        for _, target in ipairs(project.ordertargets()) do
            if target:is_default() or option.get("all") then
                _package_target(target)
            end
        end
    end

    -- unlock the whole project
    project.unlock()
end
