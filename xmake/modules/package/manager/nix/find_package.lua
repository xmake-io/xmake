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
local DERIVATION_CACHE = "nix_derivation"

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



-- get derivation info for a store path with caching
local function get_derivation_info(store_path, opt)
    local cache = get_nix_cache()
    local memory_cache = get_memory_cache()
    
    -- Check memory cache first
    local cached = memory_cache:get2(DERIVATION_CACHE, store_path)
    if cached ~= nil then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Using session cached derivation for: " .. store_path)
        end
        return cached
    end
    
    -- Check persistent cache
    cached = cache:get2(DERIVATION_CACHE, store_path)
    if cached ~= nil then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Using persistent cached derivation for: " .. store_path)
        end
        memory_cache:set2(DERIVATION_CACHE, store_path, cached)
        return cached
    end
    
    -- Get derivation path
    local nix_store = find_tool("nix-store")
    if not nix_store then
        local empty = {}
        cache:set2(DERIVATION_CACHE, store_path, empty)
        memory_cache:set2(DERIVATION_CACHE, store_path, empty)
        return empty
    end
    
    local drv_path = try {function()
        return os.iorunv(nix_store.program, {"-q", store_path, "--deriver"}):trim()
    end}
    
    if not drv_path or drv_path == "" then
        local empty = {}
        cache:set2(DERIVATION_CACHE, store_path, empty)
        memory_cache:set2(DERIVATION_CACHE, store_path, empty)
        return empty
    end
    
    -- Get derivation info using nix derivation show
    local nix = find_tool("nix")
    if not nix then
        local empty = {}
        cache:set2(DERIVATION_CACHE, store_path, empty)
        memory_cache:set2(DERIVATION_CACHE, store_path, empty)
        return empty
    end
    
    local drv_json = try {function()
        return os.iorunv(nix.program, {
            "derivation", "show", 
            "--extra-experimental-features", "nix-command flakes",
            drv_path
        }):trim()
    end}
    
    if not drv_json or drv_json == "" then
        local empty = {}
        cache:set2(DERIVATION_CACHE, store_path, empty)
        memory_cache:set2(DERIVATION_CACHE, store_path, empty)
        return empty
    end
    
    -- Parse the JSON using xmake's JSON parser
    local drv_data, parse_error = json.decode(drv_json)
    if not drv_data or parse_error then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Failed to parse derivation JSON for " .. store_path .. ": " .. (parse_error or "unknown error"))
        end
        local empty = {}
        cache:set2(DERIVATION_CACHE, store_path, empty)
        memory_cache:set2(DERIVATION_CACHE, store_path, empty)
        return empty
    end
    
    -- Extract the first (and usually only) derivation
    local drv_info = nil
    for _, info in pairs(drv_data) do
        drv_info = info
        break
    end
    
    if not drv_info or type(drv_info) ~= "table" or not drv_info.env then
        local empty = {}
        cache:set2(DERIVATION_CACHE, store_path, empty)
        memory_cache:set2(DERIVATION_CACHE, store_path, empty)
        return empty
    end
    
    -- Extract relevant information
    local result = {
        name = drv_info.env.pname or drv_info.env.name or "",
        version = drv_info.env.version or "",
        outputs = drv_info.outputs or {},
        env = drv_info.env or {}
    }
    
    -- Cache the result
    cache:set2(DERIVATION_CACHE, store_path, result)
    memory_cache:set2(DERIVATION_CACHE, store_path, result)
    cache:save()
    
    if opt and (opt.verbose or option.get("verbose")) then
        print("Nix: Cached derivation info for: " .. store_path .. " (name=" .. result.name .. ", version=" .. result.version .. ")")
    end
    
    return result
end

