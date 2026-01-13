import("core.project.config")

-- test lock file generation and basic content validation
function test_lock_file_generation(scriptdir)
    local lockfile = path.join(scriptdir, "xmake-requires.lock")
    assert(os.isfile(lockfile), "xmake-requires.lock should be generated")
    
    -- load and verify lock file content
    local lockdata = io.load(lockfile)
    assert(lockdata, "lock file should be loadable")
    assert(lockdata.__meta__, "lock file should have metadata")
    assert(lockdata.__meta__.version == "1.0", "lock file version should be 1.0")
    
    -- check platform-specific entries exist
    local plat = config.plat() or os.subhost()
    local arch = config.arch() or os.subarch()
    local plat_arch_key = plat .. "|" .. arch
    assert(lockdata[plat_arch_key], "should have entries for current platform: " .. plat_arch_key)
    
    -- check zlib entries
    local plat_entries = lockdata[plat_arch_key]
    local found_zlib = false
    local found_zlib_shared = false
    
    for key, package_data in pairs(plat_entries) do
        if key:find("zlib#") then
            found_zlib = true
            assert(package_data.version, "zlib should have version")
            assert(package_data.repo, "zlib should have repo info")
            assert(package_data.repo.url, "zlib repo should have url")
            assert(package_data.repo.commit, "zlib repo should have commit")
        end
    end
    
    -- we should have two zlib entries (one with version constraint, one with shared config)
    local zlib_count = 0
    for key, _ in pairs(plat_entries) do
        if key:find("zlib") then
            zlib_count = zlib_count + 1
        end
    end
    
    assert(zlib_count == 2, "should find 2 zlib entries in lock file, found: " .. zlib_count)
    assert(found_zlib, "should find zlib entry in lock file")
    
    print("✓ lock file generation test passed")
end

-- test lock file stability across rebuilds
function test_lock_file_stability(scriptdir, t)
    local lockfile = path.join(scriptdir, "xmake-requires.lock")
    
    -- get the lock file content after first build
    local lockdata_after_first = io.load(lockfile)
    
    -- remove installed packages using xmake lua private.xrepo to trigger reinstallation
    os.execv("xmake", {"lua", "private.xrepo", "remove", "--all", "-y", "zlib"})
    
    -- rebuild and verify lock file content doesn't change
    t:build()
    
    local lockdata_after_second = io.load(lockfile)
    
    -- compare lock file content
    assert(lockdata_after_first.__meta__.version == lockdata_after_second.__meta__.version, "lock metadata version should not change")
    
    -- count table entries properly
    local function count_table(t)
        local count = 0
        for _ in pairs(t) do
            count = count + 1
        end
        return count
    end
    
    assert(count_table(lockdata_after_first) == count_table(lockdata_after_second), "lock file structure should not change")
    
    -- compare platform-specific entries
    local plat = config.plat() or os.subhost()
    local arch = config.arch() or os.subarch()
    local plat_arch_key = plat .. "|" .. arch
    
    local first_plat_entries = lockdata_after_first[plat_arch_key]
    local second_plat_entries = lockdata_after_second[plat_arch_key]
    
    assert(count_table(first_plat_entries) == count_table(second_plat_entries), "platform entries count should not change")
    
    -- verify each package entry is identical
    for key, first_data in pairs(first_plat_entries) do
        local second_data = second_plat_entries[key]
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
