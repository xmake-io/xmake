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
-- @file        info.lua
--

-- imports
import("core.base.task")
import("core.base.option")
import("core.project.project")
import("impl.utils.filter")
import("impl.package")
import("impl.repository")
import("impl.environment")

-- from xmake/system/remote?
function _from(instance)
    local fetchinfo = instance:fetch()
    if fetchinfo then
        if instance:is3rd() then
            return ", ${green}3rd${clear}"
        elseif instance:isSys() then
            return ", ${green}system${clear}"
        else
            return ""
        end
    elseif #instance:urls() > 0 then
        return instance:supported() and format(", ${yellow}remote${clear}(in %s)", instance:repo():name()) or format(", ${yellow}remote${clear}(${red}unsupported${clear} in %s)", instance:repo():name())
    elseif instance:isSys() then
        return ", ${red}missing${clear}"
    else
        return ""
    end
end

-- get package info 
function _info(instance)
    local info = instance:version_str() and instance:version_str() or "no version"
    info = info .. _from(instance)
    info = info .. (instance:optional() and ", ${yellow}optional${clear}" or "")
    return info
end

-- show the given package info
function main(package_names)

    -- no package names?
    if not package_names then
        return 
    end

    -- enter environment 
    environment.enter()

    -- pull all repositories first if not exists
    if not repository.pulled() then
        task.run("repo", {update = true})
    end

    -- show title
    print("The package info of project:")

    -- get project requires 
    local project_requires, requires_extra = project.requires_str()
    if not project_requires then
        raise("requires(%s) not found in project!", table.concat(requires, " "))
    end

    -- find required package in project
    local requires = {}
    for _, name in ipairs(package_names) do
        for _, require_str in ipairs(project_requires) do
            if require_str:split(' ')[1]:lower():find(name:lower()) then
                table.insert(requires, require_str)
            end
        end
    end
    if #requires == 0 then
        raise("%s not found in project!", table.concat(package_names, " "))
    end

    -- list all packages
    for _, instance in ipairs(package.load_packages(requires, {requires_extra = requires_extra})) do

        -- show package name
        local requireinfo = instance:requireinfo() or {}
        cprint("    ${magenta}require${clear}(%s): ", requireinfo.originstr)

        -- show description
        local description = instance:get("description")
        if description then
            cprint("      -> ${magenta}description${clear}: %s", description)
        end

        -- show version
        local version = instance:version_str()
        if version then
            cprint("      -> ${magenta}version${clear}: %s", version)
        end

        -- show urls
        local urls = instance:urls()
        if urls and #urls > 0 then
            cprint("      -> ${magenta}urls${clear}:")
            for _, url in ipairs(urls) do
                print("         -> %s", filter.handle(url, instance))
                local sourcehash = instance:sourcehash(instance:url_alias(url))
                if sourcehash then
                    cprint("            -> ${yellow}%s${clear}", sourcehash)
                end
            end
        end

        -- show repository
        local repo = instance:repo()
        if repo then
            cprint("      -> ${magenta}repo${clear}: %s %s %s", repo:name(), repo:url(), repo:branch() or "")
        end

        -- show deps
        local deps = instance:orderdeps()
        if deps and #deps > 0 then
            cprint("      -> ${magenta}deps${clear}:")
            for _, dep in ipairs(deps) do
                requireinfo = dep:requireinfo() or {}
                cprint("         -> %s", requireinfo.originstr)
            end
        end

        -- show cache directory
        cprint("      -> ${magenta}cachedir${clear}: %s", instance:cachedir())

        -- show install directory
        cprint("      -> ${magenta}installdir${clear}: %s", instance:installdir())

        -- show fetch info
        cprint("      -> ${magenta}fetchinfo${clear}: %s", _info(instance))
        local fetchinfo = instance:fetch()
        if fetchinfo then
            for name, info in pairs(fetchinfo) do
                cprint("          -> ${magenta}%s${clear}: %s", name, table.concat(table.wrap(info), " "))
            end
        end

        -- show supported platforms
        local platforms = {}
        local on_install = instance:get("install")
        if type(on_install) == "table" then
            for plat, _ in pairs(on_install) do
                table.insert(platforms, plat)
            end
        else
            table.insert(platforms, "all")
        end
        cprint("      -> ${magenta}platforms${clear}: %s", table.concat(platforms, ", "))

        -- show requires
        cprint("      -> ${magenta}requires${clear}:")
        cprint("         -> ${cyan}plat${clear}: %s", instance:plat())
        cprint("         -> ${cyan}arch${clear}: %s", instance:arch())
        local configs_required = instance:configs()
        if configs_required then
            cprint("         -> ${cyan}configs${clear}:")
            for name, value in pairs(configs_required) do
                cprint("            -> %s: %s", name, value)
            end
        end

        -- show user configs
        local configs_defined = instance:get("configs")
        if configs_defined then
            cprint("      -> ${magenta}configs${clear}:")
            for _, conf in ipairs(configs_defined) do
                local configs_extra = instance:extraconf("configs", conf)
                if configs_extra and not configs_extra.builtin then
                    cprintf("         -> ${cyan}%s${clear}: ", conf)
                    if configs_extra.description then
                        printf(configs_extra.description)
                    end
                    if configs_extra.default ~= nil then
                        printf(" (default: %s)", configs_extra.default)
                    elseif configs_extra.type ~= nil and configs_extra.type ~= "string" then
                        printf(" (type: %s)", configs_extra.type)
                    end
                    print("")
                    if configs_extra.values then
                        cprint("            -> values: %s", string.serialize(configs_extra.values, true))
                    end
                end
            end
        end

        -- show builtin configs
        local configs_defined = instance:get("configs")
        if configs_defined then
            cprint("      -> ${magenta}configs (builtin)${clear}:")
            for _, conf in ipairs(configs_defined) do
                local configs_extra = instance:extraconf("configs", conf)
                if configs_extra and configs_extra.builtin then
                    cprintf("         -> ${cyan}%s${clear}: ", conf)
                    if configs_extra.description then
                        printf(configs_extra.description)
                    end
                    if configs_extra.default ~= nil then
                        printf(" (default: %s)", configs_extra.default)
                    elseif configs_extra.type ~= nil and configs_extra.type ~= "string" then
                        printf(" (type: %s)", configs_extra.type)
                    end
                    print("")
                    if configs_extra.values then
                        cprint("            -> values: %s", string.serialize(configs_extra.values, true))
                    end
                end
            end
        end

        -- show references
        local references = instance:references()
        if references then
            cprint("      -> ${magenta}references${clear}:")
            for projectdir, refdate in pairs(references) do
                cprint("         -> %s: %s%s", refdate, projectdir, os.isdir(projectdir) and "" or " ${red}(not found)${clear}")
            end
        end

        -- end
        print("")
    end

    -- leave environment
    environment.leave()
end

