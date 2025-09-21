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

-- recursively follow propagated build inputs
function _follow_propagated_inputs(store_paths, opt, visited)
    visited = visited or {}
    local all_paths = {}
    local seen = {}
    
    -- Add initial paths
    for _, store_path in ipairs(store_paths) do
        if not seen[store_path] then
            seen[store_path] = true
            table.insert(all_paths, store_path)
        end
    end
    
    -- Process each path
    local i = 1
    while i <= #all_paths do
        local store_path = all_paths[i]
        
        if not visited[store_path] then
            visited[store_path] = true
            
            -- Check for propagated-build-inputs file
            local prop_file = path.join(store_path, "nix-support", "propagated-build-inputs")
            if os.isfile(prop_file) then
                local content = try {function() 
                    return io.readfile(prop_file):trim()
                end}
                
                if content and content ~= "" then
                    -- Parse propagated paths
                    for prop_path in content:gmatch("%S+") do
                        if prop_path:startswith("/nix/store/") and not seen[prop_path] then
                            seen[prop_path] = true
                            table.insert(all_paths, prop_path)
                            if opt and (opt.verbose or option.get("verbose")) then
                                print("Nix: Added propagated: " .. prop_path)
                            end
                        end
                    end
                end
            end
        end
        
        i = i + 1
    end
    
    return all_paths
end

-- parse store paths from environment variables
function _parse_store_paths_from_env(env_vars, opt)
    local paths = {}
    local seen = {}
    
    if opt and (opt.verbose or option.get("verbose")) then
        print("Nix: Parsing store paths from environment variables")
    end
    
    for _, var_name in ipairs(env_vars) do
        local env_value = os.getenv(var_name) or ""
        
        if env_value ~= "" then
            -- Split by spaces and colons, extract store paths
            for item in env_value:gmatch("[^%s:]+") do
                if item:startswith("/nix/store/") then
                    local store_path = item:match("(/nix/store/[^/]+)")
                    if store_path and not seen[store_path] then
                        seen[store_path] = true
                        table.insert(paths, store_path)
                        if opt and (opt.verbose or option.get("verbose")) then
                            print("Nix: Found store path: " .. store_path)
                        end
                    end
                end
            end
        end
    end
    
    -- Follow propagated build inputs
    paths = _follow_propagated_inputs(paths, opt)
    
    return paths
end

-- check if we're in a nix-shell environment
function _in_nix_shell()
    local in_nix_shell = os.getenv("IN_NIX_SHELL")
    return in_nix_shell == "pure" or in_nix_shell == "impure"
end

-- group store paths by package base name
function _group_store_paths_by_package(store_paths, opt)
    local packages = {}
    
    for _, store_path in ipairs(store_paths) do
        if os.isdir(store_path) then
            local path_name = path.basename(store_path)
            
            -- Extract package name (everything before version or output suffix)
            -- Format: hash-packagename-version[-output]
            local package_base = path_name:match("^[^%-]+-([^%-]+)")
            if package_base then
                if not packages[package_base] then
                    packages[package_base] = {}
                end
                table.insert(packages[package_base], store_path)
            end
        end
    end
    
    return packages
end

-- pkg-config search that handles all outputs
function _find_with_pkgconfig(package_name, store_paths, opt)
    if opt and (opt.verbose or option.get("verbose")) then
        print("Nix: pkg-config search for " .. package_name)
    end
    
    -- Collect all pkg-config directories from all store paths
    local all_pkgconfig_dirs = {}
    local pkgconfig_env_additions = {}
    
    for _, store_path in ipairs(store_paths) do
        local pkgconfig_dirs = {
            path.join(store_path, "lib", "pkgconfig"),
            path.join(store_path, "share", "pkgconfig")
        }
        
        for _, pkgconfig_dir in ipairs(pkgconfig_dirs) do
            if os.isdir(pkgconfig_dir) then
                table.insert(all_pkgconfig_dirs, pkgconfig_dir)
                table.insert(pkgconfig_env_additions, pkgconfig_dir)
            end
        end
    end
    
    if #all_pkgconfig_dirs == 0 then
        return nil
    end
    
    -- Set up PKG_CONFIG_PATH environment for search
    local original_pkg_config_path = os.getenv("PKG_CONFIG_PATH") or ""
    local new_pkg_config_path = table.concat(pkgconfig_env_additions, ":")
    if original_pkg_config_path ~= "" then
        new_pkg_config_path = new_pkg_config_path .. ":" .. original_pkg_config_path
    end
    
    -- set PKG_CONFIG_PATH
    os.setenv("PKG_CONFIG_PATH", new_pkg_config_path)
    
    -- Try pkg-config with the enhanced path
    local result = nil
    
    -- First try direct package name
    result = find_package_from_pkgconfig(package_name)
    
    if not result then
        -- Try alternative names - check what .pc files actually exist
        for _, pkgconfig_dir in ipairs(all_pkgconfig_dirs) do
            local pc_files = try {function() 
                return os.files(path.join(pkgconfig_dir, "*.pc")) 
            end} or {}
            
            for _, pc_file in ipairs(pc_files) do
                local pc_name = path.basename(pc_file):match("^(.+)%.pc$")
                if pc_name then
                    local name_lower = package_name:lower()
                    local pc_lower = pc_name:lower()
                    
                    -- Check for partial matches
                    if pc_lower:find(name_lower, 1, true) or name_lower:find(pc_lower, 1, true) then
                        result = find_package_from_pkgconfig(pc_name)
                        if result then
                            if opt and (opt.verbose or option.get("verbose")) then
                                print("Nix: Found via pkg-config: " .. pc_name)
                            end
                            break
                        end
                    end
                end
            end
            if result then break end
        end
    end
    
    return result
