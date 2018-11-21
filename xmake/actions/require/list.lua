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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        list.lua
--

-- imports
import("core.project.project")
import("core.base.task")
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

-- list packages
function main()

    -- list all requires
    print("The package dependencies:")

    -- get requires 
    local requires, requires_extra = project.get("requires"), project.get("__extra_requires")
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
    for _, instance in ipairs(package.load_packages(requires, {requires_extra = requires_extra})) do
        cprint("    ${magenta}require${clear}(%s): %s", instance:requireinfo().originstr, _info(instance))
        for _, dep in ipairs(instance:orderdeps()) do
            cprint("      -> ${magenta}dep${clear}(%s): %s", dep:requireinfo().originstr, _info(dep))
        end
    end

    -- leave environment
    environment.leave()
end

