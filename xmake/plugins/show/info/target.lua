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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        target.lua
--

-- imports
import("core.base.option")
import("core.base.json")
import("core.base.hashset")
import("core.project.config")
import("core.language.language")
import("private.detect.check_targetname")

-- get source info data
function _get_sourceinfo(target, name, item, opt)
    opt = opt or {}
    local sourceinfo = target:sourceinfo(name, item)
    local tips = opt.tips
    if sourceinfo then
        return {
            file = sourceinfo.file,
            line = sourceinfo.line,
            tips = tips
        }
    elseif tips then
        return {tips = tips}
    end
end

-- format source info string with color
function _format_sourceinfo(sourceinfo)
    if not sourceinfo then
        return ""
    end
    local tips = sourceinfo.tips
    if tips then
        tips = tips .. " -> "
    end
    if sourceinfo.file then
        return string.format(" ${dim}-> %s%s:%s${clear}", tips or "", sourceinfo.file or "", sourceinfo.line or -1)
    elseif tips then
        return string.format(" ${dim}-> %s${clear}", tips)
    end
    return ""
end

-- get source info string
function _get_sourceinfo_str(target, name, item, opt)
    return _format_sourceinfo(_get_sourceinfo(target, name, item, opt))
end

-- get values from target options
function _get_values_from_opts(target, name)
    local values = {}
    for _, opt_ in ipairs(target:orderopts()) do
        for _, value in ipairs(opt_:get(name)) do
            local tips = string.format("option(%s)", opt_:name())
            values[value] = _get_sourceinfo(opt_, name, value, {tips = tips})
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
                            local tips = string.format("package(%s)", pkg:fullname())
                            values[value] = {tips = tips}
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
                local sourceinfo = _get_sourceinfo(target, "packages", pkg:name())
                values[value] = sourceinfo
            end
        else
            -- get values from the builtin package configs
            for _, value in ipairs(pkg:get(name)) do
                local tips = string.format("package(%s)", pkg:fullname())
                values[value] = {tips = tips}
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
                local tips = string.format("dep(%s)", dep:name())
                values[value] = {tips = tips}
            end
            local values_chunks = dep:get_from(name, "option::*", {interface = true})
            for _, values_chunk in ipairs(values_chunks) do
                for _, value in ipairs(values_chunk) do
                    local tips = string.format("dep(%s) -> options", dep:name())
                    values[value] = {tips = tips}
                end
            end
            values_chunks = dep:get_from(name, "package::*", {interface = true})
            for _, values_chunk in ipairs(values_chunks) do
                for _, value in ipairs(values_chunk) do
                    local tips = string.format("dep(%s) -> packages", dep:name())
                    values[value] = {tips = tips}
                end
            end
        end
    end
    return values
end

function _collect_target_info(target)
    local info = {
        name = target:name(),
        at = path.join(target:scriptdir(), "xmake.lua"),
        kind = target:kind()
    }
    local targetfile = target:targetfile()
    if targetfile then
        info.targetfile = targetfile
    end
    local deps = target:get("deps")
    if deps then
        local entries = {}
        for _, dep in ipairs(deps) do
        local entry = {name = dep, source = _get_sourceinfo(target, "deps", dep)}
        table.insert(entries, entry)
        end
        if #entries > 0 then
            info.deps = entries
        end
    end
    local rules = target:get("rules")
    if rules then
        local entries = {}
        for _, value in ipairs(rules) do
        local entry = {name = value, source = _get_sourceinfo(target, "rules", value)}
        table.insert(entries, entry)
        end
        if #entries > 0 then
            info.rules = entries
        end
    end
    local options = {}
    for _, opt in ipairs(target:get("options")) do
        if not opt:startswith("__") then
            table.insert(options, opt)
        end
    end
    if #options > 0 then
        local entries = {}
        for _, value in ipairs(options) do
        table.insert(entries, {name = value, source = _get_sourceinfo(target, "options", value)})
        end
        if #entries > 0 then
            info.options = entries
        end
    end
    local packages = target:get("packages")
    if packages then
        local entries = {}
        for _, value in ipairs(packages) do
            table.insert(entries, {name = value, source = _get_sourceinfo(target, "packages", value)})
        end
        if #entries > 0 then
            info.packages = entries
        end
    end
    info.api_entries = {}
    for _, apiname in ipairs(table.join(language.apis().values, language.apis().paths)) do
        if apiname:startswith("target.") then
            local valuename = apiname:split('.add_', {plain = true})[2]
            if valuename then
                local results = {}
                local values = table.unique(table.wrap(target:get(valuename)))
                if #values > 0 then
                    for _, value in ipairs(values) do
                        local sourceinfo = _get_sourceinfo(target, valuename, value)
                table.insert(results, {value = value, source = sourceinfo})
                    end
                end
                local values_from_opts = _get_values_from_opts(target, valuename)
                for value, sourceinfo in pairs(values_from_opts) do
                    table.insert(results, {value = value, source = sourceinfo})
                end
                local values_from_pkgs = _get_values_from_pkgs(target, valuename)
                for value, sourceinfo in pairs(values_from_pkgs) do
                    table.insert(results, {value = value, source = sourceinfo})
                end
                local values_from_deps = _get_values_from_deps(target, valuename)
                for value, sourceinfo in pairs(values_from_deps) do
                    table.insert(results, {value = value, source = sourceinfo})
                end
                if #results > 0 then
                    local entries = {}
                    for _, result in ipairs(results) do
                        table.insert(entries, result)
                    end
                    info[valuename] = entries
                    table.insert(info.api_entries, {name = valuename, entries = entries})
                end
            end
        end
    end
    local files = target:get("files")
    if files then
        local entries = {}
        for _, file in ipairs(files) do
            if not file:startswith("__remove_") then
                table.insert(entries, {path = file, source = _get_sourceinfo(target, "files", file)})
            end
        end
        if #entries > 0 then
            info.files = entries
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
            info.compilers = info.compilers or {}
            table.insert(info.compilers, {
                sourcekind = sourcekind,
                program = compinst:program(),
                flags = os.args(compinst:compflags()),
                flags_with_target = os.args(compinst:compflags({target = target}))
            })
        end
    end
    local linker = targetfile and target:linker()
    if linker then
        info.linker = {
            kind = linker:kind(),
            program = linker:program(),
            flags = os.args(linker:linkflags()),
            flags_with_target = os.args(linker:linkflags({target = target}))
        }
    end
    return info
