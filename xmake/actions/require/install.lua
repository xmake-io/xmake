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
-- @file        package.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("core.project.project")
import("lib.detect.find_tool")
import("action")
import("package")
import("repository")
import("environment")

-- attach package to option
function _attach_to_option(instance, opt)

    -- disable this option if this package is optional and missing
    if _g.optional_missing[instance:fullname()] then
        opt:enable(false)
    else

        -- add this package info to option
        opt:add(instance:fetch())

        -- add all dependent packages info to option
        local orderdeps = instance:orderdeps()
        if orderdeps then
            local total = #orderdeps
            for idx, _ in ipairs(orderdeps) do
                local dep = orderdeps[total + 1 - idx]
                if dep then
                    opt:add((dep:fetch()))
                end
            end
        end
    end

    -- update option info to the cache file
    opt:save()
end

-- attach all packages to targets
function _attach_to_targets(packages)

    for _, instance in ipairs(packages) do
        if instance:kind() ~= "binary" then
            local opt = project.option(instance:fullname())
            if opt and opt:enabled() then
                _attach_to_option(instance, opt)
            end
        end
    end
end

-- check missing packages
function _check_missing_packages(packages)

    -- get all missing packages
    local packages_missing = {}
    local optional_missing = {}
    for _, instance in ipairs(packages) do
        if not instance:exists() and (#instance:urls() > 0 or instance:from("system")) then
            if instance:requireinfo().optional then
                optional_missing[instance:fullname()] = instance
            else
                table.insert(packages_missing, instance:fullname())
            end
        end
    end

    -- raise tips
    if #packages_missing > 0 then
        raise("The packages(%s) not found!", table.concat(packages_missing, ", "))
    end

    -- save the optional missing packages
    _g.optional_missing = optional_missing
end

-- get user confirm
function _get_confirm(packages)

    -- get confirm
    local confirm = option.get("yes")
    if confirm == nil then
    
        -- show tips
        cprint("${bright yellow}note: ${default yellow}try installing all required packages (pass -y to skip confirm)?")
        for _, instance in ipairs(packages) do
            if (option.get("force") or not instance:exists()) and (#instance:urls() > 0 or instance:script("install")) then 
                print("  -> %s %s", instance:fullname(), instance:version_str() or "")
            end
        end
        cprint("please input: y (y/n)")

        -- get answer
        io.flush()
        local answer = io.read()
        if answer == 'y' or answer == '' then
            confirm = true
        end
    end

    -- ok?
    return confirm
end

-- install packages
function _install_packages(requires)

    -- init requires
    local requires_extra = nil
    if not requires then
        requires, requires_extra = project.requires()
    end
    if not requires or #requires == 0 then
        return 
    end

    -- pull all repositories first if not exists
    --
    -- attempt to install git from the builtin-packages first if git not found
    --
    if find_tool("git") and not repository.pulled() then
        task.run("repo", {update = true})
    end

    -- load packages
    local packages = package.load_packages(requires, requires_extra)

    -- fetch packages from local first
    local packages_remote = {}
    if option.get("force") then 
        for _, instance in ipairs(packages) do
            if instance and #instance:urls() > 0 then
                table.insert(packages_remote, instance)
            end
        end
    else
        process.runjobs(function (index)
            local instance = packages[index]
            if instance and not instance:fetch() and #instance:urls() > 0 then -- @note fetch first for only system packge 
                table.insert(packages_remote, instance)
            end
        end, #packages)
    end

    -- get user confirm
    if not _get_confirm(packages) then
        return 
    end

    -- download remote packages
    local waitindex = 0
    local waitchars = {'\\', '|', '/', '-'}
    process.runjobs(function (index)

        local instance = packages_remote[index]
        if instance then
            action.download(instance)
        end

    end, #packages_remote, ifelse(option.get("verbose"), 1, 4), 300, function (indices) 

        -- do not print progress info if be verbose 
        if option.get("verbose") then
            return 
        end
 
        -- update waitchar index
        waitindex = ((waitindex + 1) % #waitchars)

        -- make downloading packages list
        local downloading = {}
        for _, index in ipairs(indices) do
            local instance = packages_remote[index]
            if instance then
                table.insert(downloading, instance:fullname())
            end
        end
       
        -- trace
        cprintf("\r${yellow}  => ${clear}downloading %s .. %s", table.concat(downloading, ", "), waitchars[waitindex + 1])
        io.flush()
    end)

    -- install all required packages from repositories
    for _, instance in ipairs(packages) do
        if (option.get("force") or not instance:exists()) and (#instance:urls() > 0 or instance:script("install")) then 
            action.install(instance)
        end
    end
end

-- install packages
function main(requires)

    -- avoid to run this task repeatly
    if _g.installed then return end
    _g.installed = true

    -- TODO move the global modules
    -- enter environment 
    environment.enter()

    -- git not found? install it first
    if not find_tool("git") then
        _install_packages("git")
    end

    -- install packages
    _install_packages(requires)

    -- check missing packages
    _check_missing_packages(packages)

    -- attach required local package to targets
    _attach_to_targets(packages)

    -- leave environment
    environment.leave()
end

