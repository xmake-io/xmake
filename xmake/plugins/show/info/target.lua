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
-- @file        target.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.config")
import("core.language.language")
import("private.detect.check_targetname")

-- get source info string
function _get_sourceinfo_str(target, name, item, opt)
    opt = opt or {}
    local sourceinfo = target:sourceinfo(name, item)
    if sourceinfo then
        local tips = opt.tips
        if tips then
            tips = tips .. " -> "
        end
        return string.format(" ${dim}-> %s%s:%s${clear}", tips or "", sourceinfo.file or "", sourceinfo.line or -1)
    elseif opt.tips then
        return string.format(" ${dim}-> %s${clear}", opt.tips)
    end
    return ""
end

-- get values from target options
function _get_values_from_opts(target, name)
    local values = {}
    for _, opt_ in ipairs(target:orderopts()) do
        for _, value in ipairs(opt_:get(name)) do
            local tips = string.format("option(%s)", opt_:name())
            values[value] = _get_sourceinfo_str(opt_, name, value, {tips = tips})
        end
    end
    return values
end

-- get values from target packages
function _get_values_from_pkgs(target, name)
    local values = {}
    for _, pkg in ipairs(target:orderpkgs()) do
        local configinfo = target:pkgconfig(pkg:name())
        -- get values from package components
        -- e.g. `add_packages("sfml", {components = {"graphics", "window"}})`
        local selected_components = configinfo and configinfo.components or pkg:components_default()
        if selected_components and pkg:components() then
            local components_enabled = hashset.new()
            for _, comp in ipairs(table.wrap(selected_components)) do
                components_enabled:insert(comp)
                for _, dep in ipairs(table.wrap(pkg:component_orderdeps(comp))) do
                    components_enabled:insert(dep)
                end
            end
            components_enabled:insert("__base")
            -- if we can't find the values from the component, we need to fall back to __base to find them.
            -- it contains some common values of all components
            local components = table.wrap(pkg:components())
            for _, component_name in ipairs(table.join(pkg:components_orderlist(), "__base")) do
                if components_enabled:has(component_name) then
                    local info = components[component_name]
                    if info then
                        for _, value in ipairs(info[name]) do
                            values[value] = string.format(" -> package(%s)", pkg:fullname())
                        end
                    else
                        local components_str = table.concat(table.wrap(configinfo.components), ", ")
                        utils.warning("unknown component(%s) in add_packages(%s, {components = {%s}})", component_name, pkg:fullname(), components_str)
                    end
                end
            end
        -- get values instead of the builtin configs if exists extra package config
        -- e.g. `add_packages("xxx", {links = "xxx"})`
        elseif configinfo and configinfo[name] then
            for _, value in ipairs(configinfo[name]) do
                values[value] = _get_sourceinfo_str(target, "packages", pkg:name())
            end
        else
            -- get values from the builtin package configs
            for _, value in ipairs(pkg:get(name)) do
                values[value] = string.format(" -> package(%s)", pkg:fullname())
            end
        end
    end
    return values
end

-- get values from target dependencies
function _get_values_from_deps(target, name)
    local values = {}
    local orderdeps = target:orderdeps()
    local total = #orderdeps
    for idx, _ in ipairs(orderdeps) do
        local dep = orderdeps[total + 1 - idx]
        local depinherit = target:extraconf("deps", dep:name(), "inherit")
        if depinherit == nil or depinherit then
            for _, value in ipairs(dep:get(name, {interface = true})) do
                values[value] = string.format(" -> dep(%s)", dep:name())
            end
            local values_chunks = dep:get_from(name, "option::*", {interface = true})
            for _, values_chunk in ipairs(values_chunks) do
                for _, value in ipairs(values_chunk) do
                    values[value] = string.format(" -> dep(%s) -> options", dep:name())
                end
            end
            values_chunks = dep:get_from(name, "package::*", {interface = true})
            for _, values_chunk in ipairs(values_chunks) do
                for _, value in ipairs(values_chunk) do
                    values[value] = string.format(" -> dep(%s) -> packages", dep:name())
                end
            end
        end
    end
    return values
end

