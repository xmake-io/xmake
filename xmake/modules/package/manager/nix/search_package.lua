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
-- @author      ZZBaron
-- @file        search_package.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- search packages using modern nix search
function _search_with_flakes(nix, name)
    local results = {}
    
    -- use nix search to find packages
    local searchdata = try {function ()
        return os.iorunv(nix.program, {"search", "nixpkgs", name, "--json"})
    end}
    
    if searchdata then
        -- parse JSON output
        local ok, data = try {function ()
            return json.decode(searchdata)
        end}
        
        if ok and data then
            for pkgname, pkginfo in pairs(data) do
                -- extract package name from the full path (e.g., "legacyPackages.x86_64-linux.cmake" -> "cmake")
                local simplename = pkgname:match("([^%.]+)$")
                if simplename and simplename:find(name, 1, true) then
                    table.insert(results, {
                        name = "nix::" .. simplename,
                        version = pkginfo.version or "unknown",
                        description = pkginfo.description or ""
                    })
                end
            end
        end
    end
    
    return results
end

-- search packages using legacy nix-env
function _search_with_env(name)
    local results = {}
    local nixenv = find_tool("nix-env")
    if not nixenv then
        return results
    end
    
    -- use nix-env to search for packages
    local searchdata = try {function ()
        return os.iorunv(nixenv.program, {"-qaP", "*" .. name .. "*"})
    end}
    
    if searchdata then
        -- parse nix-env output format:
        -- nixpkgs.cmake                                cmake-3.27.7
        -- nixpkgs.cmake-cursor                         cmake-cursor-0.2.1
        -- nixpkgs.cmakeWithGui                         cmake-3.27.7
        
        for _, line in ipairs(searchdata:split("\n", {plain = true})) do
            line = line:trim()
            if line ~= "" then
                local parts = line:split("%s+", {limit = 2})
                if #parts >= 2 then
                    local fullname = parts[1]
                    local version_desc = parts[2]
                    
                    -- extract simple package name
                    local pkgname = fullname:match("nixpkgs%.(.+)")
                    if pkgname and pkgname:find(name, 1, true) then
                        -- try to separate version from description
                        local version = version_desc:match("^([%d%.%-]+)")
                        local description = version_desc:gsub("^[%d%.%-]+%s*", "")
                        
                        table.insert(results, {
                            name = "nix::" .. pkgname,
                            version = version or "unknown",
                            description = description or ""
                        })
                    end
                end
            end
        end
    end
    
    return results
end

-- search package using the nix package manager
--
-- @param name  the package name with pattern
--
function main(name)
    -- find nix
    local nix = find_tool("nix")
    if not nix then
        raise("nix not found!")
    end
    
    -- check if we have flakes enabled (modern nix)
    local hasflakes = try {function ()
        return os.iorunv(nix.program, {"search", "--help"}, {stdout = os.nuldev()})
    end}
    
    local results = {}
    
    -- try modern search first
    if hasflakes then
        results = try {function ()
            return _search_with_flakes(nix, name)
        end} or {}
    end
    
    -- fallback to legacy search if modern search failed or returned no results
    if #results == 0 then
        results = try {function ()
            return _search_with_env(name)
        end} or {}
    end
    
    -- remove duplicates and sort
    local seen = {}
    local unique_results = {}
    for _, result in ipairs(results) do
        local key = result.name
        if not seen[key] then
            seen[key] = true
            table.insert(unique_results, result)
        end
    end
    
    -- sort by package name
    table.sort(unique_results, function(a, b)
        return a.name < b.name
    end)
    
    return unique_results
end