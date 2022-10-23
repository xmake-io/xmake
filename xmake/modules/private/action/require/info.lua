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
-- @file        info.lua
--

-- imports
import("core.base.task")
import("core.base.option")
import("core.base.hashset")
import("core.project.project")
import("core.package.package", {alias = "core_package"})
import("devel.git")
import("utils.archive")
import("private.action.require.impl.utils.filter")
import("private.action.require.impl.utils.url_filename")
import("private.action.require.impl.package")
import("private.action.require.impl.repository")
import("private.action.require.impl.environment")
import("private.action.require.impl.utils.get_requires")

-- from xmake/system/remote?
function _from(instance)
    local fetchinfo = instance:fetch()
    if fetchinfo then
        if instance:is_thirdparty() then
            return ", ${green}3rd${clear}"
        elseif instance:is_system() then
            return ", ${green}system${clear}"
        else
            return ""
        end
    elseif #instance:urls() > 0 then
        local repo = instance:repo()
        local reponame = repo and repo:name() or "unknown"
        return instance:is_supported() and format(", ${yellow}remote${clear}(in %s)", reponame) or format(", ${yellow}remote${clear}(${red}unsupported${clear} in %s)", reponame)
    elseif instance:is_system() then
        return ", ${red}missing${clear}"
    else
        return ""
    end
end

-- get package info
function _info(instance)
    local info = instance:version_str() and instance:version_str() or "no version"
    info = info .. _from(instance)
    info = info .. (instance:is_optional() and ", ${yellow}optional${clear}" or "")
    return info
end

-- show the given package info
function main(requires_raw)

    -- get requires and extra config
    local requires_extra = nil
    local requires, requires_extra = get_requires(requires_raw)
    if not requires or #requires == 0 then
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

    -- list all packages
    for _, instance in ipairs(package.load_packages(requires, {requires_extra = requires_extra})) do

        -- show package name
        local requireinfo = instance:requireinfo() or {}
        cprint("    ${color.dump.string_quote}require${clear}(%s): ", requireinfo.originstr)

        -- show description
        local description = instance:get("description")
        if description then
            cprint("      -> ${color.dump.string_quote}description${clear}: %s", description)
        end

        -- show version
        local version = instance:version_str()
        if version then
            cprint("      -> ${color.dump.string_quote}version${clear}: %s", version)
        end

        -- show license
        local license = instance:get("license")
        if license then
            cprint("      -> ${color.dump.string_quote}license${clear}: %s", license)
        end

        -- show urls
        local urls = instance:urls()
        if urls and #urls > 0 then
            cprint("      -> ${color.dump.string_quote}urls${clear}:")
            for _, url in ipairs(urls) do
                print("         -> %s", filter.handle(url, instance))
                if git.asgiturl(url) then
                    local url_alias = instance:url_alias(url)
                    cprint("            -> ${yellow}%s", instance:revision(url_alias) or instance:tag() or instance:version_str())
                else
                    local sourcehash = instance:sourcehash(instance:url_alias(url))
                    if sourcehash then
                        cprint("            -> ${yellow}%s", sourcehash)
                    end
                end
            end
        end

        -- show repository
        local repo = instance:repo()
        if repo then
            cprint("      -> ${color.dump.string_quote}repo${clear}: %s %s %s", repo:name(), repo:url(), repo:branch() or "")
        end

        -- show deps
        local deps = instance:orderdeps()
        if deps and #deps > 0 then
            cprint("      -> ${color.dump.string_quote}deps${clear}:")
            for _, dep in ipairs(deps) do
                requireinfo = dep:requireinfo() or {}
                cprint("         -> %s", requireinfo.originstr)
            end
        end

        -- show cache directory
        cprint("      -> ${color.dump.string_quote}cachedir${clear}: %s", instance:cachedir())

        -- show install directory
        cprint("      -> ${color.dump.string_quote}installdir${clear}: %s", instance:installdir())

        -- show search directories and search names
        cprint("      -> ${color.dump.string_quote}searchdirs${clear}: %s", table.concat(table.wrap(core_package.searchdirs()), path.envsep()))
        local searchnames = hashset.new()
        for _, url in ipairs(instance:urls()) do
            url = filter.handle(url, instance)
            if git.checkurl(url) then
                searchnames:insert(instance:name() .. archive.extension(url))
                searchnames:insert(path.basename(url_filename(url)))
            else
                local extension = archive.extension(url)
                if extension then
                    searchnames:insert(instance:name() .. "-" .. instance:version_str() .. extension)
                end
                searchnames:insert(url_filename(url))
            end
        end
        cprint("      -> ${color.dump.string_quote}searchnames${clear}: %s", table.concat(searchnames:to_array(), ", "))

        -- show fetch info
        cprint("      -> ${color.dump.string_quote}fetchinfo${clear}: %s", _info(instance))
        local fetchinfo = instance:fetch()
        if fetchinfo then
            for name, info in pairs(fetchinfo) do
                if type(info) ~= "table" then
                    info = tostring(info)
                end
                cprint("          -> ${color.dump.string_quote}%s${clear}: %s", name, table.concat(table.wrap(info), " "))
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
        cprint("      -> ${color.dump.string_quote}platforms${clear}: %s", table.concat(platforms, ", "))

        -- show requires
        cprint("      -> ${color.dump.string_quote}requires${clear}:")
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
            cprint("      -> ${color.dump.string_quote}configs${clear}:")
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
            cprint("      -> ${color.dump.string_quote}configs (builtin)${clear}:")
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

        -- show components
        local components = instance:get("components")
        if components then
            cprint("      -> ${color.dump.string_quote}components${clear}: ")
            for _, comp in ipairs(components) do
                cprintf("         -> ${cyan}%s${clear}: ", comp)
                local plaindeps = instance:extraconf("components", comp, "deps")
                if plaindeps then
                    print("%s", table.concat(table.wrap(plaindeps), ", "))
                else
                    print("")
                end
            end
        end

        -- show references
        local references = instance:references()
        if references then
            cprint("      -> ${color.dump.string_quote}references${clear}:")
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

