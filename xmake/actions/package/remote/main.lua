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

-- package remote
function _package_remote(target)

    -- get the output directory
    local outputdir   = option.get("outputdir") or config.buildir()
    local packagename = target:name():lower()
    if bit.band(packagename:byte(2), 0xc0) == 0x80 then
        wprint("package(%s): cannot generate package, becauese it contains unicode characters!", packagename)
        return
    end
    local packagedir  = path.join(outputdir, "packages", packagename:sub(1, 1), packagename)

    -- generate xmake.lua
    local file = io.open(path.join(packagedir, "xmake.lua"), "w")
    if file then
        local deps = {}
        for _, dep in ipairs(target:orderdeps()) do
            table.insert(deps, dep:name())
        end
        file:print("package(\"%s\")", packagename)
        if target:is_binary() then
            file:print("    set_kind(\"binary\")")
        end
        file:print("    set_description(\"%s\")", "The " .. packagename .. " package")
        if target:license() then
            file:print("    set_license(\"%s\")", target:license())
        end
        if #deps > 0 then
            file:print("    set_deps(\"%s\")", table.concat(deps, "\", \""))
        end
        file:print("")
        file:print([[
    add_urls("https://github.com/myrepo/foo.git")
    add_versions("%s", "<shasum256 or gitcommit>")

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
    end)]], target:version() and (target:version()) or "1.0")
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
            binary = _package_remote
        ,   static = _package_remote
        ,   shared = _package_remote
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

