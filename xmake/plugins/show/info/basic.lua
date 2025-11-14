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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        basic.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.base.json")
import("core.project.config")
import("core.project.project")
import("core.package.package")

function _show_xmake_info(opt, result)
    local json_enabled = opt and opt.json
    local info = {
        version = tostring(xmake.version()),
        host = {os = os.host(), arch = os.arch()},
        programdir = xmake.programdir(),
        programfile = xmake.programfile(),
        globaldir = global.directory(),
        tmpdir = os.tmpdir(),
        workingdir = os.workingdir(),
        packagedir = package.installdir(),
        packagedir_cache = package.cachedir()
    }
    if json_enabled then
        result = result or {}
        result.xmake = info
    else
        print("The information of xmake:")
        cprint("    ${color.dump.string}version${clear}: %s", info.version)
        cprint("    ${color.dump.string}host${clear}: %s/%s", info.host.os, info.host.arch)
        cprint("    ${color.dump.string}programdir${clear}: %s", info.programdir)
        cprint("    ${color.dump.string}programfile${clear}: %s", info.programfile)
        cprint("    ${color.dump.string}globaldir${clear}: %s", info.globaldir)
        cprint("    ${color.dump.string}tmpdir${clear}: %s", info.tmpdir)
        cprint("    ${color.dump.string}workingdir${clear}: %s", info.workingdir)
        cprint("    ${color.dump.string}packagedir${clear}: %s", info.packagedir)
        cprint("    ${color.dump.string}packagedir(cache)${clear}: %s", info.packagedir_cache)
        print("")
    end
    return result
end

function _show_project_info(opt, result)
    local json_enabled = opt and opt.json
    local projectfile = os.projectfile()
    if not os.isfile(projectfile) then
        return result
    end

    local info = {
        configdir = config.directory(),
        projectdir = os.projectdir(),
        projectfile = projectfile
    }
    local name = project.name()
    if name then
        info.name = name
    end
    local project_version = project.version()
    if project_version ~= nil then
        info.version = tostring(project_version)
    end
    local plat = config.plat()
    if plat then
        info.plat = plat
    end
    local arch = config.arch()
    if arch then
        info.arch = arch
    end
    local mode = config.mode()
    if mode then
        info.mode = mode
    end
    local builddir = config.builddir()
    if builddir then
        info.builddir = builddir
    end

    if json_enabled then
        result = result or {}
        result.project = info
    else
        print("The information of project: %s", info.name or "")
        if info.version then
            cprint("    ${color.dump.string}version${clear}: %s", info.version)
        end
        if info.plat then
            cprint("    ${color.dump.string}plat${clear}: %s", info.plat)
        end
        if info.arch then
            cprint("    ${color.dump.string}arch${clear}: %s", info.arch)
        end
        if info.mode then
            cprint("    ${color.dump.string}mode${clear}: %s", info.mode)
        end
        if info.builddir then
            cprint("    ${color.dump.string}builddir${clear}: %s", info.builddir)
        end
        cprint("    ${color.dump.string}configdir${clear}: %s", info.configdir)
        cprint("    ${color.dump.string}projectdir${clear}: %s", info.projectdir)
        cprint("    ${color.dump.string}projectfile${clear}: %s", info.projectfile)
        print("")
    end
    return result
end

-- show basic info
function main()

    config.load()

    local opt = {
        json = option.get("json"),
        pretty = option.get("pretty")
    }
    local result = opt.json and {} or nil

    result = _show_xmake_info(opt, result)
    result = _show_project_info(opt, result)

    if opt.json then
        local json_opt
        if opt.pretty then
            json_opt = {pretty = true, orderkeys = true}
        end
        print(json.encode(result or {}, json_opt))
    end
end
