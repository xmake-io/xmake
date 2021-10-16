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

-- package library
function _package_library(target)

    -- the output directory
    local outputdir = option.get("outputdir") or config.buildir()

    -- the target name
    local targetname = target:name()

    -- copy the library file to the output directory
    if not target:is_headeronly() then
        os.vcp(target:targetfile(), format("%s/%s.pkg/$(plat)/$(arch)/lib/$(mode)/%s", outputdir, targetname, path.filename(target:targetfile())))

        -- copy the symbol file to the output directory
        local symbolfile = target:symbolfile()
        if os.isfile(symbolfile) then
            os.vcp(symbolfile, format("%s/%s.pkg/$(plat)/$(arch)/lib/$(mode)/%s", outputdir, targetname, path.filename(symbolfile)))
        end
    end

    -- copy *.lib for shared/windows (*.dll) target
    -- @see https://github.com/xmake-io/xmake/issues/787
    if target:is_shared() and target:is_plat("windows", "mingw") then
        local targetfile = target:targetfile()
        local targetfile_lib = path.join(path.directory(targetfile), path.basename(targetfile) .. ".lib")
        if os.isfile(targetfile_lib) then
            os.vcp(targetfile_lib, format("%s/%s.pkg/$(plat)/$(arch)/lib/$(mode)/", outputdir, targetname))
        end
    end

    -- copy the config.h to the output directory (deprecated)
    local configheader = target:configheader()
    if configheader then
        os.vcp(configheader, format("%s/%s.pkg/$(plat)/$(arch)/include/%s", outputdir, targetname, path.filename(configheader)))
    end

    -- copy headers
    local srcheaders, dstheaders = target:headerfiles(format("%s/%s.pkg/$(plat)/$(arch)/include", outputdir, targetname))
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

    -- make xmake.lua
    local file = io.open(format("%s/%s.pkg/xmake.lua", outputdir, targetname), "w")
    if file then
        file:print("option(\"%s\")", targetname)
        file:print("    set_showmenu(true)")
        file:print("    set_category(\"package\")")
        if not target:is_headeronly() then
            file:print("    add_links(\"%s\")", target:basename())
            file:write("    add_linkdirs(\"$(plat)/$(arch)/lib/$(mode)\")\n")
        end
        file:write("    add_includedirs(\"$(plat)/$(arch)/include\")\n")
        local languages = target:get("languages")
        if languages then
            file:print("    set_languages(\"%s\")", table.concat(table.wrap(languages), "\", \""))
        end
        file:close()
    end
end

-- do package target
function _do_package_target(target)
    if not target:is_phony() then
        local scripts =
        {
            binary     = function (target) end
        ,   static     = _package_library
        ,   shared     = _package_library
        ,   headeronly = _package_library
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
