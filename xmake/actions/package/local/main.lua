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
import("target.action.install")
import("private.detect.check_targetname")

-- get library deps
function _get_librarydeps(target)
    local librarydeps = {}
    for _, depname in ipairs(target:get("deps")) do
        local dep = project.target(depname, {namespace = target:namespace()})
        if not ((target:is_binary() or target:is_shared()) and dep:is_static()) then
            table.insert(librarydeps, dep:name():lower())
        end
    end
    return librarydeps
end

-- do package target
function _do_package_target(target)
    if target:is_phony() then
        return
    end

    -- do install
    local packagedir  = target:packagedir()
    local installdir  = path.join(packagedir, target:plat(), target:arch(), config.mode())
    install(target, {installdir = installdir, libdir = "lib", bindir = "bin", includedir = "include"})

    -- generate xmake.lua
    local packagename = target:name():lower()
    local file = io.open(path.join(packagedir, "xmake.lua"), "w")
    if file then
        file:print("package(\"%s\")", packagename)
        if target:is_binary() then
            file:print("    set_kind(\"binary\")")
        elseif target:is_headeronly() then
            file:print("    set_kind(\"library\", {headeronly = true})")
        elseif target:is_moduleonly() then
            file:print("    set_kind(\"library\", {moduleonly = true})")
        end
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
        local has_deps = false
        local deps = _get_librarydeps(target)
        if #deps > 0 then
            file:print("    add_deps(\"%s\")", table.concat(deps, "\", \""))
            has_deps = true
        end
        -- export packages as deps, @see https://github.com/xmake-io/xmake/issues/4202
        if target:is_library() then
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
                has_deps = true
            end
        end
        if has_deps then
            file:print("")
        end

        if target:is_library() and not target:is_headeronly() and not target:is_moduleonly() then
            file:print([[    add_configs("shared", {description = "Build shared library.", default = %s, type = "boolean", readonly = true})]], target:is_shared() and "true" or "false")
            file:print("")
        end
        file:print([[
    on_load(function (package)
        package:set("installdir", path.join(os.scriptdir(), package:plat(), package:arch(), package:mode()))
    end)
]])
        if target:is_binary() then
            file:print([[
    on_fetch(function (package)
        return {program = path.join(package:installdir("bin"), "%s")}
    end)]], path.filename(target:targetfile()))
        elseif target:is_headeronly() or target:is_moduleonly() then
            file:print([[
    on_fetch(function (package)
        local result = {}
        result.includedirs = package:installdir("include")
        return result
    end)]])
        elseif target:is_library() then
            file:print([[
    on_fetch(function (package)
        local result = {}
        local libfiledir = (package:config("shared") and package:is_plat("windows", "mingw")) and "bin" or "lib"
        result.links = "%s"
        result.linkdirs = package:installdir("lib")
        result.includedirs = package:installdir("include")
        result.libfiles = path.join(package:installdir(libfiledir), "%s")
        return result
    end)]], target:linkname(), path.filename(target:targetfile()))
        end

        file:close()
    end
    print("package(%s): %s generated", packagename, packagedir)
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
        local target = assert(check_targetname(targetname))
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