-- show target information
function _show_target(target)
    print("The information of target(%s):", target:name())
    cprint("    ${color.dump.string}at${clear}: %s", path.join(target:scriptdir(), "xmake.lua"))
    cprint("    ${color.dump.string}kind${clear}: %s", target:kind())
    cprint("    ${color.dump.string}targetfile${clear}: %s", target:targetfile())
    local deps = target:get("deps")
    if deps then
        cprint("    ${color.dump.string}deps${clear}:")
        for _, dep in ipairs(deps) do
            cprint("      ${color.dump.reference}->${clear} %s%s", dep, _get_sourceinfo_str(target, "deps", dep))
        end
    end
    local rules = target:get("rules")
    if rules then
        cprint("    ${color.dump.string}rules${clear}:")
        for _, value in ipairs(rules) do
            cprint("      ${color.dump.reference}->${clear} %s%s", value, _get_sourceinfo_str(target, "rules", value))
        end
    end
    local options = {}
    for _, opt in ipairs(target:get("options")) do
        if not opt:startswith("__") then
            table.insert(options, opt)
        end
    end
    if #options > 0 then
        cprint("    ${color.dump.string}options${clear}:")
        for _, value in ipairs(options) do
            cprint("      ${color.dump.reference}->${clear} %s%s", value, _get_sourceinfo_str(target, "options", value))
        end
    end
    local packages = target:get("packages")
    if packages then
        cprint("    ${color.dump.string}packages${clear}:")
        for _, value in ipairs(packages) do
            cprint("      ${color.dump.reference}->${clear} %s%s", value, _get_sourceinfo_str(target, "packages", value))
        end
    end
    for _, apiname in ipairs(table.join(language.apis().values, language.apis().paths)) do
        if apiname:startswith("target.") then
            local valuename = apiname:split('.add_', {plain = true})[2]
            if valuename then
                local results = {}
                local values = table.unique(table.wrap(target:get(valuename)))
                if #values > 0 then
                    for _, value in ipairs(values) do
                        table.insert(results, {value = value, sourceinfo = _get_sourceinfo_str(target, valuename, value)})
                    end
                end
                local values_from_opts = _get_values_from_opts(target, valuename)
                for value, sourceinfo in pairs(values_from_opts) do
                    table.insert(results, {value = value, sourceinfo = sourceinfo})
                end
                local values_from_pkgs = _get_values_from_pkgs(target, valuename)
                for value, sourceinfo in pairs(values_from_pkgs) do
                    table.insert(results, {value = value, sourceinfo = sourceinfo})
                end
                local values_from_deps = _get_values_from_deps(target, valuename)
                for value, sourceinfo in pairs(values_from_deps) do
                    table.insert(results, {value = value, sourceinfo = sourceinfo})
                end
                if #results > 0 then
                    cprint("    ${color.dump.string}%s${clear}:", valuename)
                    for _, result in ipairs(results) do
                        cprint("      ${color.dump.reference}->${clear} %s%s", result.value, result.sourceinfo)
                    end
                end
            end
        end
    end
    local files = target:get("files")
    if files then
        cprint("    ${color.dump.string}files${clear}:")
        for _, file in ipairs(files) do
            if not file:startswith("__remove_") then
                cprint("      ${color.dump.reference}->${clear} %s%s", file, _get_sourceinfo_str(target, "files", file))
            end
        end
    end
    local sourcekinds = hashset.new()
    for _, sourcebatch in pairs(target:sourcebatches()) do
        if sourcebatch.sourcekind then
            sourcekinds:insert(sourcebatch.sourcekind)
        end
    end
    for _, sourcekind in sourcekinds:keys() do
        local compinst = target:compiler(sourcekind)
        if compinst then
            cprint("    ${color.dump.string}compiler (%s)${clear}: %s", sourcekind, compinst:program())
            cprint("      ${color.dump.reference}->${clear} %s", os.args(compinst:compflags()))
        end
    end
    local linker = target:linker()
    if linker then
        cprint("    ${color.dump.string}linker (%s)${clear}: %s", linker:kind(), linker:program())
        cprint("      ${color.dump.reference}->${clear} %s", os.args(linker:linkflags()))
    end
    for _, sourcekind in sourcekinds:keys() do
        local compinst = target:compiler(sourcekind)
        if compinst then
            cprint("    ${color.dump.string}compflags (%s)${clear}:", sourcekind)
            cprint("      ${color.dump.reference}->${clear} %s", os.args(compinst:compflags({target = target})))
        end
    end
    local linker = target:linker()
    if linker then
        cprint("    ${color.dump.string}linkflags (%s)${clear}:", linker:kind())
        cprint("      ${color.dump.reference}->${clear} %s", os.args(linker:linkflags({target = target})))
    end
end

function main(name)

    -- get target
    config.load()
    local target = assert(check_targetname(name))

    -- show target information
    _show_target(target)
end
