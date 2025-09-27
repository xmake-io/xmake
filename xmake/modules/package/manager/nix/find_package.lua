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
import("core.cache.globalcache")
import("core.cache.memcache")
import("core.base.json")

-- cache keys
local STORE_PATHS_CACHE = "nix_store_paths"
local PACKAGE_INFO_CACHE = "nix_package_info"
local PROPAGATED_CACHE = "nix_propagated"
local PKGCONFIG_CACHE = "nix_pkgconfig"
local DERIVATION_CACHE = "nix_derivation_info"

-- get nix cache instance
local function get_nix_cache()
    return globalcache.cache("nix_packages")
end

-- get memory cache for current session
local function get_memory_cache()
    return memcache.cache("nix_session")
end

-- check if we're in a nix shell
local function is_in_nix_shell()
    local in_nix_shell = os.getenv("IN_NIX_SHELL")
    return in_nix_shell == "pure" or in_nix_shell == "impure"
end

-- generate cache key for environment state
local function generate_env_cache_key()
    local env_vars = {
        "buildInputs",
        "nativeBuildInputs", 
        "propagatedBuildInputs",
        "propagatedNativeBuildInputs"
    }
    
    local env_data = {}
    for _, var in ipairs(env_vars) do
        env_data[var] = os.getenv(var) or ""
    end
    
    -- Include nix shell state and user
    env_data.in_nix_shell = tostring(is_in_nix_shell())
    env_data.user = os.getenv("USER") or "unknown"
    
    -- Create a hash-like key from the environment
    local key_parts = {}
    for k, v in pairs(env_data) do
        table.insert(key_parts, k .. "=" .. v)
    end
    table.sort(key_parts)
    return table.concat(key_parts, "|")
end

