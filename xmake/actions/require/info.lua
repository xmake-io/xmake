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
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        info.lua
--

-- imports
import("core.base.task")
import("action.filter")
import("package")
import("repository")
import("environment")

-- show the given package info
function main(requires)

    -- no requires?
    if not requires then
        return 
    end

    -- enter environment 
    environment.enter()

    -- pull all repositories first if not exists
    if not repository.pulled() then
        task.run("repo", {update = true})
    end

    -- show title
    print("The package infos:")

    -- list all packages
    for _, instance in ipairs(package.load_packages(requires)) do

        -- show package name
        local requireinfo = instance:requireinfo() or {}
        cprint("    ${magenta}require${clear}(%s):", requireinfo.originstr)

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

        -- show install directory
        cprint("      -> ${magenta}installdir${clear}: %s", instance:installdir())
    end

    -- leave environment
    environment.leave()
end