end

function _print_entries(label, items, formatter)
    if not items or #items == 0 then
        return
    end
    cprint("    ${color.dump.string}%s${clear}:", label)
    for _, item in ipairs(items) do
        local text, source = formatter(item)
        cprint("      ${color.dump.reference}->${clear} %s%s", text, source or "")
    end
end

function _print_target_info(info)
    print("The information of target(%s):", info.name)
    cprint("    ${color.dump.string}at${clear}: %s", info.at)
    cprint("    ${color.dump.string}kind${clear}: %s", info.kind)
    if info.targetfile then
        cprint("    ${color.dump.string}targetfile${clear}: %s", info.targetfile)
    end
    _print_entries("deps", info.deps, function(item)
        return item.name, _format_sourceinfo(item.source)
    end)
    _print_entries("rules", info.rules, function(item)
        return item.name, _format_sourceinfo(item.source)
    end)
    _print_entries("options", info.options, function(item)
        return item.name, _format_sourceinfo(item.source)
    end)
    _print_entries("packages", info.packages, function(item)
        return item.name, _format_sourceinfo(item.source)
    end)
    if info.api_entries then
        for _, entry in ipairs(info.api_entries) do
            _print_entries(entry.name, entry.entries, function(item)
                local source = _format_sourceinfo(item.source)
                return item.value, source
            end)
        end
    end
    if info.files then
        _print_entries("files", info.files, function(item)
            return item.path, _format_sourceinfo(item.source)
        end)
    end
    if info.compilers then
        for _, compiler in ipairs(info.compilers) do
            cprint("    ${color.dump.string}compiler (%s)${clear}: %s", compiler.sourcekind, compiler.program)
            if compiler.flags then
                cprint("      ${color.dump.reference}->${clear} %s", compiler.flags)
            end
        end
        for _, compiler in ipairs(info.compilers) do
            cprint("    ${color.dump.string}compflags (%s)${clear}:", compiler.sourcekind)
            cprint("      ${color.dump.reference}->${clear} %s", compiler.flags_with_target)
        end
    end
    if info.linker then
        cprint("    ${color.dump.string}linker (%s)${clear}: %s", info.linker.kind, info.linker.program)
        cprint("      ${color.dump.reference}->${clear} %s", info.linker.flags)
        cprint("    ${color.dump.string}linkflags (%s)${clear}:", info.linker.kind)
        cprint("      ${color.dump.reference}->${clear} %s", info.linker.flags_with_target)
    end
end

function main(name)

    -- get target
    config.load()
    local opt = {
        json = option.get("json"),
        pretty = option.get("pretty")
    }
    local target = assert(check_targetname(name))

    local info = _collect_target_info(target)
    if opt.json then
        info.api_entries = nil
        local json_opt
        if opt.pretty then
            json_opt = {pretty = true}
        end
        print(json.encode(info or {}, json_opt))
    else
        _print_target_info(info)
    end
end