-- extract package information from store path using derivation data
local function extract_package_info_from_path(store_path, opt)
    local cache = get_nix_cache()
    local memory_cache = get_memory_cache()
    
    -- Check caches first
    local cached = memory_cache:get2(DERIVATION_CACHE, store_path)
    if cached then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Using session cached derivation info for: " .. store_path)
        end
        return cached.name, cached.version, cached.outputs, cached.current_output
    end
    
    cached = cache:get2(DERIVATION_CACHE, store_path)
    if cached then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Using persistent cached derivation info for: " .. store_path)
        end
        memory_cache:set2(DERIVATION_CACHE, store_path, cached)
        return cached.name, cached.version, cached.outputs, cached.current_output
    end
    
    -- Find required tools
    local nix_store = find_tool("nix-store")
    local nix = find_tool("nix")

    if not nix_store or not nix then
        if opt and (opt.verbose or option.get("verbose")) then
            local missing = {}
            if not nix_store then table.insert(missing, "nix-store") end
            if not nix then table.insert(missing, "nix") end
            print("Nix: Required tools not found: " .. table.concat(missing, ", "))
        end
        return nil
    end

    -- Get the derivation path
    local drv_output = try {function()
        return os.iorunv(nix_store.program, {"--query", "--valid-derivers", store_path}):trim() -- not "--deriver" because:
        -- The returned deriver is not guaranteed to exist in the local store, for example when paths were substituted from a binary cache.
        -- Ref: https://nix.dev/manual/nix/latest/command-ref/nix-store/query.html
    end}
    
    if not drv_output or drv_output == "" then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Could not get derivation for: " .. store_path)
        end
        return nil
    end

    -- drv_output is a list of derivations
    local derivations = {}
    for drv_path in drv_output:gmatch("(%S+)") do
        if drv_path:match("%.drv$") then
            table.insert(derivations, drv_path)
        end
    end
    
    if #derivations == 0 then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: No valid derivation paths found for: " .. store_path)
        end
        return nil
    end
    
    -- Try each derivation until we find one that works
    local derivation_json = nil
    for _, drv_path in ipairs(derivations) do
        derivation_json = try {function()
            return os.iorunv(nix.program, {
                "derivation", "show", 
                drv_path,
                "--extra-experimental-features", "nix-command flakes"
            }):trim()
        end}
        
        if derivation_json and derivation_json ~= "" then
            if opt and (opt.verbose or option.get("verbose")) then
                print("Nix: Using derivation: " .. drv_path)
            end
            break
        end
    end
    
    if not derivation_json or derivation_json == "" then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Could not show derivation for: " .. drv_output)
        end
        return nil
    end
    
    -- Parse the JSON output
    local derivation_data, parse_error = json.decode(derivation_json)
    if not derivation_data or parse_error then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Failed to parse derivation JSON: " .. (parse_error or "unknown error"))
        end
        return nil
    end
    
    -- Extract the derivation info (should be a single key-value pair)
    local drv_info = nil
    for _, info in pairs(derivation_data) do
        drv_info = info
        break
    end
    
    if not drv_info then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: No derivation info found in JSON")
        end
    end
    
    -- Extract package information
    -- structureAttrs vs env:
    -- not every nix package has structureAttrs, so we fallback to env
    -- Ref: https://nix.dev/manual/nix/latest/language/advanced-attributes.html
    local package_name = (drv_info.structuredAttrs and drv_info.structuredAttrs.pname) or (drv_info.env and drv_info.env.pname) or nil 
    -- not just "name" as that includes version
    local version = (drv_info.structuredAttrs and drv_info.structuredAttrs.version) or (drv_info.env and drv_info.env.version) or nil 
    local outputs = drv_info.outputs or {}
    
    if not package_name then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: No pname found in derivation: " .. drv_output)
        end
        return nil
    end
    
    -- Create outputs map (output_name -> store_path)
    local output_paths = {}
    for output_name, output_info in pairs(outputs) do
        if output_info.path then
            output_paths[output_name] = output_info.path
        end
    end
    
    -- Determine which output this store_path represents
    local current_output = nil
    for output_name, output_path in pairs(output_paths) do
        if output_path == store_path then
            current_output = output_name
            break
        end
    end
    
    -- Cache the result
    local result = {
        name = package_name,
        version = version,
        outputs = output_paths,
        current_output = current_output
    }
    
    cache:set2(DERIVATION_CACHE, store_path, result)
    memory_cache:set2(DERIVATION_CACHE, store_path, result)
    
    if opt and (opt.verbose or option.get("verbose")) then
        print("Nix: Extracted derivation info for " .. package_name .. " (version: " .. (version or "unknown") .. ")")
    end
    
    return package_name, version, output_paths, current_output
end

-- remove duplicates from array
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

-- PackageInfo data
local PackageInfo = {}
PackageInfo.__index = PackageInfo

function PackageInfo:new(package_name)
    local o = {
        name = package_name, -- "pname" in nix terms
        includedirs = {},
        bindirs = {},
        linkdirs = {},
        links = {},
        libfiles = {},
        store_paths = {},
        outputs = {}, -- output_name -> store_path mapping
        version = nil,
        pkgconfig_available = false
    }

    table.inherit2(o, self)
    return o
end

function PackageInfo:add_store_path(p, output_name)
    table.insert(self.store_paths, p)
    if output_name then
        self.outputs[output_name] = p
    end
end

function PackageInfo:add_includedir(d)
    table.insert(self.includedirs, d)
end

function PackageInfo:add_bindir(d)
    table.insert(self.bindirs, d)
end

function PackageInfo:add_linkdir(d)
    table.insert(self.linkdirs, d)
end

function PackageInfo:add_link(l)
    table.insert(self.links, l)
end

function PackageInfo:add_libfile(f)
    table.insert(self.libfiles, f)
end

function PackageInfo:set_version(v)
    if not self.version and v then
        self.version = v
    end
end

function PackageInfo:set_pkgconfig_available()
    self.pkgconfig_available = true
end