-- parse store basename to extract name, version, and output (fallback method)
local function parse_store_basename(path_name)
    -- parse "<hash>-<name>-<version>" or "<hash>-<name>-<version>-<output>"
    -- remove leading hash (up to first '-')
    local first_dash = path_name:find("-", 1, true)
    if not first_dash then
        return nil, nil, nil
    end
    local rest = path_name:sub(first_dash + 1)
    
    -- find last dash and second-last dash in rest
    local last_dash = nil
    for i = #rest, 1, -1 do
        if rest:sub(i, i) == "-" then
            last_dash = i
            break
        end
    end
    if not last_dash then
        return rest, nil, nil  -- Just name, no version
    end
    
    -- try to find second-last dash
    local second_last = nil
    for i = last_dash - 1, 1, -1 do
        if rest:sub(i, i) == "-" then
            second_last = i
            break
        end
    end
    
    if second_last then
        -- form: name (may have dashes) = rest[1..second_last-1], version = rest[second_last+1..last_dash-1], output = rest[last_dash+1..]
        local name = rest:sub(1, second_last - 1)
        local version = rest:sub(second_last + 1, last_dash - 1)
        local output = rest:sub(last_dash + 1)
        return name, version, output
    else
        -- form: name = rest[1..last_dash-1], version = rest[last_dash+1..]
        local name = rest:sub(1, last_dash - 1)
        local version = rest:sub(last_dash + 1)
        return name, version, nil
    end
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

-- PackageInfo class
local PackageInfo = {}
PackageInfo.__index = PackageInfo

function PackageInfo:new(package_name)
    local o = {
        name = package_name,
        includedirs = {},
        bindirs = {},
        linkdirs = {},
        links = {},
        libfiles = {},
        store_paths = {},
        version = nil,
        pkgconfig_available = false,
        outputs = {}
    }

    table.inherit2(o, self)
    return o
end

function PackageInfo:add_store_path(p)
    table.insert(self.store_paths, p)
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
    if not self.version and v and v ~= "" then
        self.version = v
    end
end

function PackageInfo:set_pname(p)
    if not self.name and p and p ~= "" then
        self.name = p
    end
end

function PackageInfo:set_outputs(o)
    if o and type(o) == "table" then
        self.outputs = o
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
        version = self.version,
        outputs = self.outputs,
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

-- STORE PATH EXTRACTION FUNCTIONS (same as before)

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

-- extract store paths from nix profile
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

-- extract store paths from home-manager (tool version)
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

-- extract store paths from home-manager (profile version)
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

-- extract store paths from nixos user packages
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

-- extract store paths from nixos current system
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

