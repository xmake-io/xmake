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
-- @author      JassJam
-- @file        csproj_generator.lua
--

import("properties", {rootdir = os.scriptdir(), alias = "csharp_properties"})
import("itemgroups", {rootdir = os.scriptdir(), alias = "csharp_itemgroups"})

function _xml_escape(value)
    value = tostring(value or "")
    value = value:gsub("&", "&amp;")
    value = value:gsub("<", "&lt;")
    value = value:gsub(">", "&gt;")
    value = value:gsub("\"", "&quot;")
    value = value:gsub("'", "&apos;")
    return value
end

function _format_attributes(attrs)
    if type(attrs) ~= "table" then
        return ""
    end
    local keys = {}
    for key, value in pairs(attrs) do
        if value ~= nil and value ~= "" then
            table.insert(keys, key)
        end
    end
    table.sort(keys)
    if #keys == 0 then
        return ""
    end
    local chunks = {}
    for _, key in ipairs(keys) do
        table.insert(chunks, string.format(" %s=\"%s\"", key, _xml_escape(attrs[key])))
    end
    return table.concat(chunks)
end

function _get_csharp_value(target, name, defaultval)
    local val = target:values(name)
    if type(val) == "table" then
        val = val[1]
    end
    if val == nil or val == "" then
        return defaultval
    end
    return val
end

function _resolve_registry_value(entry, target, context)
    if entry.resolve then
        return entry.resolve(context)
    end
    if entry.value_type == "list" then
        local values = table.wrap(target:values(entry.lua_key))
        if #values == 0 and entry.default ~= nil then
            values = table.wrap(entry.default)
        end
        if #values > 0 then
            local items = {}
            for _, value in ipairs(values) do
                if value ~= nil and value ~= "" then
                    table.insert(items, tostring(value))
                end
            end
            if #items > 0 then
                return table.concat(items, entry.sep or ";")
            end
        end
        return nil
    end
    return _get_csharp_value(target, entry.lua_key, entry.default)
end

function _collect_project_attributes(target, context, registry_entries)
    local attrs = {}
    for _, entry in ipairs(registry_entries) do
        if entry.kind == "project_attribute" then
            if not entry.when or entry.when(context) then
                local value = _resolve_registry_value(entry, target, context)
                if value ~= nil and value ~= "" then
                    attrs[entry.attr] = value
                end
            end
        end
    end
    return attrs
end

function _collect_property_entries(target, context, registry_entries)
    local entries = {}
    for _, entry in ipairs(registry_entries) do
        if entry.kind == "property" then
            if not entry.when or entry.when(context) then
                local value = _resolve_registry_value(entry, target, context)
                if value ~= nil and value ~= "" then
                    table.insert(entries, {xml = entry.xml, value = value})
                end
            end
        end
    end
    return entries
end

function _normalize_item_entry(item, default_xml)
    if type(item) == "string" then
        return {xml = default_xml, attrs = {Include = item}}
    elseif type(item) ~= "table" then
        return nil
    end
    local xml = item.xml or default_xml
    if not xml or #tostring(xml) == 0 then
        return nil
    end
    local attrs = item.attrs
    if type(attrs) ~= "table" then
        attrs = {}
        for key, value in pairs(item) do
            if type(key) == "string" and key ~= "xml" and key ~= "value" and key ~= "attrs" then
                attrs[key] = value
            end
        end
    end
    return {xml = xml, attrs = attrs, value = item.value}
end

function _collect_item_groups(context, registry_entries)
    local groups = {}
    local groupmap = {}
    function _group(name)
        local g = groupmap[name]
        if not g then
            g = {name = name, items = {}}
            groupmap[name] = g
            table.insert(groups, g)
        end
        return g
    end
    for _, entry in ipairs(registry_entries) do
        if entry.kind == "item" then
            if not entry.when or entry.when(context) then
                for _, item in ipairs(table.wrap(entry.resolve_items and entry.resolve_items(context) or {})) do
                    local normalized = _normalize_item_entry(item, entry.xml)
                    if normalized then
                        table.insert(_group(entry.group or entry.xml).items, normalized)
                    end
                end
            end
        end
    end
    return groups