function PackageInfo:finalize()
    -- remove duplicates
    self.includedirs = remove_duplicates(self.includedirs)
    self.bindirs = remove_duplicates(self.bindirs)
    self.linkdirs = remove_duplicates(self.linkdirs)
    self.links = remove_duplicates(self.links)
    self.libfiles = remove_duplicates(self.libfiles)
    self.store_paths = remove_duplicates(self.store_paths)
    
    -- return plain table (so cache stores normal table)
    return {
        name = self.name,
        includedirs = self.includedirs,
        bindirs = self.bindirs,
        linkdirs = self.linkdirs,
        links = self.links,
        libfiles = self.libfiles,
        store_paths = self.store_paths,
        outputs = self.outputs,
        version = self.version,
        pkgconfig_available = self.pkgconfig_available
    }
end

-- follow propagated build inputs recursively with caching
local function follow_propagated_inputs(store_paths, opt)
    local cache = get_nix_cache()
    local all_paths = {}
    local seen = {}
    local visited = {}
    
    -- Add initial paths
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
            
            -- Check cache first
            local cached_props = cache:get2(PROPAGATED_CACHE, store_path)
            local prop_paths
            
            if cached_props then
                prop_paths = cached_props
                if opt and (opt.verbose or option.get("verbose")) then
                    print("Nix: Using cached propagated inputs for: " .. store_path)
                end
            else
                -- Read from filesystem
                prop_paths = {}
                local prop_file = path.join(store_path, "nix-support", "propagated-build-inputs")
                if os.isfile(prop_file) then
                    local content = try {function()
                        return io.readfile(prop_file):trim()
                    end}
                    if content and content ~= "" then
                        for prop_path in content:gmatch("%S+") do
                            if prop_path:startswith("/nix/store/") then
                                table.insert(prop_paths, prop_path)
                            end
                        end
                    end
                end
                
                -- Cache the result
                cache:set2(PROPAGATED_CACHE, store_path, prop_paths)
                if opt and (opt.verbose or option.get("verbose")) then
                    print("Nix: Cached propagated inputs for: " .. store_path)
                end
            end
            
            -- Add new paths
            for _, prop_path in ipairs(prop_paths) do
                if not seen[prop_path] then
                    seen[prop_path] = true
                    table.insert(all_paths, prop_path)
                    if opt and (opt.verbose or option.get("verbose")) then
                        print("Nix: Added propagated: " .. prop_path)
                    end
                end
            end
        end
        i = i + 1
    end
    
    return all_paths
end

-- get store paths from nix command output
local function get_store_paths_from_command(command, args, opt)
    local output = try {function()
        return os.iorunv(command, args):trim()
    end}
    
    if not output then
        return {}
    end
    
    local store_paths = {}
    for line in output:gmatch("[^\n]+") do
        local store_path = line:match("(/nix/store/[^%s]+)")
        if store_path then
            table.insert(store_paths, store_path)
        end
    end
    
    return follow_propagated_inputs(store_paths, opt)
end

