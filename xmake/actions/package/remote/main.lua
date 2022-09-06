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

-- package remote
function _package_remote(target)

    -- get the output directory
    local packagedir  = target:packagedir()
    local packagename = target:name():lower()

    -- generate xmake.lua
    local file = io.open(path.join(packagedir, "xmake.lua"), "w")
    if file then
        local deps = _get_librarydeps(target)
        file:print("package(\"%s\")", packagename)
        if target:is_binary() then
            file:print("    set_kind(\"binary\")")
        elseif target:is_headeronly() then
            file:print("    set_kind(\"library\", {headeronly = true})")
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
        if #deps > 0 then
            file:print("    add_deps(\"%s\")", table.concat(deps, "\", \""))
        end
        file:print("")
        local url = option.get("url") or "https://github.com/myrepo/foo.git"
        local version = option.get("version") or target:version() and (target:version()) or "1.0"
        local shasum = option.get("shasum") or "<shasum256 or gitcommit>"
        file:print("    add_urls(\"%s\")", url)
        file:print("    add_versions(\"%s\", \"%s\")", version, shasum)
        file:print("")
        file:print([[
    on_install(function (package)
        local configs = {}
        if package:config("shared") then
            configs.kind = "shared"
        end
        import("package.tools.xmake").install(package, configs)
    end)

    on_test(function (package)
        -- TODO check includes and interfaces
        -- assert(package:has_cfuncs("foo", {includes = "foo.h"})
    end)]])
        file:close()
    end

    -- show tips
    print("package(%s): %s generated", packagename, packagedir)
end

-- package target
function _package_target(target)
    if not target:is_phony() then
        local scripts =
        {
            binary     = _package_remote
        ,   static     = _package_remote
        ,   shared     = _package_remote
        ,   headeronly = _package_remote
        }
        local kind = target:kind()
        assert(scripts[kind], "this target(%s) with kind(%s) can not be packaged!", target:name(), kind)
        scripts[kind](target)
    end
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

    -- load config
    config.load()

    -- package the given target?
    local targetname = option.get("target")
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

