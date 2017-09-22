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
-- @file        list.lua
--

-- imports
import("core.project.project")
import("package")
import("repository")
import("environment")

-- from local/global/system/remote?
function _from(instance)
    local fetchinfo, fetchfrom = instance:fetch()
    if fetchinfo then
        return ", ${green}" .. fetchfrom .. "${clear}"
    elseif #instance:urls() > 0 then
        return ", ${yellow}remote${clear}"
    elseif instance:from("system") then
        return ", ${red}missing${clear}"
    else
        return ""
    end
end

-- list packages
function main()

    -- list all requires
    print("The package dependencies:")

    -- get requires 
    local requires, requires_extra = project.requires()
    if not requires or #requires == 0 then
        return 
    end

    -- enter environment 
    environment.enter()

    -- pull all repositories first if not exists
    if not repository.pulled() then
        task.run("repo", {update = true})
    end

    -- list all packages
    for _, instance in ipairs(package.load_packages(requires, requires_extra)) do
        local requireinfo = instance:requireinfo() or {}
        local packageopt  = project.option(instance:alias() or instance:fullname())
        if packageopt then
            cprint("    ${magenta}require${clear}(%s): %s%s%s", requireinfo.originstr, ifelse(instance:version_str(), instance:version_str(), "no version"), _from(instance), ifelse(requireinfo.optional, ", ${yellow}optional${clear}", ""))
            for _, dep in ipairs(instance:orderdeps()) do
                requireinfo = dep:requireinfo() or {}
                cprint("      -> ${magenta}dep${clear}(%s): %s%s%s", requireinfo.originstr, ifelse(dep:version_str(), dep:version_str(), "no version"), _from(dep), ifelse(requireinfo.optional, ", ${yellow}optional${clear}", ""))
            end
        end
    end

    -- leave environment
    environment.leave()
end