end

-- extract package info from all outputs of a package
function _extract_package_info(store_paths, package_name, opt)
    local result = {
        includedirs = {},
        bindirs = {},
        linkdirs = {},
        links = {},
        libfiles = {}
    }
    
    -- Group paths by package
    local packages = _group_store_paths_by_package(store_paths, opt)
    
    -- Find matching package
    local matching_outputs = nil
    local search_name = package_name:lower()
    
    for pkg_name, outputs in pairs(packages) do
        local pkg_lower = pkg_name:lower()
        local name_in_pkg = pkg_lower:find(search_name, 1, true)
        local pkg_in_name = search_name:find(pkg_lower, 1, true)
        
        if name_in_pkg or pkg_in_name then
            matching_outputs = outputs
            if opt and (opt.verbose or option.get("verbose")) then
                print("Nix: Found package match: " .. pkg_name .. " (" .. #outputs .. " outputs)")
            end
            break
        end
    end
    
    -- Also check direct path name matches for cases where grouping fails
    if not matching_outputs then
        matching_outputs = {}
        for _, store_path in ipairs(store_paths) do
            local path_name = path.basename(store_path):lower()
            if path_name:find(search_name, 1, true) then
                table.insert(matching_outputs, store_path)
            end
        end
    end
    
    if not matching_outputs or #matching_outputs == 0 then
        return nil
    end
    
    -- Try pkg-config search first
    local pkgconfig_result = _find_with_pkgconfig(package_name, matching_outputs, opt)
    
    -- Process all outputs of the package
    for _, store_path in ipairs(matching_outputs) do
        -- Add include directories from any output that has them
        local includedir = path.join(store_path, "include")
        if os.isdir(includedir) then
            table.insert(result.includedirs, includedir)
            if opt and (opt.verbose or option.get("verbose")) then
                print("Nix: Found include dir: " .. includedir)
            end
        end
        
        -- Add bin directories from any output that has them
        local bindir = path.join(store_path, "bin")
        if os.isdir(bindir) then
            table.insert(result.bindirs, bindir)
            if opt and (opt.verbose or option.get("verbose")) then
                print("Nix: Found bin dir: " .. bindir)
            end
        end
        
        -- Add lib directories and scan for libraries from any output that has them
        local libdir = path.join(store_path, "lib")
        if os.isdir(libdir) then
            -- Check if this lib dir actually contains libraries (not just cmake/pkgconfig)
            local libfiles = try {function()
                local files = {}
                local so_files = os.files(path.join(libdir, "*.so*")) or {}
                local a_files = os.files(path.join(libdir, "*.a")) or {}
                local dylib_files = os.files(path.join(libdir, "*.dylib*")) or {}
                for _, f in ipairs(so_files) do table.insert(files, f) end
                for _, f in ipairs(a_files) do table.insert(files, f) end  
                for _, f in ipairs(dylib_files) do table.insert(files, f) end
                return files
            end} or {}
            
            if #libfiles > 0 then
                table.insert(result.linkdirs, libdir)
                if opt and (opt.verbose or option.get("verbose")) then
                    print("Nix: Found lib dir: " .. libdir .. " (" .. #libfiles .. " libraries)")
                end
                
                for _, libfile in ipairs(libfiles) do
                    local filename = path.filename(libfile)
                    local linkname = filename:match("^lib(.+)%.so") or 
                                   filename:match("^lib(.+)%.a") or 
                                   filename:match("^lib(.+)%.dylib")
                    
                    if linkname then
                        table.insert(result.links, linkname)
                        table.insert(result.libfiles, libfile)
                    end
                end
            else
                -- If no actual libraries but has cmake/pkgconfig, still add for potential cmake usage
                local has_cmake = os.isdir(path.join(libdir, "cmake"))
                local has_pkgconfig = os.isdir(path.join(libdir, "pkgconfig"))
                
                if has_cmake or has_pkgconfig then
                    table.insert(result.linkdirs, libdir)
                    if opt and (opt.verbose or option.get("verbose")) then
                        print("Nix: Found lib dir: " .. libdir .. " (cmake/pkgconfig only)")
                    end
                end
            end
        end
    end
    
    -- Merge pkg-config results if available (prioritize pkg-config results)
    if pkgconfig_result then
        -- Use pkg-config results preferentially, but supplement with discovered paths
        for _, incdir in ipairs(pkgconfig_result.includedirs or {}) do
            table.insert(result.includedirs, incdir)
        end
        for _, linkdir in ipairs(pkgconfig_result.linkdirs or {}) do
            table.insert(result.linkdirs, linkdir)
        end
        for _, link in ipairs(pkgconfig_result.links or {}) do
            table.insert(result.links, link)
        end
        
        -- Add any additional paths we found that pkg-config might have missed
        if pkgconfig_result.syslinks then
            for _, link in ipairs(pkgconfig_result.syslinks) do
                table.insert(result.links, link)
            end
        end
    end
    
    -- Remove duplicates
    local function remove_duplicates(arr)
        local seen = {}
        local clean = {}
        for _, item in ipairs(arr) do
            if not seen[item] then
                seen[item] = true
                table.insert(clean, item)
            end
        end
        return clean
    end
    
    result.includedirs = remove_duplicates(result.includedirs)
    result.bindirs = remove_duplicates(result.bindirs)
    result.linkdirs = remove_duplicates(result.linkdirs)
    result.links = remove_duplicates(result.links)
    result.libfiles = remove_duplicates(result.libfiles)
    
    -- Return result if we found anything useful
    if (#result.includedirs > 0) or (#result.bindirs > 0) or (#result.links > 0) or (#result.linkdirs > 0) then
        return result
    end
    
    return nil
end

-- priority 1: nix shell (flake or legacy)
function _find_in_nix_shell(package_name, opt)
    if not _in_nix_shell() then
        return nil
    end
    
    -- Parse buildInputs environment variables
    local build_env_vars = {
        "buildInputs",
        "nativeBuildInputs", 
        "propagatedBuildInputs",
        "propagatedNativeBuildInputs"
    }
    
    local store_paths = _parse_store_paths_from_env(build_env_vars, opt)
    if #store_paths > 0 then
        local result = _extract_package_info(store_paths, package_name, opt)
        if result then
            if opt and (opt.verbose or option.get("verbose")) then
                print("Found " .. package_name .. " in nix-shell environment with " .. #store_paths .. " paths")
            end
            return result
        end
    end
    
    return nil
end

-- priority 2: profile installs
function _find_in_nix_profile(package_name, opt)
    local nix = find_tool("nix")
    if not nix then
        return nil
    end
    
    local profile_list = try {function()
        return os.iorunv(nix.program, {"profile", "list", "--extra-experimental-features 'nix-command flakes'"}):trim()
    end}
    
    if profile_list then
        local store_paths = {}
        for line in profile_list:gmatch("[^\n]+") do
            -- Parse nix profile list output format
            local store_path = line:match("(/nix/store/[^%s]+)")
            if store_path then
                table.insert(store_paths, store_path)
            end
        end
        
        if #store_paths > 0 then
            -- Follow propagated inputs for profile packages too
            store_paths = _follow_propagated_inputs(store_paths, opt)
            local result = _extract_package_info(store_paths, package_name, opt)
            if result then
                if opt and (opt.verbose or option.get("verbose")) then
                    print("Found " .. package_name .. " in nix profile with " .. #store_paths .. " paths")
                end
                return result
            end
        end
    end
    
    return nil
end

-- priority 3: home-manager (with tool)
function _find_in_home_manager_tool(package_name, opt)
    local home_manager = find_tool("home-manager")
    if not home_manager then
        return nil
    end
    
    local hm_packages = try {function()
        return os.iorunv(home_manager.program, {"packages"}):trim()
    end}
    
    if hm_packages then
        local store_paths = {}
        for line in hm_packages:gmatch("[^\n]+") do
            local store_path = line:match("(/nix/store/[^%s]+)")
            if store_path then
                table.insert(store_paths, store_path)
            end
        end
        
        if #store_paths > 0 then
            store_paths = _follow_propagated_inputs(store_paths, opt)
            local result = _extract_package_info(store_paths, package_name, opt)
            if result then
                if opt and (opt.verbose or option.get("verbose")) then
                    print("Found " .. package_name .. " in home-manager with " .. #store_paths .. " paths")
                end
                return result
            end
        end
    end
    
    return nil
end

-- priority 4: home-manager (without tool)
function _find_in_home_manager_profile(package_name, opt)
    local nix_store = find_tool("nix-store")
    if not nix_store then
        return nil
    end
    
    local user = os.getenv("USER") or "unknown"
    local user_profile = "/etc/profiles/per-user/" .. user
    
    if not os.isdir(user_profile) then
        return nil
    end
    
    local requisites = try {function()
        return os.iorunv(nix_store.program, {"--query", "--requisites", user_profile}):trim()
    end}
    
    if requisites then
        local store_paths = {}
        for line in requisites:gmatch("[^\n]+") do
            if line:startswith("/nix/store/") then
                table.insert(store_paths, line)
            end
        end
        
        if #store_paths > 0 then
            -- Note: requisites already includes everything, no need to follow propagated inputs again
            local result = _extract_package_info(store_paths, package_name, opt)
            if result then
                if opt and (opt.verbose or option.get("verbose")) then
                    print("Found " .. package_name .. " in home-manager profile with " .. #store_paths .. " paths")
                end
                return result
            end
        end
    end
    
    return nil
end

-- priority 5: nixos user packages
function _find_in_nixos_user_packages(package_name, opt)
    local nixos_option = find_tool("nixos-option")
    if not nixos_option then
        return nil
    end
    
    local user = os.getenv("USER") or "unknown"
    local user_packages = try {function()
        return os.iorunv(nixos_option.program, {"users.users." .. user .. ".packages"}):trim()
    end}
    
    if user_packages then
        local store_paths = {}
        for store_path in user_packages:gmatch('(/nix/store/[^"\'%s]+)') do
            table.insert(store_paths, store_path)
        end
        
        if #store_paths > 0 then
            store_paths = _follow_propagated_inputs(store_paths, opt)
            local result = _extract_package_info(store_paths, package_name, opt)
            if result then
                if opt and (opt.verbose or option.get("verbose")) then
                    print("Found " .. package_name .. " in NixOS user packages with " .. #store_paths .. " paths")
                end
                return result
            end
        end
    end
    
    return nil
end

-- priority 6: nixos system packages
function _find_in_nixos_system_packages(package_name, opt)
    local nixos_option = find_tool("nixos-option")
    if not nixos_option then
        return nil
    end
    
    local system_packages = try {function()
        return os.iorunv(nixos_option.program, {"environment.systemPackages"}):trim()
    end}
    
    if system_packages then
        local store_paths = {}
        for store_path in system_packages:gmatch('(/nix/store/[^"\'%s]+)') do
            table.insert(store_paths, store_path)
        end
        
        if #store_paths > 0 then
            store_paths = _follow_propagated_inputs(store_paths, opt)
            local result = _extract_package_info(store_paths, package_name, opt)
            if result then
                if opt and (opt.verbose or option.get("verbose")) then
                    print("Found " .. package_name .. " in NixOS system packages with " .. #store_paths .. " paths")
                end
                return result
            end
        end
    end
    
    return nil
end

-- priority 7: nixos current system
function _find_in_nixos_current_system(package_name, opt)
    local nix_store = find_tool("nix-store")
    if not nix_store then
        return nil
    end
    
    if not os.isdir("/run/current-system") then
        return nil
    end
    
    local requisites = try {function()
        return os.iorunv(nix_store.program, {"--query", "--requisites", "/run/current-system"}):trim()
    end}
    
    if requisites then
        local store_paths = {}
        for line in requisites:gmatch("[^\n]+") do
            if line:startswith("/nix/store/") then
                table.insert(store_paths, line)
            end
        end
        
        if #store_paths > 0 then
            -- Note: requisites already includes everything, no need to follow propagated inputs again
            local result = _extract_package_info(store_paths, package_name, opt)
            if result then
                if opt and (opt.verbose or option.get("verbose")) then
                    print("Found " .. package_name .. " in NixOS current system with " .. #store_paths .. " paths")
                end
                return result
            end
        end
    end
    
    return nil
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
    
    -- Search priority chain
    local search_functions = {
        _find_in_nix_shell,
        _find_in_nix_profile,
        _find_in_home_manager_tool,
        _find_in_home_manager_profile,
        _find_in_nixos_user_packages,
        _find_in_nixos_system_packages,
        _find_in_nixos_current_system
    }
    
    for _, search_func in ipairs(search_functions) do
        local result = search_func(actual_name, opt)
        if result then
            return result
        end
    end
    
    -- No results found
    if force_nix and opt and (opt.verbose or option.get("verbose")) then
        print("Nix: Package " .. actual_name .. " not found in any nix environment")
    end
    
    return nil
end