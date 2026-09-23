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
-- @file        csproj.lua
--

-- imports
import("properties")
import("itemgroups")

-- escape special xml characters
function _xml_escape(value)
    value = tostring(value or "")
    value = value:gsub("&", "&amp;")
    value = value:gsub("<", "&lt;")
    value = value:gsub(">", "&gt;")
    value = value:gsub("\"", "&quot;")
    value = value:gsub("'", "&apos;")
    return value
end

-- format key-value pairs as xml attributes string, e.g. ` Sdk="Microsoft.NET.Sdk"`
function _format_attributes(attrs)
    if type(attrs) ~= "table" then
        return ""
    end
    local keys = {}
    for key, value in table.orderpairs(attrs) do
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

-- get single csharp value from target:values(), with default fallback
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

-- resolve a registry entry value, supports custom resolve function, list type and single value
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

-- collect <Project> element attributes, e.g. Sdk="Microsoft.NET.Sdk"
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

-- collect <PropertyGroup> entries from registered csharp.* properties
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

-- normalize item entry to {xml, attrs, value, children} format
-- `children`, if given, is a list of {xml, value} sub-elements rendered inside the item,
-- e.g. {xml = "Reference", attrs = {Include = "Foo"}, children = {{xml = "HintPath", value = "Foo.dll"}}}
-- renders as <Reference Include="Foo"><HintPath>Foo.dll</HintPath></Reference>
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
        for key, value in table.orderpairs(item) do
            if type(key) == "string" and key ~= "xml" and key ~= "value" and key ~= "attrs" and key ~= "children" then
                attrs[key] = value
            end
        end
    end
    return {xml = xml, attrs = attrs, value = item.value, children = item.children}
end

-- collect <ItemGroup> entries (Compile, ProjectReference, PackageReference, ..)
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

-- collect custom properties from target:values("csharp.properties")
-- value format: "Name=Value", e.g. set_values("csharp.properties", "MyProp=value")
function _collect_custom_property_entries(target)
    local entries = {}
    for _, item in ipairs(table.wrap(target:values("csharp.properties"))) do
        local name, value = tostring(item):match("^%s*([^=]+)%s*=(.*)$")
        if name and #value > 0 then
            table.insert(entries, {xml = name:trim(), value = value})
        end
    end
    return entries
end

-- render <PropertyGroup> section to file
function _render_property_group(file, entries)
    if #entries == 0 then
        return
    end
    file:print("  <PropertyGroup>")
    for _, entry in ipairs(entries) do
        file:print("    <%s>%s</%s>", entry.xml, _xml_escape(entry.value), entry.xml)
    end
    file:print("  </PropertyGroup>")
end

-- render <ItemGroup> sections to file
function _render_item_groups(file, item_groups)
    for _, group in ipairs(item_groups) do
        if #group.items > 0 then
            file:print("  <ItemGroup>")
            for _, item in ipairs(group.items) do
                local attrs = _format_attributes(item.attrs)
                if item.children and #item.children > 0 then
                    file:print("    <%s%s>", item.xml, attrs)
                    for _, child in ipairs(item.children) do
                        file:print("      <%s>%s</%s>", child.xml, _xml_escape(child.value), child.xml)
                    end
                    file:print("    </%s>", item.xml)
                elseif item.value ~= nil and item.value ~= "" then
                    file:print("    <%s%s>%s</%s>", item.xml, attrs, _xml_escape(item.value), item.xml)
                else
                    file:print("    <%s%s />", item.xml, attrs)
                end
            end
            file:print("  </ItemGroup>")
        end
    end
end

-- generate .csproj file for the target, write to tmpfile first then copy if different
function main(target, csprojfile, opt)
    opt = opt or {}

    local csprojdir = path.directory(csprojfile)
    local context = {
        target = target,
        csprojfile = csprojfile,
        csprojdir = csprojdir,
        opt = opt
    }

    -- collect project properties
    local property_registry_entries = properties()
    local item_registry_entries = itemgroups()

    local project_attributes = _collect_project_attributes(target, context, property_registry_entries)
    local property_entries = _collect_property_entries(target, context, property_registry_entries)
    local custom_property_entries = _collect_custom_property_entries(target)
    table.join2(property_entries, custom_property_entries)

    local item_groups = _collect_item_groups(context, item_registry_entries)

    -- generate csproj
    local tmpfile = os.tmpfile() .. ".csproj"
    local file = io.open(tmpfile, "w")
    file:print("<Project%s>", _format_attributes(project_attributes))
    _render_property_group(file, property_entries)
    _render_item_groups(file, item_groups)
    file:print("</Project>")
    file:close()

    os.mkdir(csprojdir)
    os.cp(tmpfile, csprojfile, {copy_if_different = true})
    os.rm(tmpfile)
end
