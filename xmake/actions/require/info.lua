--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
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

-- from local/global/system/remote?
function _from(instance)
    local fetchinfo, fetchfrom = instance:fetch()
    if fetchinfo then
        return ", ${green}" .. fetchfrom .. "${clear}"
    elseif #instance:urls() > 0 then
        return instance:supported() and format(", ${yellow}remote${clear}(in %s)", instance:repo():name()) or format(", ${yellow}remote${clear}(${red}unsupported${clear} in %s)", instance:repo():name())
    elseif instance:from("system") then
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
                local sha256 = instance:sha256(instance:url_alias(url))
                if sha256 then
                    cprint("            -> ${yellow}%s${clear}", sha256)
                end
            end
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

        -- show prefix directory
        cprint("      -> ${magenta}prefixdir${clear}: %s", instance:prefixdir())

        -- show prefix file
        cprint("      -> ${magenta}prefixfile${clear}: %s", instance:prefixfile())

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

        -- end
        print("")
    end

    -- leave environment
    environment.leave()
end