-- parse store paths from environment variables with caching
local function parse_store_paths_from_env(env_vars, opt)
    local cache_key = generate_env_cache_key()
    local memory_cache = get_memory_cache()
    
    -- Check memory cache first (session cache)
    local cached_paths = memory_cache:get2(STORE_PATHS_CACHE, cache_key)
    if cached_paths then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Using session cached store paths")
        end
        return cached_paths
    end
    
    -- Check persistent cache
    local cache = get_nix_cache()
    cached_paths = cache:get2(STORE_PATHS_CACHE, cache_key)
    if cached_paths then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Using persistent cached store paths")
        end
        -- Also cache in memory for faster access
        memory_cache:set2(STORE_PATHS_CACHE, cache_key, cached_paths)
        memory_cache:set("last_env_key", cache_key)
        return cached_paths
    end
    
    -- Parse from environment
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
    
    -- Follow propagated inputs
    paths = follow_propagated_inputs(paths, opt)
    
    -- Cache the result
    cache:set2(STORE_PATHS_CACHE, cache_key, paths)
    memory_cache:set2(STORE_PATHS_CACHE, cache_key, paths)
    memory_cache:set("last_env_key", cache_key)
    cache:save()
    
    if opt and (opt.verbose or option.get("verbose")) then
        print("Nix: Cached " .. #paths .. " store paths")
    end
    
    return paths
end

-- STORE PATH EXTRACTION FUNCTIONS

-- extract store paths from nix shell
local function get_store_paths_nix_shell(opt)
    if not is_in_nix_shell() then
        return {}
    end
    
    local build_env_vars = {
        "buildInputs",
        "nativeBuildInputs",
        "propagatedBuildInputs",
        "propagatedNativeBuildInputs"
    }
    
    return parse_store_paths_from_env(build_env_vars, opt)
end

-- Find package from current user's nix profile, includes nix-env installed packages
-- Note: nix-env only lists one output in the profile list
-- $ nix-env -iA nixpkgs.<package> # installs multiple outputs, but only one is listed in the profile
-- this can cause issues if the main output does not contain the necessary files
-- Example: zlib.dev contains the headers, but zlib only contains the library
-- there does not seem to be an straight-forward way to find all outputs...
-- It is better to use nix profile like:
-- $ nix profile install 'nixpkgs#zlib^*'' # installs all outputs
-- $ nix profile install 'nixpkgs#zlib^dev' # installs only the dev output
local function get_store_paths_nix_profile(opt)
    local nix = find_tool("nix")
    if not nix then
        return {}
    end
    
    return get_store_paths_from_command(
        nix.program, 
        {"profile", "list", "--extra-experimental-features", "nix-command flakes"},
        opt
    )
end

-- Popular nix-community tool to declaratively manage user environments (NixOS and non-NixOS)
local function get_store_paths_home_manager_tool(opt)
    local home_manager = find_tool("home-manager")
    if not home_manager then
        return {}
    end
    
    return get_store_paths_from_command(
        home_manager.program,
        {"packages"},
        opt
    )
end

-- Home manager can be installed as a module in nixos, in which case the home-manager tool is missing.
local function get_store_paths_home_manager_profile(opt)
    local nix_store = find_tool("nix-store")
    if not nix_store then
        return {}
    end
    
    local user = os.getenv("USER") or "unknown"
    local user_profile = "/etc/profiles/per-user/" .. user
    if not os.isdir(user_profile) then
        return {}
    end
    
    return get_store_paths_from_command(
        nix_store.program,
        {"--query", "--requisites", user_profile},
        opt
    )
end

-- nixos-option is not always configured properly, but if it is, we can find user/system packages
local function get_store_paths_nixos_user_packages(opt)
    local nixos_option = find_tool("nixos-option")
    if not nixos_option then
        return {}
    end
    
    local user = os.getenv("USER") or "unknown"
    local output = try {function()
        return os.iorunv(nixos_option.program, {"users.users." .. user .. ".packages"}):trim()
    end}
    
    if output then
        local store_paths = {}
        for store_path in output:gmatch('(/nix/store/[^"\'%s]+)') do
            table.insert(store_paths, store_path)
        end
        
        return follow_propagated_inputs(store_paths, opt)
    end
    return {}
end

-- extract store paths from nixos system packages
local function get_store_paths_nixos_system_packages(opt)
    local nixos_option = find_tool("nixos-option")
    if not nixos_option then
        return {}
    end
    
    local output = try {function()
        return os.iorunv(nixos_option.program, {"environment.systemPackages"}):trim()
    end}
    
    if output then
        local store_paths = {}
        for store_path in output:gmatch('(/nix/store/[^"\'%s]+)') do
            table.insert(store_paths, store_path)
        end
        
        return follow_propagated_inputs(store_paths, opt)
    end
    return {}
end

-- Includes all system/user/home-manager packages
local function get_store_paths_nixos_current_system(opt)
    local nix_store = find_tool("nix-store")
    if not nix_store then
        return {}
    end
    
    if not os.isdir("/run/current-system") then
        return {}
    end
    
    return get_store_paths_from_command(
        nix_store.program,
        {"--query", "--requisites", "/run/current-system"},
        opt
    )
end

-- get all store paths from all nix environments with caching
local function get_all_store_paths(opt)
    local cache = get_nix_cache()
    local memory_cache = get_memory_cache()
    local cache_key = "all_environments:" .. generate_env_cache_key()
    
    -- Check memory cache first
    local cached_paths = memory_cache:get2(STORE_PATHS_CACHE, cache_key)
    if cached_paths then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Using session cached all store paths")
        end
        return cached_paths
    end
    
    -- Check persistent cache
    cached_paths = cache:get2(STORE_PATHS_CACHE, cache_key)
    if cached_paths then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Using persistent cached all store paths")
        end
        memory_cache:set2(STORE_PATHS_CACHE, cache_key, cached_paths)
        return cached_paths
    end
    
    -- Extract from all sources
    local all_paths = {}
    local seen = {}
    
    local get_store_path_functions = {
        get_store_paths_nix_shell,
        get_store_paths_nix_profile,
        get_store_paths_home_manager_tool,
        get_store_paths_home_manager_profile,
        get_store_paths_nixos_user_packages,
        get_store_paths_nixos_system_packages,
        get_store_paths_nixos_current_system
    }
    
    for _, func in ipairs(get_store_path_functions) do
        local paths = func(opt)
        for _, store_path in ipairs(paths) do
            if not seen[store_path] then
                seen[store_path] = true
                table.insert(all_paths, store_path)
            end
        end
    end
    
    -- Cache the result
    cache:set2(STORE_PATHS_CACHE, cache_key, all_paths)
    memory_cache:set2(STORE_PATHS_CACHE, cache_key, all_paths)
    cache:save()
    
    if opt and (opt.verbose or option.get("verbose")) then
        print("Nix: Found " .. #all_paths .. " total store paths across all environments")
    end
    
    return all_paths
end

-- check if store path has the package name (substring search)
local function path_matches_package(store_path, package_name)
    local path_name_lower = path.basename(store_path):lower()
    local package_name_lower = package_name:lower()
    
    return path_name_lower:find(package_name_lower, 1, true) ~= nil
end

-- extract package information from store paths with caching
local function extract_package_info(store_paths, package_name, opt)
    opt = opt or {}
    local cache = get_nix_cache()
    local memory_cache = get_memory_cache()
    local paths_key = table.concat(store_paths or {}, ";")
    local cache_key = "package_info:" .. (package_name or "all") .. ":" .. paths_key
    
    -- Check memory cache first
    local cached = memory_cache:get2(PACKAGE_INFO_CACHE, cache_key)
    if cached ~= nil then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Using session cached package info")
        end
        return cached
    end
    
    -- Check persistent cache
    cached = cache:get2(PACKAGE_INFO_CACHE, cache_key)
    if cached ~= nil then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Using persistent cached package info")
        end
        memory_cache:set2(PACKAGE_INFO_CACHE, cache_key, cached)
        return cached
    end

    if not store_paths or #store_paths == 0 then
        local empty = {}
        cache:set2(PACKAGE_INFO_CACHE, cache_key, empty)
        memory_cache:set2(PACKAGE_INFO_CACHE, cache_key, empty)
        return empty
    end

    -- Filter store paths if package_name is provided
    local filtered_paths = store_paths
    if package_name then
        filtered_paths = {}
        local seen = {}
        
        -- First, find direct matches
        for _, store_path in ipairs(store_paths) do
            if path_matches_package(store_path, package_name) and not seen[store_path] then
                seen[store_path] = true
                table.insert(filtered_paths, store_path)
            end
        end
        
        -- Then find their dependencies
        local all_deps = follow_propagated_inputs(filtered_paths, opt)
        for _, dep_path in ipairs(all_deps) do
            if not seen[dep_path] then
                seen[dep_path] = true
                table.insert(filtered_paths, dep_path)
            end
        end
        
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Filtered to " .. #filtered_paths .. " relevant store paths for package: " .. package_name)
        end
    end

    if opt and (opt.verbose or option.get("verbose")) then
        print("Nix: Extracting package info for " .. #filtered_paths .. " store paths")
    end

    local packages = {} -- map: package_name -> PackageInfo

    local function ensure_pkg(name)
        if not name then
            name = "<unknown>"
        end
        local p = packages[name]
        if not p then
            p = PackageInfo:new(name)
            packages[name] = p
        end
        return p
    end

    for _, store_path in ipairs(filtered_paths) do
        if not store_path or store_path == "" then goto continue end

        -- Use the enhanced derivation-based extraction
        local parsed_name, parsed_version, output_paths, current_output = 
            extract_package_info_from_path(store_path, opt)

        if not parsed_name then
            if opt and (opt.verbose or option.get("verbose")) then
                print("Nix: Could not extract package info from: " .. store_path)
            end
            goto continue
        end

        local pkg = ensure_pkg(parsed_name)

        pkg:add_store_path(store_path, current_output)
        if parsed_version then
            pkg:set_version(parsed_version)
        end

        -- Add all output paths to the package
        if output_paths then
            for output_name, output_path in pairs(output_paths) do
                pkg.outputs[output_name] = output_path
            end
        end

        -- include directories (and their subdirs)
        local includedir = path.join(store_path, "include")
        if os.isdir(includedir) then
            pkg:add_includedir(includedir)
            local subdirs = try { function() return os.dirs(path.join(includedir, "*")) end } or {}
            for _, subdir in ipairs(subdirs) do
                if os.isdir(subdir) then
                    pkg:add_includedir(subdir)
                end
            end
        end

        -- bin
        local bindir = path.join(store_path, "bin")
        if os.isdir(bindir) then
            pkg:add_bindir(bindir)
        end

        -- lib and libs
        local libdir = path.join(store_path, "lib")
        if os.isdir(libdir) then
            local libfiles = try { function()
                local files = {}
                local patterns = {"*.so*", "*.a", "*.dylib*"}
                for _, pattern in ipairs(patterns) do
                    for _, f in ipairs(os.files(path.join(libdir, pattern)) or {}) do
                        table.insert(files, f)
                    end
                end
                return files
            end } or {}

            if #libfiles > 0 then
                pkg:add_linkdir(libdir)
                for _, libfile in ipairs(libfiles) do
                    local filename = path.filename(libfile)
                    local linkname = filename:match("^lib(.+)%.so") or
                                     filename:match("^lib(.+)%.a") or
                                     filename:match("^lib(.+)%.dylib")
                    if linkname then
                        pkg:add_link(linkname)
                        pkg:add_libfile(libfile)
                    end
                end
            else
                -- if no libs, see if cmake/pkgconfig dirs exist and add linkdir
                local has_cmake = os.isdir(path.join(libdir, "cmake"))
                local has_pkgconfig = os.isdir(path.join(libdir, "pkgconfig"))
                if has_cmake or has_pkgconfig then
                    pkg:add_linkdir(libdir)
                end
            end
        end

        ::continue::
    end

    -- finalize all PackageInfo instances into plain tables
    local result = {}
    for name, pkgobj in pairs(packages) do
        local plain = pkgobj:finalize()
        result[name] = plain
    end

    -- cache result
    cache:set2(PACKAGE_INFO_CACHE, cache_key, result)
    memory_cache:set2(PACKAGE_INFO_CACHE, cache_key, result)
    cache:save()

    if opt and (opt.verbose or option.get("verbose")) then
        local keys = table.keys(result)
        print("Nix: Extracted " .. #keys .. " packages from store paths")
    end

    return result
end

-- find package with pkg-config with caching
local function find_with_pkgconfig(package_name, store_paths, opt)
    local cache = get_nix_cache()
    local memory_cache = get_memory_cache()

    -- prefer the normalized env key stored in session memcache
    local env_key = memory_cache:get("last_env_key")
    local cache_key = package_name .. ":" .. (env_key or table.concat(store_paths, ";"))

    -- Check session memory cache first
    local memo = memory_cache:get2(PKGCONFIG_CACHE, cache_key)
    if memo ~= nil then
        if opt and (opt.verbose or option.get("verbose")) then
            local status = memo and "found" or "not found"
            print("Nix: Using session cached pkg-config result (" .. status .. ") for: " .. package_name)
        end
        return memo or nil
    end

    -- Check persistent cache
    local cached_result = cache:get2(PKGCONFIG_CACHE, cache_key)
    if cached_result ~= nil then
        if opt and (opt.verbose or option.get("verbose")) then
            local status = cached_result and "found" or "not found"
            print("Nix: Using persistent cached pkg-config result (" .. status .. ") for: " .. package_name)
        end
        memory_cache:set2(PKGCONFIG_CACHE, cache_key, cached_result)
        return cached_result or nil
    end

    -- Filter store paths to only relevant ones
    local filtered_paths = {}
    local seen = {}
    
    for _, store_path in ipairs(store_paths) do
        if path_matches_package(store_path, package_name) and not seen[store_path] then
            seen[store_path] = true
            table.insert(filtered_paths, store_path)
        end
    end
    
    -- Add dependencies of matching packages
    local all_deps = follow_propagated_inputs(filtered_paths, opt)
    for _, dep_path in ipairs(all_deps) do
        if not seen[dep_path] then
            seen[dep_path] = true
            table.insert(filtered_paths, dep_path)
        end
    end

    -- Search filtered paths
    for _, store_path in ipairs(filtered_paths) do
        local pkgconfig_dirs = {
            path.join(store_path, "lib", "pkgconfig"),
            path.join(store_path, "share", "pkgconfig")
        }

        for _, pcdir in ipairs(pkgconfig_dirs) do
            if os.isdir(pcdir) then
                local result = find_package_from_pkgconfig(package_name, {configdirs = pcdir})
                if result then
                    if opt and (opt.verbose or option.get("verbose")) then
                        print("Nix: Found package via pkg-config: " .. package_name)
                    end
                    memory_cache:set2(PKGCONFIG_CACHE, cache_key, result)
                    cache:set2(PKGCONFIG_CACHE, cache_key, result)
                    return result
                end
            end
        end
    end

    -- Cache negative result
    memory_cache:set2(PKGCONFIG_CACHE, cache_key, false)
    cache:set2(PKGCONFIG_CACHE, cache_key, false)
    return nil
end

-- find package using the nix package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")

function main(name, opt)
    opt = opt or {}

    -- ensure a stable env cache key is available for the whole run
    local memory_cache = get_memory_cache()
    memory_cache:set("last_env_key", generate_env_cache_key())
    
    -- Skip cross-compilation scenarios
    if is_cross(opt.plat, opt.arch) then
        return
    end
    
    -- Get all store paths from all nix environments (cached)
    local store_paths = get_all_store_paths(opt)
    if #store_paths == 0 then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: No store paths found in any nix environment")
        end
        return nil
    end
    
    -- Extract all package info (cached)
    local packages = extract_package_info(store_paths, name, opt)
    local keys = table.keys(packages)
    if not packages or #keys == 0 then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: No packages extracted from store paths")
        end
        return nil
    end
    
    -- Try to find the package by name match first
    local name_lower = name:lower()
    local found_package = packages[name_lower]
    
    -- Try pkg-config if package found in store paths
    local pkgconfig_result = nil
    if found_package then
        pkgconfig_result = find_with_pkgconfig(name, store_paths, opt)
        if pkgconfig_result then
            if opt and (opt.verbose or option.get("verbose")) then
                print("Nix: Found package via pkg-config: " .. name)
            end
            return pkgconfig_result
        end
    end
    
    -- If we found package info directly, return it
    if found_package then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Found package: " .. name .. " (" .. found_package.name .. ")")
        end
        
        local result = {
            name = found_package.name,
            version = found_package.version
        }
        
        local fields_to_copy = {"includedirs", "linkdirs", "links", "libfiles", "bindirs"}
        -- Add directories and links if they exist
        for _, field in ipairs(fields_to_copy) do
            if found_package[field] and #found_package[field] > 0 then
                result[field] = found_package[field]
            end
        end
        
        return result
    end
    
    -- Package not found
    if opt and (opt.verbose or option.get("verbose")) then
        print("Nix: Package " .. name .. " not found in any nix environment")
    end
    
    return nil
end