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
-- @file        find_package.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")
import("private.core.base.is_cross")
import("package.manager.pkgconfig.find_package", {alias = "find_package_from_pkgconfig"})

-- check if we're in a nix-shell environment
function _in_nix_shell()
    local in_nix_shell = os.getenv("IN_NIX_SHELL")
    return in_nix_shell == "pure" or in_nix_shell == "impure"
end

-- extract store paths from nix environment variables with better filtering
function _extract_nix_store_paths(env_var_name, env_var_value)
    local paths = {}
    local seen = {}
    
    if env_var_value == "" then
        return paths
    end
    
    -- Handle different environment variable formats
    local separators = {
        PATH = ":",
        PKG_CONFIG_PATH = ":",
        LIBRARY_PATH = ":",
        LD_LIBRARY_PATH = ":",
        C_INCLUDE_PATH = ":",
        CPLUS_INCLUDE_PATH = ":",
        NIX_LDFLAGS = "%s",  -- space separated, may contain -L flags
        NIX_CFLAGS_COMPILE = "%s"  -- space separated, may contain -I flags
    }
    
    local separator = separators[env_var_name] or ":"
    local pattern = separator == ":" and "[^:]+" or "[^%s]+"
    
    for item in env_var_value:gmatch(pattern) do
        local clean_item = item
        
        -- Remove flag prefixes for compiler/linker flags
        if env_var_name == "NIX_LDFLAGS" then
            clean_item = item:gsub("^%-L", "")
        elseif env_var_name == "NIX_CFLAGS_COMPILE" then
            clean_item = item:gsub("^%-[iI]system%s*", ""):gsub("^%-I", "")
        end
        
        if clean_item:startswith("/nix/store/") then
            local store_path = clean_item:match("(/nix/store/[^/]+)")
            if store_path and not seen[store_path] then
                seen[store_path] = true
                table.insert(paths, store_path)
            end
        end
    end
    
    return paths
end

-- get current shell buildInputs from environment with improved detection
function _get_shell_build_inputs()
    local all_paths = {}
    local seen = {}
    
    if not _in_nix_shell() then
        return all_paths
    end
    
    -- Environment variables to check for nix store paths
    local env_vars = {
        "PATH",
        "PKG_CONFIG_PATH", 
        "LIBRARY_PATH",
        "LD_LIBRARY_PATH",
        "C_INCLUDE_PATH",
        "CPLUS_INCLUDE_PATH",
        "NIX_LDFLAGS",
        "NIX_CFLAGS_COMPILE"
    }
    
    for _, env_var in ipairs(env_vars) do
        local env_value = os.getenv(env_var) or ""
        local paths = _extract_nix_store_paths(env_var, env_value)
        
        for _, path in ipairs(paths) do
            if not seen[path] then
                seen[path] = true
                table.insert(all_paths, path)
            end
        end
    end
    
    return all_paths
end

-- get all nix store paths currently available in environment
function _get_available_nix_paths()
    local paths = {}
    local seen = {}
    
    -- First, get paths from current shell if we're in nix-shell
    if _in_nix_shell() then
        local shell_paths = _get_shell_build_inputs()
        for _, path in ipairs(shell_paths) do
            if not seen[path] then
                seen[path] = true
                table.insert(paths, path)
            end
        end
    end
    
    -- Get paths from environment PATH (additional check)
    local env_path = os.getenv("PATH") or ""
    
    for dir in env_path:gmatch("[^:]+") do
        if dir:startswith("/nix/store/") then
            local store_path = dir:match("(/nix/store/[^/]+)")
            if store_path and not seen[store_path] then
                seen[store_path] = true
                table.insert(paths, store_path)
            end
        end
    end
    
    -- Get paths from common Nix environment locations
    local env_locations = {
        os.getenv("NIX_PROFILES") or "",
        (os.getenv("HOME") or "") .. "/.nix-profile",
        "/nix/var/nix/profiles/default",
        "/run/current-system/sw" -- NixOS
    }
    
    for _, location in ipairs(env_locations) do
        if location ~= "" and os.isdir(location) then
            
            -- Check if it's a symlink to store path
            local target = try {function()
                return os.iorunv("readlink", {"-f", location}):trim()
            end}
            
            if target and target:startswith("/nix/store/") then
                local store_path = target:match("(/nix/store/[^/]+)")
                if store_path and not seen[store_path] then
                    seen[store_path] = true
                    table.insert(paths, store_path)
                end
            end
            
            -- Also check for manifest (generation info)
            local manifest = path.join(location, "manifest.nix")
            if os.isfile(manifest) then
                local manifest_content = io.readfile(manifest)
                
                if manifest_content then
                    -- Extract store paths from manifest
                    for store_path in manifest_content:gmatch('(/nix/store/[^"\'%s]+)') do
                        if not seen[store_path] then
                            seen[store_path] = true
                            table.insert(paths, store_path)
                        end
                    end
                end
            end
        end
    end

    return paths
end

