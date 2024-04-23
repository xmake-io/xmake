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

-- get target scope apis
function target_scope_apis()
    local result = {}
    for _, names in pairs(target.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    return result
end

-- get target instance apis
function target_instance_apis()
    local result = {}
    local instance = target.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "target:" .. k)
        end
    end
    return result
end

-- get option scope apis
function option_scope_apis()
    local result = {}
    for _, names in pairs(option.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    return result
end

-- get option instance apis
function option_instance_apis()
    local result = {}
    local instance = option.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "option:" .. k)
        end
    end
    return result
end

-- get rule scope apis
function rule_scope_apis()
    local result = {}
    for _, names in pairs(rule.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    return result
end

-- get rule instance apis
function rule_instance_apis()
    local result = {}
    local instance = rule.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "rule:" .. k)
        end
    end
    return result
end


-- get package scope apis
function package_scope_apis()
    local result = {}
    for _, names in pairs(package.apis()) do
        for _, name in ipairs(names) do
            if type(name) == "table" then
                name = name[1]
            end
            table.insert(result, name)
        end
    end
    return result
end

-- get package instance apis
function package_instance_apis()
    local result = {}
    local instance = package.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "package:" .. k)
        end
    end
    return result
end

-- get toolchain scope apis
function toolchain_scope_apis()
    local result = {}
    for _, names in pairs(toolchain.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    return result
end

-- get toolchain instance apis
function toolchain_instance_apis()
    local result = {}
    local instance = toolchain.load("clang")
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "toolchain:" .. k)
        end
    end
    return result
end

-- get scope apis
function scope_apis()
    local result = {}
    table.join2(result, target_scope_apis())
    table.join2(result, option_scope_apis())
    table.join2(result, rule_scope_apis())
    table.join2(result, package_scope_apis())
    table.join2(result, toolchain_scope_apis())
    table.sort(result)
    return result
end

-- get instance apis
function instance_apis()
    local result = {}
    table.join2(result, target_instance_apis())
    table.join2(result, option_instance_apis())
    table.join2(result, rule_instance_apis())
    table.join2(result, package_instance_apis())
    table.join2(result, toolchain_instance_apis())
    table.sort(result)
    return result
end

-- get all apis
function apis()
    return {scope = scope_apis(), instance = instance_apis()}
end

-- show all apis
function main()
    config.load()
    local result = apis()
    if result then
        showlist(result)
    end
end
