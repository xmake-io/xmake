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
import("rules.c++.modules.modules_support.compiler_support", {alias = "module_compiler_support", rootdir = os.programdir()})
import("rules.c++.modules.modules_support.builder", {alias = "module_builder", rootdir = os.programdir()})

-- get library deps
function _get_librarydeps(target)
    local librarydeps = {}
    for _, depname in ipairs(target:get("deps")) do
        local dep = project.target(depname)
        if not ((target:is_binary() or target:is_shared()) and dep:is_static()) then
            table.insert(librarydeps, dep:name():lower())
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
    local modulesdir  = path.join(packagedir, target:plat(), target:arch(), config.mode(), "modules")

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
        if os.islink(targetfile) then
            local targetfile_with_soname = os.readlink(targetfile)
            if not path.is_absolute(targetfile_with_soname) then
                targetfile_with_soname = path.join(target:targetdir(), targetfile_with_soname)
            end
            if os.islink(targetfile_with_soname) then
                local targetfile_with_version = os.readlink(targetfile_with_soname)
                if not path.is_absolute(targetfile_with_version) then
                    targetfile_with_version = path.join(target:targetdir(), targetfile_with_version)
                end
                os.vcp(targetfile_with_version, librarydir, {symlink = true, force = true})
            end
            os.vcp(targetfile_with_soname, librarydir, {symlink = true, force = true})
            os.vcp(targetfile, librarydir, {symlink = true, force = true})
        else
            os.vcp(targetfile, librarydir)
        end
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

    -- copy modules
    if target:data("cxx.has_modules") then

        local modules = module_compiler_support.localcache():get2(target:name(), "c++.modules")
        module_builder.generate_metadata(target, modules)

        local sourcebatch = target:sourcebatches()["c++.build.modules.install"]
        if sourcebatch and sourcebatch.sourcefiles then
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                local fileconfig = target:fileconfig(sourcefile)
                local install = fileconfig and fileconfig.public or false
                if install then
                    local modulehash = module_compiler_support.get_modulehash(target, sourcefile)
                    local prefixdir = path.join(modulesdir, modulehash)
                    os.vcp(sourcefile, path.join(prefixdir, path.filename(sourcefile)))
                    local metafile = module_compiler_support.get_metafile(target, sourcefile)
                    if os.exists(metafile) then
                        os.vcp(metafile, path.join(prefixdir, path.filename(metafile)))
                    end
                end
            end
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
        file:print("")
        if #deps > 0 then
            file:print("    add_deps(\"%s\")", table.concat(deps, "\", \""))
        end
        -- export packages as deps, @see https://github.com/xmake-io/xmake/issues/4202
        local interface
        if target:is_shared() then
            interface = true
        end
        for _, pkg in ipairs(target:orderpkgs({interface = interface})) do
            local requireconf_str
            local requireconf = pkg:requireconf()
            if requireconf then
                local conf = table.clone(requireconf)
                conf.alias = nil
                requireconf_str = string.serialize(conf, {indent = false, strip = true})
            end
            if requireconf_str and requireconf_str ~= "{}" then
                file:print("    add_deps(\"%s\", %s)", pkg:requirestr(), requireconf_str)
            else
                file:print("    add_deps(\"%s\")", pkg:requirestr())
            end
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

function _package_moduleonly(target)

    -- get the output directory
    local packagedir  = target:packagedir()
    local packagename = target:name():lower()
    local headerdir   = path.join(packagedir, target:plat(), target:arch(), config.mode(), "include")
    local modulesdir  = path.join(packagedir, target:plat(), target:arch(), config.mode(), "modules")

    local modules = module_compiler_support.localcache():get2(target:name(), "c++.modules")
    module_builder.generate_metadata(target, modules)

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

    -- copy modules
    local sourcebatch = target:sourcebatches()["c++.build.modules.install"]
    if sourcebatch and sourcebatch.sourcefiles then
        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
            local modulehash = module_compiler_support.get_modulehash(target, sourcefile)
            local prefixdir = path.join(modulesdir, modulehash)
            os.vcp(sourcefile, path.join(prefixdir, path.filename(sourcefile)))
            local metafile = module_compiler_support.get_metafile(target, sourcefile)
            if os.exists(metafile) then
                os.vcp(metafile, path.join(prefixdir, path.filename(metafile)))
            end
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
        ,   moduleonly = _package_moduleonly
        ,   headeronly = _package_headeronly
        }
        local kind = target:kind()
        local script = scripts[kind]
        if script then
            script(target)
        end
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
