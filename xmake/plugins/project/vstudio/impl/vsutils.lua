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
-- @author      xq114
-- @file        vsutils.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.config")
import("core.project.project")
import("core.cache.memcache")
import("core.cache.localcache")

-- escape special chars in msbuild file
function escape(str)
    if not str then
        return nil
    end

    local map =
    {
         ["%"] = "%25" -- Referencing metadata
    ,    ["$"] = "%24" -- Referencing properties
    ,    ["@"] = "%40" -- Referencing item lists
    ,    ["'"] = "%27" -- Conditions and other expressions
    ,    [";"] = "%3B" -- List separator
    ,    ["?"] = "%3F" -- Wildcard character for file names in Include and Exclude attributes
    ,    ["*"] = "%2A" -- Wildcard character for use in file names in Include and Exclude attributes
    -- html entities
    ,    ["\""] = "&quot;"
    ,    ["<"] = "&lt;"
    ,    [">"] = "&gt;"
    ,    ["&"] = "&amp;"
    }

    return (string.gsub(str, "[%%%$@';%?%*\"<>&]", function (c) return assert(map[c]) end))
end

-- get vs arch
function vsarch(arch)
    if arch == 'x86' or arch == 'i386' then return "Win32" end
    if arch == 'x86_64' then return "x64" end
    if arch:startswith('arm64') then return "ARM64" end
    if arch:startswith('arm') then return "ARM" end
    return arch
end

-- translate file path (with namespace characters '::', it's invalid path characters on windows)
function translate_path(filepath)
    return (filepath:gsub("::", "#"))
end

-- get the source files that are not natively built by VS, e.g. files added by add_files but handled
-- by a custom rule. we list them as <None> in the project for display only (like add_extrafiles).
-- this must be consistent with vs201x_vcxproj._make_source_files.
-- @see https://github.com/xmake-io/xmake/issues/7619
function otherfiles(target)

    -- collect the source files that are natively built by VS
    local builtfiles = hashset.new()
    for _, targetinfo in ipairs(target.info or {}) do
        for _, sourcebatch in pairs(targetinfo.sourcebatches or {}) do
            local sourcekind = sourcebatch.sourcekind
            local rulename = sourcebatch.rulename
            if rulename == "c.build" or rulename == "c++.build" or rulename == "c++.build.modules"
                or sourcekind == "as" or sourcekind == "mrc" or sourcekind == "cu" then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    builtfiles:insert(sourcefile)
                end
            end
        end
    end

    -- exclude the header/extra files and the precompiled header to avoid duplicate display
    local excludefiles = hashset.from(table.join(target.headerfiles or {}, target.extrafiles or {}))
    if target.pcheader then
        excludefiles:insert(target.pcheader)
    end
    if target.pcxxheader then
        excludefiles:insert(target.pcxxheader)
    end

    -- the remaining source files are the custom files
    local results = {}
    for _, sourcefile in ipairs(target.sourcefiles or {}) do
        if not builtfiles:has(sourcefile) and not excludefiles:has(sourcefile) then
            table.insert(results, sourcefile)
        end
    end
    return results
end

function reset_config_and_caches(mode, arch)
    -- reload config, project and platform
    -- modify config
    config.set("as", nil, {force = true}) -- force to re-check as for ml/ml64
    config.set("mode", mode, {readonly = true, force = true})
    config.set("arch", arch, {readonly = true, force = true})

    -- clear all options
    for _, opt in pairs(project.options()) do
        if not config.readonly(opt:fullname()) then
            opt:clear()
        end
    end
    -- merge the project options after default options
    for name, value in pairs(project.get("config")) do
        local value = table.unwrap(value)
        assert(type(value) == "string" or type(value) == "boolean" or type(value) == "number", "set_config(%s): unsupported value type(%s)", name, type(value))
        if not config.readonly(name) then
            config.set(name, value)
        end
    end

    -- clear cache
    memcache.clear()
    localcache.clear("detect")
    localcache.clear("option")
    localcache.clear("package")
    localcache.clear("toolchain")
    localcache.clear("cxxmodules")
end
