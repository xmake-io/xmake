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
-- @file        itemgroups.lua
--

-- normalize path to relative and use forward slashes
function _normalize_relative(fromdir, targetpath)
    local relpath = path.relative(targetpath, fromdir) or targetpath
    return path.unix(relpath)
end

-- collect .cs source files as relative paths to csprojdir
function _collect_cs_sourcefiles(context)
    local csfiles = {}
    for _, sourcefile in ipairs(context.target:sourcefiles()) do
        if path.extension(sourcefile):lower() == ".cs" then
            local sourceabs = path.is_absolute(sourcefile) and sourcefile or path.absolute(sourcefile, os.projectdir())
            table.insert(csfiles, _normalize_relative(context.csprojdir, sourceabs))
        end
    end
    table.sort(csfiles)
    return table.unique(csfiles)
end

-- collect ProjectReference paths from dependency targets
function _collect_project_references(context)
    local references = {}
    for _, dep in ipairs(context.target:orderdeps()) do
        local depcsproj = dep:data("csharp.csproj")
        if depcsproj then
            table.insert(references, _normalize_relative(context.csprojdir, depcsproj))
        end
    end
    table.sort(references)
    return table.unique(references)
end

-- extract nuget package name and version from package require string
function _get_nuget_info(pkg)
    local requirestr = pkg:requirestr() or ""
    local splitinfo = requirestr:trim():split("%s+")
    if #splitinfo == 0 then
        return nil
    end

    local pkgname = splitinfo[1]
    if pkgname:find("::", 1, true) then
        pkgname = pkgname:split("::", {plain = true})
        pkgname = pkgname[#pkgname]
    end
    local pkgname_raw = pkgname:match("(.-)%[.*%]$")
    if pkgname_raw and #pkgname_raw > 0 then
        pkgname = pkgname_raw
    end
    if not pkgname or #pkgname == 0 then
        return nil
    end

    local version
    local versionobj = pkg:version()
    if versionobj then
        version = tostring(versionobj)
    end
    if not version and #splitinfo > 1 then
        local require_version = table.concat(table.slice(splitinfo, 2), " ")
        if require_version ~= "latest" then
            version = require_version
        end
    end
    return pkgname, version
end

-- collect Reference entries (HintPath to prebuilt, non-NuGet assemblies) from csharp.references
-- e.g. set_values("csharp.references", "path/to/Foo.dll", "path/to/Bar.dll")
function _collect_assembly_references(context)
    local references = {}
    for _, refpath in ipairs(table.wrap(context.target:values("csharp.references"))) do
        refpath = tostring(refpath):trim()
        if #refpath > 0 then
            local refabs = path.is_absolute(refpath) and refpath or path.absolute(refpath, os.projectdir())
            table.insert(references, {name = path.basename(refabs), hintpath = _normalize_relative(context.csprojdir, refabs)})
        end
    end
    table.sort(references, function (a, b) return a.name < b.name end)
    return references
end

-- collect PackageReference entries from nuget packages
function _collect_nuget_references(context)
    local versions = {}
    for _, pkg in ipairs(context.target:orderpkgs()) do
        local namespace = pkg:namespace()
        local requirestr = pkg:requirestr() or ""
        if namespace == "nuget" or requirestr:startswith("nuget::") then
            local pkgname, version = _get_nuget_info(pkg)
            if pkgname then
                if version or versions[pkgname] == nil then
                    versions[pkgname] = version or false
                end
            end
        end
    end

    local references = {}
    for pkgname, version in table.orderpairs(versions) do
        table.insert(references, {name = pkgname, version = version or nil})
    end
    table.sort(references, function (a, b) return a.name < b.name end)
    return references
end

-- register all item group entries (Compile, ProjectReference, Reference, PackageReference)
function main()
    local entries = {}
    local function register(entry)
        table.insert(entries, entry)
    end

    register({
        kind = "item",
        group = "compile",
        xml = "Compile",
        resolve_items = function (context)
            local items = {}
            for _, sourcefile in ipairs(_collect_cs_sourcefiles(context)) do
                table.insert(items, {attrs = {Include = sourcefile}})
            end
            return items
        end
    })

    register({
        kind = "item",
        group = "project_reference",
        xml = "ProjectReference",
        resolve_items = function (context)
            local items = {}
            for _, reffile in ipairs(_collect_project_references(context)) do
                table.insert(items, {attrs = {Include = reffile}})
            end
            return items
        end
    })

    register({
        kind = "item",
        group = "reference",
        xml = "Reference",
        resolve_items = function (context)
            local items = {}
            for _, refinfo in ipairs(_collect_assembly_references(context)) do
                table.insert(items, {
                    attrs = {Include = refinfo.name},
                    children = {{xml = "HintPath", value = refinfo.hintpath}}
                })
            end
            return items
        end
    })

    register({
        kind = "item",
        group = "package_reference",
        xml = "PackageReference",
        resolve_items = function (context)
            local items = {}
            for _, pkginfo in ipairs(_collect_nuget_references(context)) do
                local attrs = {Include = pkginfo.name}
                if pkginfo.version then
                    attrs.Version = pkginfo.version
                end
                table.insert(items, {attrs = attrs})
            end
            return items
        end
    })

    return entries
end
