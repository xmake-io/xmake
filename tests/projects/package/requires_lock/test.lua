import("core.project.config")

-- helper function to count table entries
local function count_table(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- helper function to get all package keys from lock data
local function get_package_keys(lockdata)
    local keys = {}
    for key, _ in pairs(lockdata) do
        if key ~= "__meta__" then
            table.insert(keys, key)
        end
    end
    return keys
end

-- helper function to verify lock file basic structure
local function verify_lock_file_structure(lockdata)
    assert(lockdata, "lock file should be loadable")
    assert(lockdata.__meta__, "lock file should have metadata")
    assert(lockdata.__meta__.version == "1.0", "lock file version should be 1.0")
    
    local plat = config.plat() or os.subhost()
    local arch = config.arch() or os.subarch()
    local plat_arch_key = plat .. "|" .. arch
    assert(lockdata[plat_arch_key], "should have entries for current platform: " .. plat_arch_key)
    
    return lockdata[plat_arch_key]
end

-- helper function to count zlib entries
local function count_zlib_entries(plat_entries)
    local zlib_count = 0
    for key, _ in pairs(plat_entries) do
        if key:find("zlib") then
            zlib_count = zlib_count + 1
        end
    end
    return zlib_count
end

-- test lock file generation and basic content validation
function test_lock_file_generation(scriptdir)
    local lockfile = path.join(scriptdir, "xmake-requires.lock")
    assert(os.isfile(lockfile), "xmake-requires.lock should be generated")
    
    -- load and verify lock file content
    local lockdata = io.load(lockfile)
    local plat_entries = verify_lock_file_structure(lockdata)
    
    -- check zlib entries and repo info
    local found_zlib = false
    for key, package_data in pairs(plat_entries) do
        if key:find("zlib#") then
            found_zlib = true
            assert(package_data.version, "zlib should have version")
            assert(package_data.repo, "zlib should have repo info")
            assert(package_data.repo.url, "zlib repo should have url")
            assert(package_data.repo.commit, "zlib repo should have commit")
        end
    end
    
    -- we should have three zlib entries (version constraint, specific version, shared config)
    local zlib_count = count_zlib_entries(plat_entries)
    assert(zlib_count == 3, "should find 3 zlib entries in lock file, found: " .. zlib_count)
    assert(found_zlib, "should find zlib entry in lock file")
    
    -- verify specific versions are locked correctly
    local found_old_version = false
    for key, package_data in pairs(plat_entries) do
        if key:find("zlib 1.2.13#") then
            found_old_version = true
            assert(package_data.version == "v1.2.13", "zlib 1.2.13 should be locked to v1.2.13")
        end
    end
    assert(found_old_version, "should find zlib 1.2.13 entry with v1.2.13")
    
    print("✓ lock file generation test passed")
end

-- test lock file stability across rebuilds
function test_lock_file_stability(scriptdir, t)
    local lockfile = path.join(scriptdir, "xmake-requires.lock")
    
    -- get the lock file content after first build
    local lockdata_after_first = io.load(lockfile)
    local keys_after_first = get_package_keys(lockdata_after_first)
    
    -- remove installed packages using xmake lua private.xrepo to trigger reinstallation
    os.execv("xmake", {"lua", "private.xrepo", "remove", "--all", "-y", "zlib"})
    
    -- rebuild and verify lock file content doesn't change
    t:build()
    
    local lockdata_after_second = io.load(lockfile)
    local keys_after_second = get_package_keys(lockdata_after_second)
    
    -- compare lock file content
    assert(lockdata_after_first.__meta__.version == lockdata_after_second.__meta__.version, "lock metadata version should not change")
    assert(count_table(lockdata_after_first) == count_table(lockdata_after_second), "lock file structure should not change")
    
    -- compare platform-specific entries
    local plat_entries_after_first = verify_lock_file_structure(lockdata_after_first)
    local plat_entries_after_second = verify_lock_file_structure(lockdata_after_second)
    
    assert(count_table(plat_entries_after_first) == count_table(plat_entries_after_second), "platform entries count should not change")
    
    -- verify package key order stability (keys should be in same order)
    assert(#keys_after_first == #keys_after_second, "package keys count should be the same")
    for i, key in ipairs(keys_after_first) do
        assert(keys_after_second[i] == key, "package key order should be stable at index " .. i .. ": " .. key)
    end
    
    -- verify each package entry is identical
    for key, first_data in pairs(plat_entries_after_first) do
        local second_data = plat_entries_after_second[key]
        assert(second_data, "package entry should exist: " .. key)
        assert(first_data.version == second_data.version, "version should not change for: " .. key)
        assert(first_data.repo.url == second_data.repo.url, "repo url should not change for: " .. key)
        assert(first_data.repo.commit == second_data.repo.commit, "repo commit should not change for: " .. key)
        assert(first_data.repo.branch == second_data.repo.branch, "repo branch should not change for: " .. key)
    end
    
    print("✓ lock file stability test passed")
end

function main(t)
    -- freebsd ci is slower
    if is_host("bsd", "solaris") then
        return
    end
    
    -- only for x86/x64, because it will take too long time on ci with arm/mips
    if os.subarch():startswith("x") or os.subarch() == "i386" then
        -- build project and generate requires lock
        t:build()
        
        -- get script directory from context filename
        local scriptdir = path.directory(t.filename)
        
        -- test requires lock file generation and content
        test_lock_file_generation(scriptdir)
        
        -- test building with existing lock file
        t:build()
        
        -- test lock file stability across rebuilds
        test_lock_file_stability(scriptdir, t)
        
        print("requires lock test passed!")
    end
end
