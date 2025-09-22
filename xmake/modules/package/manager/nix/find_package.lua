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
    local relevant_paths = {}
    for _, store_path in ipairs(store_paths) do
        if _path_matches_package(store_path, package_name, opt) then
            table.insert(relevant_paths, store_path)
        end
    end
    if #relevant_paths == 0 then
        return nil
    end
    local all_pkgconfig_dirs = {}
    local pkgconfig_env_additions = {}
    for _, store_path in ipairs(relevant_paths) do
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
    local original_pkg_config_path = os.getenv("PKG_CONFIG_PATH") or ""
    local new_pkg_config_path = table.concat(pkgconfig_env_additions, ":")
    if original_pkg_config_path ~= "" then
        new_pkg_config_path = new_pkg_config_path .. ":" .. original_pkg_config_path
    end
    os.setenv("PKG_CONFIG_PATH", new_pkg_config_path)
    local result = find_package_from_pkgconfig(package_name)
    if result then
        return result
    end
    for _, pkgconfig_dir in ipairs(all_pkgconfig_dirs) do
        local pc_files = try {function()
            return os.files(path.join(pkgconfig_dir, "*.pc"))
        end} or {}
        for _, pc_file in ipairs(pc_files) do
            local pc_name = path.basename(pc_file):match("^(.+)%.pc$")
            if pc_name then
                local name_lower = package_name:lower()
                local pc_lower = pc_name:lower()
                if pc_lower:find(name_lower, 1, true) or name_lower:find(pc_lower, 1, true) then
                    result = find_package_from_pkgconfig(pc_name)
                    if result then
                        break
                    end
                end
            end
        end
        if result then break end
    end
    return result
end

function _extract_package_info(store_paths, package_name, opt)
    local result = {
        includedirs = {},
        bindirs = {},
        linkdirs = {},
        links = {},
        libfiles = {}
    }
    local pkgconfig_result = _find_with_pkgconfig(package_name, store_paths, opt)
    if pkgconfig_result then
        return pkgconfig_result
    end
    local main_package_paths = {}
    local dependency_paths = {}
    local found_main_package = false
    for _, store_path in ipairs(store_paths) do
        if _path_matches_package(store_path, package_name, opt) then
            table.insert(main_package_paths, store_path)
            found_main_package = true
        else
            table.insert(dependency_paths, store_path)
        end
    end
    if not found_main_package then
        return nil
    end
    for _, store_path in ipairs(main_package_paths) do
        local includedir = path.join(store_path, "include")
        if os.isdir(includedir) then
            table.insert(result.includedirs, includedir)
            if opt and (opt.verbose or option.get("verbose")) then
                print("Nix: Found main package include dir: " .. includedir)
            end
            local subdirs = try {function()
                return os.dirs(path.join(includedir, "*"))
            end} or {}
            for _, subdir in ipairs(subdirs) do
                if os.isdir(subdir) then
                    table.insert(result.includedirs, subdir)
                    if opt and (opt.verbose or option.get("verbose")) then
                        print("Nix: Found main package include subdir: " .. subdir)
                    end
                end
            end
        end
        local bindir = path.join(store_path, "bin")
        if os.isdir(bindir) then
            table.insert(result.bindirs, bindir)
            if opt and (opt.verbose or option.get("verbose")) then
                print("Nix: Found main package bin dir: " .. bindir)
            end
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
                if opt and (opt.verbose or option.get("verbose")) then
                    print("Nix: Found main package lib dir: " .. libdir .. " (" .. #libfiles .. " libraries)")
                end
                for _, libfile in ipairs(libfiles) do
                    local filename = path.filename(libfile)
                    local linkname = filename:match("^lib(.+)%.so") or
                                   filename:match("^lib(.+)%.a") or
                                   filename:match("^lib(.+)%.dylib")
                    if linkname then
                        table.insert(result.links, linkname)
                        table.insert(result.libfiles, libfile)
                        if opt and (opt.verbose or option.get("verbose")) then
                            print("Nix: Found main package library: " .. linkname .. " -> " .. libfile)
                        end
                    end
                end
            else
                local has_cmake = os.isdir(path.join(libdir, "cmake"))
                local has_pkgconfig = os.isdir(path.join(libdir, "pkgconfig"))
                if has_cmake or has_pkgconfig then
                    table.insert(result.linkdirs, libdir)
                    if opt and (opt.verbose or option.get("verbose")) then
                        print("Nix: Found main package lib dir: " .. libdir .. " (cmake/pkgconfig only)")
                    end
                end
            end
        end
    end
    for _, store_path in ipairs(dependency_paths) do
        local includedir = path.join(store_path, "include")
        if os.isdir(includedir) then
            table.insert(result.includedirs, includedir)
            if opt and (opt.verbose or option.get("verbose")) then
                print("Nix: Found dependency include dir: " .. includedir)
            end
            local subdirs = try {function()
                return os.dirs(path.join(includedir, "*"))
            end} or {}
            for _, subdir in ipairs(subdirs) do
                if os.isdir(subdir) then
                    table.insert(result.includedirs, subdir)
                    if opt and (opt.verbose or option.get("verbose")) then
                        print("Nix: Found dependency include subdir: " .. subdir)
                    end
                end
            end
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
                if opt and (opt.verbose or option.get("verbose")) then
                    print("Nix: Found dependency lib dir: " .. libdir .. " (" .. #libfiles .. " libraries)")
                end
                for _, libfile in ipairs(libfiles) do
                    local filename = path.filename(libfile)
                    local linkname = filename:match("^lib(.+)%.so") or
                                   filename:match("^lib(.+)%.a") or
                                   filename:match("^lib(.+)%.dylib")
                    if linkname then
                        table.insert(result.links, linkname)
                        table.insert(result.libfiles, libfile)
                        if opt and (opt.verbose or option.get("verbose")) then
                            print("Nix: Found dependency library: " .. linkname .. " -> " .. libfile)
                        end
                    end
                end
            else
                local has_cmake = os.isdir(path.join(libdir, "cmake"))
                local has_pkgconfig = os.isdir(path.join(libdir, "pkgconfig"))
                if has_cmake or has_pkgconfig then
                    table.insert(result.linkdirs, libdir)
                    if opt and (opt.verbose or option.get("verbose")) then
                        print("Nix: Found dependency lib dir: " .. libdir .. " (cmake/pkgconfig only)")
                    end
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
    if (#result.includedirs > 0) or (#result.bindirs > 0) or (#result.links > 0) or (#result.linkdirs > 0) then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: DEBUG: Package info extraction succeeded for '" .. package_name .. "'")
            print("Nix: DEBUG: Found " .. #result.includedirs .. " include dirs, " ..
                  #result.bindirs .. " bin dirs, " .. #result.linkdirs .. " link dirs, " ..
                  #result.links .. " links")
            print("Nix: DEBUG: Main package paths: " .. #main_package_paths .. ", Dependency paths: " .. #dependency_paths)
        end
        return result
    else
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: DEBUG: Package info extraction found no useful information for '" .. package_name .. "'")
        end
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