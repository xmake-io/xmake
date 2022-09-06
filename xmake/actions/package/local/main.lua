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
import("core.base.bit")

-- get library deps
function _get_librarydeps(target)
    local librarydeps = {}
    for _, depname in ipairs(target:get("deps")) do
        local dep = project.target(depname)
        if not ((target:is_binary() or target:is_shared()) and dep:is_static()) then
            table.insert(librarydeps, dep:name())
        end
    end
    return librarydeps
end

-- package binary
function _package_binary(target)

    -- get the output directory
    local packagedir  = target:packagedir()
    local packagename = target:name():lower()
    local binarydir   = path.join(packagedir, target:plat(), target:arch(), config.mode(), "bin")

    -- copy the binary file to the output directory
    local targetfile = target:targetfile()
    os.mkdir(binarydir)
    os.vcp(targetfile, binarydir)
    os.trycp(target:symbolfile(), binarydir)

    -- generate xmake.lua
    local file = io.open(path.join(packagedir, "xmake.lua"), "w")
    if file then
        local deps = _get_librarydeps(target)
        file:print("package(\"%s\")", packagename)
        local homepage = option.get("homepage")
        if homepage then
            file:print("    set_homepage(\"%s\")", homepage)
        end
        local description = option.get("description") or ("The " .. packagename .. " package")
        file:print("    set_description(\"%s\")", description)
        if target:license() then
            file:print("    set_license(\"%s\")", target:license())
        end
        if #deps > 0 then
            file:print("    add_deps(\"%s\")", table.concat(deps, "\", \""))
        end
        file:print("")
        file:print([[
    on_load(function (package)
        package:set("installdir", path.join(os.scriptdir(), package:plat(), package:arch(), package:mode()))
    end)

    on_fetch(function (package)
        return {program = path.join(package:installdir("bin"), "%s")}
    end)]], #deps > 0 and ("add_deps(\"" .. table.concat(deps, "\", \"") .. "\")") or "",
            path.filename(targetfile))
        file:close()
    end

    -- show tips
    print("package(%s): %s generated", packagename, packagedir)
end

-- package library
function _package_library(target)

    -- get the output directory
    local packagedir  = target:packagedir()
    local packagename = target:name():lower()
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
        local deps = _get_librarydeps(target)
        file:print("package(\"%s\")", packagename)
        local homepage = option.get("homepage")
        if homepage then
            file:print("    set_homepage(\"%s\")", homepage)
        end
        local description = option.get("description") or ("The " .. packagename .. " package")
        file:print("    set_description(\"%s\")", description)
        if target:license() then
            file:print("    set_license(\"%s\")", target:license())
        end
        if #deps > 0 then
            file:print("    add_deps(\"%s\")", table.concat(deps, "\", \""))
        end
        file:print("")
        file:print([[
    add_configs("shared", {description = "Build shared library.", default = %s, type = "boolean", readonly = true})

    on_load(function (package)
        package:set("installdir", path.join(os.scriptdir(), package:plat(), package:arch(), package:mode()))
    end)

    on_fetch(function (package)
        local result = {}
        local libfiledir = (package:config("shared") and package:is_plat("windows", "mingw")) and "bin" or "lib"
        result.links = "%s"
        result.linkdirs = package:installdir("lib")
        result.includedirs = package:installdir("include")
        result.libfiles = path.join(package:installdir(libfiledir), "%s")
        return result
    end)]], target:is_shared() and "true" or "false",
            target:linkname(),
            path.filename(targetfile))
        file:close()
    end

    -- show tips
    print("package(%s): %s generated", packagename, packagedir)
end

-- package headeronly library
function _package_headeronly(target)

    -- get the output directory
    local packagedir  = target:packagedir()
    local packagename = target:name():lower()
    local headerdir   = path.join(packagedir, target:plat(), target:arch(), config.mode(), "include")

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
        local deps = _get_librarydeps(target)
        file:print("package(\"%s\")", packagename)
        local homepage = option.get("homepage")
        if homepage then
            file:print("    set_homepage(\"%s\")", homepage)
        end
        local description = option.get("description") or ("The " .. packagename .. " package")
        file:print("    set_description(\"%s\")", description)
        if target:license() then
            file:print("    set_license(\"%s\")", target:license())
        end
        if #deps > 0 then
            file:print("    add_deps(\"%s\")", table.concat(deps, "\", \""))
        end
        file:print("")
        file:print([[
    on_load(function (package)
        package:set("installdir", path.join(os.scriptdir(), package:plat(), package:arch(), package:mode()))
    end)

    on_fetch(function (package)
        local result = {}
        result.includedirs = package:installdir("include")
        return result
    end)]])
        file:close()
    end

    -- show tips
    print("package(%s): %s generated", packagename, packagedir)
end

-- do package target
function _do_package_target(target)
    if not target:is_phony() then
        local scripts =
        {
            binary     = _package_binary
        ,   static     = _package_library
        ,   shared     = _package_library
        ,   headeronly = _package_headeronly
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