-- check if a store path actually contains the requested package
function _validate_package_in_store_path(store_path, name)
    
    -- Check if the store path name contains the package name
    local store_name = path.basename(store_path):lower()
    local search_name = name:lower()
    
    -- Look for exact match, or package name in the store path
    local name_match = store_name:find(search_name, 1, true) or 
                      store_name:find((search_name:gsub("%-", "%%-"))) -- handle hyphens
    
    if name_match then
        return true
    end
    
    -- Check for libraries with the package name
    local libdir = path.join(store_path, "lib")
    if os.isdir(libdir) then
        local libfiles = os.files(path.join(libdir, "lib" .. name .. ".*"))
        if #libfiles > 0 then
            return true
        end
    end
    
    -- Check for pkg-config files
    local pkgconfigdirs = {
        path.join(store_path, "lib", "pkgconfig"),
        path.join(store_path, "share", "pkgconfig")
    }
    
    for _, pcdir in ipairs(pkgconfigdirs) do
        if os.isdir(pcdir) then
            local pcfiles = os.files(path.join(pcdir, name .. ".pc"))
            if #pcfiles > 0 then
                return true
            end
        end
    end

    return false
end

-- find package in a specific nix store path with validation
function _find_in_store_path(store_path, name)
    
    if not os.isdir(store_path) then
        return nil
    end
    
    -- First validate that this store path actually contains our package
    if not _validate_package_in_store_path(store_path, name) then
        return nil
    end
    
    local result = {}
    
    -- Find include directories
    local includedir = path.join(store_path, "include")
    if os.isdir(includedir) then
        result.includedirs = {includedir}
    end
    
    -- Find libraries
    local libdir = path.join(store_path, "lib")
    if os.isdir(libdir) then
        result.linkdirs = {libdir}
        result.links = {}
        result.libfiles = {}
        
        -- Scan for library files related to our package
        local libfiles = os.files(path.join(libdir, "*.so*"), 
                                path.join(libdir, "*.a"), 
                                path.join(libdir, "*.dylib*"))
        
        for _, libfile in ipairs(libfiles) do
            local filename = path.filename(libfile)
            local linkname = filename:match("^lib(.+)%.so") or 
                           filename:match("^lib(.+)%.a") or 
                           filename:match("^lib(.+)%.dylib")
            
            if linkname then
                if linkname == name or linkname:find(name, 1, true) then
                    table.insert(result.links, linkname)
                    table.insert(result.libfiles, libfile)
                end
                
                if filename:endswith(".a") then
                    result.static = true
                else
                    result.shared = true
                end
            end
        end
    end
    
    -- Find pkg-config files
    local pkgconfigdirs = {
        path.join(store_path, "lib", "pkgconfig"),
        path.join(store_path, "share", "pkgconfig")
    }
    
    for _, pcdir in ipairs(pkgconfigdirs) do
        if os.isdir(pcdir) then
            local pcfiles = os.files(path.join(pcdir, name .. ".pc"))
            if #pcfiles > 0 then
                -- Use pkg-config with configdirs
                local pcresult = find_package_from_pkgconfig(name, {configdirs = pcdir})
                
                if pcresult then
                    return pcresult
                end
            end
        end
    end
    
    -- Return result if we found anything useful
    if result.includedirs or (result.links and #result.links > 0) then
        return result
    end
    
    return nil
end

-- try to build package with modern nix (flakes)
function _try_modern_nix_build(name)
    local nix = find_tool("nix")
    if not nix then
        return nil
    end
    
    -- Try with flakes syntax
    local storepath = try {function()
        return os.iorunv(nix.program, {"build", "nixpkgs#" .. name, "--print-out-paths", "--no-link"}):trim()
    end}
    
    return storepath
end

-- try to build package with legacy nix
function _try_legacy_nix_build(name)
    local nix_build = find_tool("nix-build")
    if not nix_build then
        return nil
    end
    
    -- Try legacy nix-build
    local storepath = try {function()
        return os.iorunv(nix_build.program, {"<nixpkgs>", "-A", name, "--no-out-link"}):trim()
    end}
    
    return storepath
end

-- main find function
function main(name, opt)
    opt = opt or {}
    
    -- Check for cross compilation
    if is_cross(opt.plat, opt.arch) then
        return
    end
    
    -- Handle nix:: prefix
    local actual_name = name
    local force_nix = false
    if name:startswith("nix::") then
        actual_name = name:sub(6) -- Remove "nix::" prefix
        force_nix = true
    end
    
    -- Get all available Nix store paths
    local nix_paths = _get_available_nix_paths()
    
    -- Search through available paths first (prioritize shell environment)
    if #nix_paths > 0 then
        for i, store_path in ipairs(nix_paths) do
            local result = _find_in_store_path(store_path, actual_name)
            if result then
                if opt.verbose or option.get("verbose") then
                    print("Found " .. actual_name .. " in: " .. store_path)
                end
                return result
            end
        end
    end
    
    -- If not found in available paths and not in nix-shell, try building
    if not _in_nix_shell() or force_nix then
        local storepath = nil
        
        -- Try modern nix first
        storepath = _try_modern_nix_build(actual_name)
        
        -- Fallback to legacy nix-build
        if not storepath then
            storepath = _try_legacy_nix_build(actual_name)
        end
        
        if storepath and os.isdir(storepath) then
            local result = _find_in_store_path(storepath, actual_name)
            if result then
                if opt.verbose or option.get("verbose") then
                    print("Built and found " .. actual_name .. " in: " .. storepath)
                end
                return result
            end
        end
    end
    
    return nil
end