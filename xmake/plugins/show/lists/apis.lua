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
-- @file        apis.lua
--

-- imports
import("core.project.config")
import("core.project.rule")
import("core.project.target")
import("core.project.option")
import("core.package.package")
import("core.tool.toolchain")
import(".showlist")

-- get target apis
function target_apis()
    local result = {}
    for _, names in pairs(target.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    local instance = target.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "target:" .. k)
        end
    end
    return result
end

-- get option apis
function option_apis()
    local result = {}
    for _, names in pairs(option.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    local instance = option.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "option:" .. k)
        end
    end
    return result
end

-- get rule apis
function rule_apis()
    local result = {}
    for _, names in pairs(rule.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    local instance = rule.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "rule:" .. k)
        end
    end
    return result
end

-- get package apis
function package_apis()
    local result = {}
    for _, names in pairs(package.apis()) do
        for _, name in ipairs(names) do
            if type(name) == "table" then
                name = name[1]
            end
            table.insert(result, name)
        end
    end
    local instance = package.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "package:" .. k)
        end
    end
    return result
end

-- get toolchain apis
function toolchain_apis()
    local result = {}
    for _, names in pairs(toolchain.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    local instance = toolchain.load("clang")
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "toolchain:" .. k)
        end
    end
    return result
end

-- get all apis
function apis()
    local result = {}
    table.join2(result, target_apis())
    table.join2(result, option_apis())
    table.join2(result, rule_apis())
    table.join2(result, package_apis())
    table.join2(result, toolchain_apis())
    return result
end

-- show all apis
function main()
    config.load()
    local result = apis()
    if result then
        table.sort(result)
        showlist(result)
    end
end
