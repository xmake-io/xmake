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
import("core.project.project")
import("core.project.option")
import("core.package.package")
import("core.language.language")
import("core.sandbox.sandbox")
import("core.sandbox.module")
import("core.tool.toolchain")
import("core.base.interpreter")
import(".showlist")

function _is_callable(func)
    if type(func) == "function" then
        return true
    elseif type(func) == "table" then
        local meta = debug.getmetatable(func)
        if meta and meta.__call then
            return true
        end
    end
end

-- get target description scope apis
function description_target_scope_apis()
    local result = {}
    for _, names in pairs(target.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    return result
end

-- get language description scope apis
function description_language_scope_apis()
    local result = {}
    for _, names in pairs(language.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    return result
end

-- get option description scope apis
function description_option_scope_apis()
    local result = {}
    for _, names in pairs(option.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    return result
end

-- get rule description scope apis
function description_rule_scope_apis()
    local result = {}
    for _, names in pairs(rule.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    return result
end

-- get package description scope apis
function description_package_scope_apis()
    local result = {}
    for _, names in pairs(package.apis()) do
        for _, name in ipairs(names) do
            if type(name) == "table" then
                name = "package." .. name[1]
            end
            table.insert(result, name)
        end
    end
    return result
end

-- get toolchain description scope apis
function description_toolchain_scope_apis()
    local result = {}
    for _, names in pairs(toolchain.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    return result
end

-- get description scope apis
function description_scope_apis()
    local result = {}
    table.join2(result, description_target_scope_apis())
    table.join2(result, description_option_scope_apis())
    table.join2(result, description_language_scope_apis())
    table.join2(result, description_rule_scope_apis())
    table.join2(result, description_package_scope_apis())
    table.join2(result, description_toolchain_scope_apis())
    table.sort(result)
    return result
end

-- get description builtin apis
function description_builtin_apis()
    -- add builtin interpreter apis
    local builtin_module_apis = table.clone(interpreter.builtin_modules())
    builtin_module_apis.pairs = nil
    builtin_module_apis.ipairs = nil
    local result = {}
    for name, value in pairs(builtin_module_apis) do
        if type(value) == "function" then
            table.insert(result, name)
        end
    end
    table.insert(result, "ipairs")
    table.insert(result, "pairs")
    table.insert(result, "includes")
    table.insert(result, "set_xmakever")

    -- add root project apis
    for _, names in pairs(project.apis()) do
        for _, name in ipairs(names) do
            if type(name) == "table" then
                name = name[1]
            end
            table.insert(result, name)
        end
    end
    table.sort(result)
    return result
end

-- get description builtin module apis
function description_builtin_module_apis()
    local builtin_module_apis = table.clone(interpreter.builtin_modules())
    builtin_module_apis.pairs = nil
    builtin_module_apis.ipairs = nil
    local result = {}
    for name, value in pairs(builtin_module_apis) do
        if type(value) == "table" then
            for k, v in pairs(value) do
                if not k:startswith("_") and type(v) == "function" then
                    table.insert(result, name .. "." .. k)
                end
            end
        end
    end
    table.sort(result)
    return result
end

-- get script target instance apis
function script_target_instance_apis()
    local result = {}
    local instance = target.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "target:" .. k)
        end
    end
    return result
end

-- get script option instance apis
function script_option_instance_apis()
    local result = {}
    local instance = option.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "option:" .. k)
        end
    end
    return result
end

-- get script rule instance apis
function script_rule_instance_apis()
    local result = {}
    local instance = rule.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "rule:" .. k)
        end
    end
    return result
end

-- get script toolchain instance apis
function script_toolchain_instance_apis()
    local result = {}
    local instance = toolchain.load("clang")
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "toolchain:" .. k)
        end
    end
    return result
end

-- get script package instance apis
function script_package_instance_apis()
    local result = {}
    local instance = package.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "package:" .. k)
        end
    end
    return result
end

-- get script instance apis
function script_instance_apis()
    local result = {}
    table.join2(result, script_target_instance_apis())
    table.join2(result, script_option_instance_apis())
    table.join2(result, script_rule_instance_apis())
    table.join2(result, script_package_instance_apis())
    table.join2(result, script_toolchain_instance_apis())
    table.sort(result)
    return result
end

-- get script builtin apis
function script_builtin_apis()
    local builtin_module_apis = table.clone(sandbox.builtin_modules())
    builtin_module_apis.pairs = nil
    builtin_module_apis.ipairs = nil
    local result = {}
    for name, value in pairs(builtin_module_apis) do
        if type(value) == "function" then
            table.insert(result, name)
        end
    end
    table.insert(result, "ipairs")
    table.insert(result, "pairs")
    table.sort(result)
    return result
end

-- get script builtin module apis
function script_builtin_module_apis()
    local builtin_module_apis = table.clone(sandbox.builtin_modules())
    builtin_module_apis.pairs = nil
    builtin_module_apis.ipairs = nil
    local result = {}
    for name, value in pairs(builtin_module_apis) do
        if type(value) == "table" then
            for k, v in pairs(value) do
                if not k:startswith("_") and type(v) == "function" then
                    table.insert(result, name .. "." .. k)
                end
            end
        end
    end
    table.sort(result)
    return result
end

-- get script extension modules
function script_extension_module_apis()
    local result = {}
    local moduledirs = module.directories()
    for _, moduledir in ipairs(moduledirs) do
        moduledir = path.absolute(moduledir)
        local modulefiles = os.files(path.join(moduledir, "**.lua|**/xmake.lua|private/**.lua|core/tools/**.lua|detect/tools/**.lua"))
        if modulefiles then
            for _, modulefile in ipairs(modulefiles) do
                local modulename = path.relative(modulefile, moduledir)
                if path.filename(modulename) == "main.lua" then
                    modulename = path.directory(modulename)
                end
                modulename = modulename:gsub("[\\/]", "."):gsub("%.lua", "")
                local instance = import(modulename, {try = true, anonymous = true})
                if instance then
                    if _is_callable(instance) then
                        table.insert(result, modulename)
                    elseif type(instance) == "table" then
                        for k, v in pairs(instance) do
                            if not k:startswith("_") and type(v) == "function" then
                                table.insert(result, modulename .. "." .. k)
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(result)
    return result
end

-- get all apis
--
-- the api kind:
--  - description
--    - builtin api
--    - builtin module api
--    - scope api
--  - script
--    - builtin api
--    - builtin module api
--    - extension module api
--    - instance api
function apis()
    return {description_scope_apis = description_scope_apis(),
            description_builtin_apis = description_builtin_apis(),
            description_builtin_module_apis = description_builtin_module_apis(),
            script_builtin_apis = script_builtin_apis(),
            script_builtin_module_apis = script_builtin_module_apis(),
            script_extension_module_apis = script_extension_module_apis(),
            script_instance_apis = script_instance_apis()
        }
end

-- show all apis
function main()
    config.load()
    local result = apis()
    if result then
        showlist(result)
    end
end
