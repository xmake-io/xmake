import("core.project.config")

-- helper function to count table entries
function count_table(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- helper function to get all package keys from lock data
function get_package_keys(lockdata)
    local keys = {}
    for key, _ in pairs(lockdata) do
        if key ~= "__meta__" then
            table.insert(keys, key)
        end
    end
    return keys
end

-- helper function to verify lock file basic structure
function verify_lock_file_structure(lockdata)
    assert(lockdata, "lock file should be loadable")
    assert(lockdata.__meta__, "lock file should have metadata")
    assert(lockdata.__meta__.version == "1.0", "lock file version should be 1.0")

    -- find any platform entry
    local found_platform = nil
    for key, value in pairs(lockdata) do
        if key ~= "__meta__" then
            found_platform = key
            break
        end
    end

    assert(found_platform, "no platform entries found in lock file")
    return lockdata[found_platform]
end

-- helper function to count zlib entries
function count_zlib_entries(plat_entries)
    local zlib_count = 0
    for key, _ in pairs(plat_entries) do
        if key:find("zlib") then
            zlib_count = zlib_count + 1
        end
    end
    return zlib_count
end

-- helper function to remove installed packages to trigger reinstallation
function remove_zlib_packages()
    os.execv("xmake", {"lua", "private.xrepo", "remove", "--all", "-y", "zlib"})
end

-- helper function to remove existing lock file
function remove_lock_file(scriptdir)
    local lockfile = path.join(scriptdir, "xmake-requires.lock")
    os.tryrm(lockfile)
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

    -- get the lock file content and mtime after first build
    local lockdata_after_first = io.load(lockfile)
    local mtime_after_first = os.mtime(lockfile)
    local keys_after_first = get_package_keys(lockdata_after_first)

    -- remove installed packages using xmake lua private.xrepo to trigger reinstallation
    remove_zlib_packages()

    -- rebuild and verify lock file content doesn't change
    t:build()

    local lockdata_after_second = io.load(lockfile)
    local mtime_after_second = os.mtime(lockfile)
    local keys_after_second = get_package_keys(lockdata_after_second)

    -- compare lock file content
    assert(lockdata_after_first.__meta__.version == lockdata_after_second.__meta__.version, "lock metadata version should not change")
    assert(count_table(lockdata_after_first) == count_table(lockdata_after_second), "lock file structure should not change")

    -- compare platform-specific entries using the same platform for consistency
    local plat_entries_after_first = verify_lock_file_structure(lockdata_after_first)
    local plat_entries_after_second = verify_lock_file_structure(lockdata_after_second)

    -- ensure we're comparing the same platform entries by finding the common platform
    local first_platform_key = nil
    for key, value in pairs(lockdata_after_first) do
        if key ~= "__meta__" then
            first_platform_key = key
            break
        end
    end

    assert(first_platform_key, "no platform found in first lock file")
    assert(lockdata_after_second[first_platform_key], "platform " .. first_platform_key .. " not found in second lock file")

    plat_entries_after_first = lockdata_after_first[first_platform_key]
    plat_entries_after_second = lockdata_after_second[first_platform_key]

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
        assert(first_data.version == second_data.version, "version should not change for: " .. key .. ", first: " .. (first_data.version or "nil") .. ", second: " .. (second_data.version or "nil"))
        assert(first_data.repo.url == second_data.repo.url, "repo url should not change for: " .. key .. ", first: " .. (first_data.repo.url or "nil") .. ", second: " .. (second_data.repo.url or "nil"))
        assert(first_data.repo.commit == second_data.repo.commit, "repo commit should not change for: " .. key .. ", first: " .. (first_data.repo.commit or "nil") .. ", second: " .. (second_data.repo.commit or "nil"))
        assert(first_data.repo.branch == second_data.repo.branch, "repo branch should not change for: " .. key .. ", first: " .. (first_data.repo.branch or "nil") .. ", second: " .. (second_data.repo.branch or "nil"))
    end

    -- verify mtime doesn't change (lock file should only be written when content actually changes)
    -- With copy_if_different, the file should not be rewritten if content is identical
    local time_diff = math.abs(mtime_after_second - mtime_after_first)
    print("lock file mtime difference: " .. time_diff .. "s")
    -- mtime should be exactly the same when content is identical
    assert(time_diff == 0, "lock file mtime should not change when content is identical, diff: " .. time_diff .. "s")

    print("✓ lock file stability test passed")
end

function main(t)
    -- freebsd ci is slower
    if is_host("bsd", "solaris") then
        return
    end

    -- only for x86/x64, because it will take too long time on ci with arm/mips
    if os.subarch():startswith("x") or os.subarch() == "i386" then

        -- get script directory from context filename
        local scriptdir = path.directory(t.filename)

        -- remove existing lock file before test
        remove_lock_file(scriptdir)

        -- remove installed packages using xmake lua private.xrepo to trigger reinstallation
        remove_zlib_packages()

        -- build project and generate requires lock
        t:build()

        -- test requires lock file generation and content
        test_lock_file_generation(scriptdir)

        -- test building with existing lock file
        t:build()

        -- test lock file stability across rebuilds
        test_lock_file_stability(scriptdir, t)

        print("requires lock test passed!")
    end
end
