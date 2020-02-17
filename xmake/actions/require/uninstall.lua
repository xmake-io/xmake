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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        uninstall.lua
--

-- imports
import("core.base.task")
import("core.base.option")
import("core.project.project")
import("impl.package")
import("impl.repository")
import("impl.environment")

-- get requires and extra config
function _get_requires(requires)

    -- init requires
    local requires_extra = nil
    if not requires then
        requires, requires_extra = project.requires_str()
    end
    if not requires or #requires == 0 then
        return 
    end

    -- get extra info
    local extra =  option.get("extra")
    local extrainfo = nil
    if extra then
        local v, err = string.deserialize(extra)
        if err then
            raise(err)
        else
            extrainfo = v
        end
    end

    -- force to use the given requires extra info
    if extrainfo then
        requires_extra = requires_extra or {}
        for _, require_str in ipairs(requires) do
            requires_extra[require_str] = extrainfo
        end
    end
    return requires, requires_extra
end

-- uninstall the given packages
function main(requires)

    -- enter environment 
    environment.enter()

    -- pull all repositories first if not exists
    if not repository.pulled() then
        task.run("repo", {update = true})
    end

    -- get requires and extra config
    local requires_extra = nil
    requires, requires_extra = _get_requires(requires)
    if not requires or #requires == 0 then
        raise("requires(%s) not found!", table.concat(requires, " "))
        return 
    end

    -- uninstall packages
    local packages = package.uninstall_packages(requires, {requires_extra = requires_extra})
    for _, instance in ipairs(packages) do
        print("uninstall: %s%s ok!", instance:name(), instance:version_str() and ("-" .. instance:version_str()) or "")
    end
    if #packages == 0 then
        print("local packages not found!")
    end

    -- leave environment
    environment.leave()
end