-- extract package information from store paths with caching and derivation info
local function extract_package_info(store_paths, opt)
    opt = opt or {}
    local cache = get_nix_cache()
    local memory_cache = get_memory_cache()
    local paths_key = table.concat(store_paths or {}, ";")
    local cache_key = "package_info:" .. paths_key
    
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

    if opt and (opt.verbose or option.get("verbose")) then
        print("Nix: Extracting package info for " .. #store_paths .. " store paths")
    end

    local packages = {} -- map: package_name -> PackageInfo

    for _, store_path in ipairs(store_paths) do
        if not store_path or store_path == "" then goto continue end

        -- Get derivation info
        local drv_info = get_derivation_info(store_path, opt)
        if not drv_info or not drv_info.name or drv_info.name == "" then
            if opt and (opt.verbose or option.get("verbose")) then
                print("Nix: Skipping " .. store_path .. " - no derivation info or name available")
            end
            goto continue
        end

        local pkgname = drv_info.name:lower()
        
        -- Only create one package entry per name (first one wins due to prioritized ordering)
        if not packages[pkgname] then
            local pkg = PackageInfo:new(pkgname)
            packages[pkgname] = pkg
            
            pkg:add_store_path(store_path)
            pkg:set_version(drv_info.version)
            pkg:set_pname(drv_info.name)
            pkg:set_outputs(drv_info.outputs)

            if opt and (opt.verbose or option.get("verbose")) then
                print("Nix: Added package: " .. drv_info.name .. " " .. (drv_info.version or ""))
            end

            -- include directories
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

            -- lib
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
        else
            -- Package already exists, just add this store path as additional
            packages[pkgname]:add_store_path(store_path)
            if opt and (opt.verbose or option.get("verbose")) then
                print("Nix: Added additional store path for " .. pkgname .. ": " .. store_path)
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
        local _, count = table.keys(result)
        print("Nix: Extracted " .. count .. " packages from store paths")
    end

    return result
end

-- check if path matches package name using derivation info
local function path_matches_package(store_path, package_name, opt)
    local drv_info = get_derivation_info(store_path, opt)
    if drv_info and drv_info.name and drv_info.name ~= "" then
        return drv_info.name:lower() == package_name:lower()
    end
    return false
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

    -- Try matching store paths for this package first
    local matching_paths = {}
    for _, store_path in ipairs(store_paths) do
        if path_matches_package(store_path, package_name, opt) then
            table.insert(matching_paths, store_path)
        end
    end

    -- Search matching paths first
    for _, store_path in ipairs(matching_paths) do
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
                    memory_cache:set2(PKGCONFIG_CACHE, cache_key, result)
                    cache:set2(PKGCONFIG_CACHE, cache_key, result)
                    return result
                end
            end
        end
    end

    -- If no matches found, search all paths
    for _, store_path in ipairs(store_paths) do
        local pkgconfig_dirs = {
            path.join(store_path, "lib", "pkgconfig"),
            path.join(store_path, "share", "pkgconfig")
        }

        for _, pcdir in ipairs(pkgconfig_dirs) do
            if os.isdir(pcdir) then
                local result = find_package_from_pkgconfig(package_name, {configdirs = pcdir})
                if result then
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


-- main entry point
function main(name, opt)
    opt = opt or {}

    -- ensure a stable env cache key is available for the whole run
    local memory_cache = get_memory_cache()
    memory_cache:set("last_env_key", generate_env_cache_key())
    
    -- Skip cross-compilation scenarios
    if is_cross(opt.plat, opt.arch) then
        return
    end
    
    -- Handle nix:: prefix
    local actual_name = name
    local force_nix = false
    if name:startswith("nix::") then
        actual_name = name:sub(6)
        force_nix = true
    end
    
    -- Get all store paths from all nix environments (cached)
    local store_paths = get_all_store_paths(opt)
    if #store_paths == 0 then
        if force_nix and opt and (opt.verbose or option.get("verbose")) then
            print("Nix: No store paths found in any nix environment")
        end
        return nil
    end
    
    -- Extract all package info (cached)
    local packages = extract_package_info(store_paths, opt)
    local _, count = table.keys(packages)
    if not packages or count == 0 then
        if force_nix and opt and (opt.verbose or option.get("verbose")) then
            print("Nix: No packages extracted from store paths")
        end
        return nil
    end
    
    -- Look for exact name match only
    local actual_name_lower = actual_name:lower()
    local found_package = packages[actual_name_lower]
    
    -- Try pkg-config if package found in store paths
    local pkgconfig_result = nil
    if found_package or force_nix then
        pkgconfig_result = find_with_pkgconfig(actual_name, store_paths, opt)
        if pkgconfig_result then
            if opt and (opt.verbose or option.get("verbose")) then
                print("Nix: Found package via pkg-config: " .. actual_name)
            end
            return pkgconfig_result
        end
    end
    
    -- If we found package info directly, return it
    if found_package then
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Found package: " .. actual_name .. " (" .. found_package.name .. ")")
        end
        
        local result = {
            name = found_package.name,
            version = found_package.version
        }
        
        -- Add directories and links if they exist
        if found_package.includedirs and #found_package.includedirs > 0 then
            result.includedirs = found_package.includedirs
        end
        if found_package.linkdirs and #found_package.linkdirs > 0 then
            result.linkdirs = found_package.linkdirs
        end
        if found_package.links and #found_package.links > 0 then
            result.links = found_package.links
        end
        if found_package.libfiles and #found_package.libfiles > 0 then
            result.libfiles = found_package.libfiles
        end
        if found_package.bindirs and #found_package.bindirs > 0 then
            result.bindirs = found_package.bindirs
        end
        
        return result
    end
    
    -- Package not found - alert user
    if force_nix then
        print("Nix: Package '" .. actual_name .. "' not found in any nix environment")
        if opt and (opt.verbose or option.get("verbose")) then
            print("Nix: Available packages:")
            for pkg_name, _ in pairs(packages) do
                print("  - " .. pkg_name)
            end
        end
    end
    
    return nil
end