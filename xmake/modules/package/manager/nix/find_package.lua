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

    for _, store_path in ipairs(store_paths) do
        if not seen[store_path] then
            seen[store_path] = true
            table.insert(all_paths, store_path)
        end
    end

    local i = 1
    while i <= #all_paths do
        local store_path = all_paths[i]
        if not visited[store_path] then
            visited[store_path] = true
            local prop_file = path.join(store_path, "nix-support", "propagated-build-inputs")
            if os.isfile(prop_file) then
                local content = try {function()
                    return io.readfile(prop_file):trim()
                end}
                if content and content ~= "" then
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

    paths = _follow_propagated_inputs(paths, opt)
    return paths
end

function _in_nix_shell()
    local in_nix_shell = os.getenv("IN_NIX_SHELL")
    return in_nix_shell == "pure" or in_nix_shell == "impure"
end

function _path_matches_package(store_path, package_name, opt)
    local path_name = path.basename(store_path)
    local package_name_lower = package_name:lower()
    local package_base = path_name:match("^[^%-]+-([^%-]+)")
    if package_base then
        local package_base_lower = package_base:lower()
        if package_base_lower == package_name_lower then
            return true
        end
        if package_base_lower:find(package_name_lower, 1, true) or package_name_lower:find(package_base_lower, 1, true) then
            return true
        end
    end
    return false
end

function _find_with_pkgconfig(package_name, store_paths, opt)
    for _, store_path in ipairs(store_paths) do
        local pkgconfig_dirs = {
            path.join(store_path, "lib", "pkgconfig"),
            path.join(store_path, "share", "pkgconfig")
        }
        
        for _, pcdir in ipairs(pkgconfig_dirs) do
            if os.isdir(pcdir) then
                if opt and (opt.verbose or option.get("verbose")) then
                    print("Nix: Attempting pkg-config lookup: " .. package_name .. " (configdirs=" .. pcdir .. ")")
                end
                local result = find_package_from_pkgconfig(package_name, {configdirs = pcdir})
                if result then
                    if opt and (opt.verbose or option.get("verbose")) then
                        print("Nix: Found package via pkg-config: " .. package_name)
                    end
                    return result
                end
            end
        end
    end
    return nil
end

function _extract_package_info(store_paths, package_name, opt)
    local result = {
        includedirs = {},
        bindirs = {},
        linkdirs = {},
        links = {},
        libfiles = {}
    }

    -- Try pkg-config first
    local pkgconfig_result = _find_with_pkgconfig(package_name, store_paths, opt)
    if pkgconfig_result then
        return pkgconfig_result
    end

    local main_package_paths = {}
    for _, store_path in ipairs(store_paths) do
        if _path_matches_package(store_path, package_name, opt) then
            table.insert(main_package_paths, store_path)
        end
    end

    -- Collect includedirs and linkdirs from all store paths
    for _, store_path in ipairs(store_paths) do
        local includedir = path.join(store_path, "include")
        if os.isdir(includedir) then
            table.insert(result.includedirs, includedir)
            local subdirs = try {function()
                return os.dirs(path.join(includedir, "*"))
            end} or {}
            for _, subdir in ipairs(subdirs) do
                if os.isdir(subdir) then
                    table.insert(result.includedirs, subdir)
                end
            end
        end
        local bindir = path.join(store_path, "bin")
        if os.isdir(bindir) then
            table.insert(result.bindirs, bindir)
        end
        local libdir = path.join(store_path, "lib")
        if os.isdir(libdir) then
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
                -- Only add links/libfiles for main package paths
                if _path_matches_package(store_path, package_name, opt) then
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
                end
            else
                local has_cmake = os.isdir(path.join(libdir, "cmake"))
                local has_pkgconfig = os.isdir(path.join(libdir, "pkgconfig"))
                if has_cmake or has_pkgconfig then
                    table.insert(result.linkdirs, libdir)
                end
            end
        end
    end

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
    if #main_package_paths > 0 and ((#result.links > 0) or (#result.libfiles > 0)) then
        return result
    else
        return nil
    end
end

function _find_in_nix_shell(package_name, opt)
    if not _in_nix_shell() then
        return nil
    end
    local build_env_vars = {
        "buildInputs",
        "nativeBuildInputs",
        "propagatedBuildInputs",
        "propagatedNativeBuildInputs"
    }
    local store_paths = _parse_store_paths_from_env(build_env_vars, opt)
    if #store_paths > 0 then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Found " .. #store_paths .. " total store paths in nix-shell")
        end
        local result = _extract_package_info(store_paths, package_name, opt)
        if result then
            if opt and (opt.verbose or option.get("verbose")) then
                print("Nix: Found " .. package_name .. " in nix-shell environment")
            end
            return result
        end
    end
    return nil
end

-- Find package from current user's nix profile, includes nix-env installed packages
-- Note: nix-env only lists one output in the profile list
-- $ nix-env -iA nixpkgs.<package> # installs multiple outputs, but only one is listed in the profile
-- this can cause issues if the main output does not contain the necessary files
-- Example: zlib.dev contains the headers, but zlib only contains the library
-- there does not seem to be an straight-forward way to find all outputs...
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
                    print("Found " .. package_name .. " in nix profile with " .. #store_paths .. " paths")
                end
                return result
            end
        end
    end
    return nil
end

-- Popular nix-community tool to declaratively manage user environments (NixOS and non-NixOS)
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

-- Home manager can be installed as a module in nixos, in which case the home-manager tool is missing.
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

-- nixos-option is not always configured properly, but if it is, we can find user/system packages
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

-- Includes all system/user/home-manager packages
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

function main(name, opt)
    opt = opt or {}
    if is_cross(opt.plat, opt.arch) then
        return
    end
    local actual_name = name
    local force_nix = false
    if name:startswith("nix::") then
        actual_name = name:sub(5)
        force_nix = true
    end
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
    if force_nix and opt and (opt.verbose or option.get("verbose")) then
        print("Nix: Package " .. actual_name .. " not found in any nix environment")
    end
    return nil
end