end

function _is_valid_property_name(name)
    return type(name) == "string" and name:match("^[A-Za-z_][A-Za-z0-9_.-]*$") ~= nil
end

function _add_custom_property(entries, name, value)
    if not _is_valid_property_name(name) then
        return
    end
    if value == nil then
        return
    end
    if type(value) == "table" then
        local values = {}
        for _, v in ipairs(value) do
            if v ~= nil and v ~= "" then
                table.insert(values, tostring(v))
            end
        end
        if #values == 0 then
            return
        end
        value = table.concat(values, ";")
    else
        value = tostring(value)
    end
    if #value == 0 then
        return
    end
    table.insert(entries, {xml = name, value = value})
end

function _add_custom_properties_from_item(entries, item)
    if type(item) == "string" then
        local name, value = item:match("^%s*([^=]+)%s*=(.*)$")
        if name then
            _add_custom_property(entries, name:trim(), value)
        end
        return
    end
    if type(item) ~= "table" then
        return
    end
    if item.name then
        _add_custom_property(entries, tostring(item.name), item.value)
        return
    end
    local keys = {}
    for k in pairs(item) do
        if type(k) == "string" then
            table.insert(keys, k)
        end
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        _add_custom_property(entries, key, item[key])
    end
end

function _collect_custom_property_entries(target)
    local entries = {}
    for _, item in ipairs(table.wrap(target:values("csharp.properties"))) do
        _add_custom_properties_from_item(entries, item)
    end
    return entries
end

function _render_property_group(lines, entries)
    if #entries == 0 then
        return
    end
    table.insert(lines, "  <PropertyGroup>")
    for _, entry in ipairs(entries) do
        table.insert(lines, string.format("    <%s>%s</%s>", entry.xml, _xml_escape(entry.value), entry.xml))
    end
    table.insert(lines, "  </PropertyGroup>")
end

function _render_item_groups(lines, item_groups)
    for _, group in ipairs(item_groups) do
        if #group.items > 0 then
            table.insert(lines, "  <ItemGroup>")
            for _, item in ipairs(group.items) do
                local attrs = _format_attributes(item.attrs)
                if item.value ~= nil and item.value ~= "" then
                    table.insert(lines, string.format("    <%s%s>%s</%s>", item.xml, attrs, _xml_escape(item.value), item.xml))
                else
                    table.insert(lines, string.format("    <%s%s />", item.xml, attrs))
                end
            end
            table.insert(lines, "  </ItemGroup>")
        end
    end
end

function main(target, csprojfile, opt)
    opt = opt or {}
    
    local csprojdir = path.directory(csprojfile)
    local context = {
        target = target,
        csprojfile = csprojfile,
        csprojdir = csprojdir,
        opt = opt
    }

    local property_registry_entries = csharp_properties()
    local item_registry_entries = csharp_itemgroups()

    local project_attributes = _collect_project_attributes(target, context, property_registry_entries)
    local property_entries = _collect_property_entries(target, context, property_registry_entries)
    local custom_property_entries = _collect_custom_property_entries(target)
    table.join2(property_entries, custom_property_entries)

    local item_groups = _collect_item_groups(context, item_registry_entries)
    local lines = {}

    table.insert(lines, string.format("<Project%s>", _format_attributes(project_attributes)))
    _render_property_group(lines, property_entries)
    _render_item_groups(lines, item_groups)
    table.insert(lines, "</Project>")

    local content = table.concat(lines, "\n") .. "\n"

    os.mkdir(csprojdir)
    local oldcontent = nil
    if os.isfile(csprojfile) then
        oldcontent = io.readfile(csprojfile)
    end
    if oldcontent ~= content then
        io.writefile(csprojfile, content)
    end
end
