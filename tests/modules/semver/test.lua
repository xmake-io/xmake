import("core.base.semver")

-- select version
function _check_semver_select(t, results, required_ver, versions, tags, branches)
    local version, source = semver.select(required_ver, versions or {}, tags or {}, branches or {})
    t:are_equal((version.version or version), results[1])
    t:are_equal(source, results[2])
end

-- test select version
function test_semver_select(t)

    _check_semver_select(t, {"1.5.1", "versions"}
                        , ">=1.5.0 <1.6.0"
                        , {"1.4.0", "1.5.0", "1.5.1"})

    _check_semver_select(t, {"1.5.1", "versions"}
                        , "^1.5.0"
                        ,{"1.4.0", "1.5.0", "1.5.1"})

    _check_semver_select(t, {"master", "branches"}
                        , "master"
                        , {"1.4.0", "1.5.0", "1.5.1"}
                        , {"v1.2.0", "v1.6.0"}
                        , {"master", "dev"})

    _check_semver_select(t, {"1.5.1", "versions"}
                        , "latest"
                        , {"1.4.0", "1.5.0", "1.5.1"})
end

-- select version
function _check_semver_satisfies(t, expected, version, range)
    local result = semver.satisfies(version, range)
    t:are_equal(result, expected)
end

-- test satisfies version
function test_semver_satisfies(t)

    _check_semver_satisfies(t, true, "1.5.1", ">=1.5.0 <1.6.0")
    _check_semver_satisfies(t, true, "1.5.1", "^1.5.0")
    _check_semver_satisfies(t, true, "1.5.1", "~1.5.0")
    _check_semver_satisfies(t, true, "1.6.0", "^1.5.0")

    _check_semver_satisfies(t, false, "1.6.1", "~1.5.0")
    _check_semver_satisfies(t, false, "2.5.1", "^1.5.0")
    _check_semver_satisfies(t, false, "1.4.1", ">=1.5.0 <1.6.0")
end

-- parse version
function _check_semver_parse(t, version_str, major, minor, patch, prerelease, build)
    local version = semver.new(version_str)
    t:require(version)
    t:are_equal(version:major(), major)
    t:are_equal(version:minor(), minor)
    t:are_equal(version:patch(), patch)
    t:are_equal(version:prerelease(), prerelease or {})
    t:are_equal(version:build(), build or {})
end

-- match version
function _check_semver_match(t, str, version_str, major, minor, patch, prerelease, build)
    local version = semver.match(str)
    t:require(version)
    t:are_equal(version:rawstr(), version_str)
    t:are_equal(version:major(), major)
    t:are_equal(version:minor(), minor)
    t:are_equal(version:patch(), patch)
    t:are_equal(version:prerelease(), prerelease or {})
    t:are_equal(version:build(), build or {})
end

-- test parse version
function test_semver_parse(t)

    _check_semver_parse(t, "1.2.3", 1, 2, 3)
    _check_semver_parse(t, "1.2.3-beta", 1, 2, 3, {"beta"})
    _check_semver_parse(t, "1.2.3-beta+77", 1, 2, 3, {"beta"}, {77})
    _check_semver_parse(t, "v1.2.3-alpha.1+77", 1, 2, 3, {"alpha", 1}, {77})
    _check_semver_parse(t, "v3.2.1-alpha.1+77.foo", 3, 2, 1, {"alpha", 1}, {77, "foo"})
end

-- test match version string
function test_semver_match(t)
    _check_semver_match(t, "gcc (Ubuntu 7.4.0-1ubuntu1~18.04.1) 7.4.0", "7.4.0-1ubuntu1", 7, 4, 0, {"1ubuntu1"})
    _check_semver_match(t, "gcc (i686-posix-dwarf-rev0, Built by MinGW-W64 project) 8.1.0", "8.1.0", 8, 1, 0)
    _check_semver_match(t, "DMD64 D Compiler v2.090.0", "2.090.0", 2, 90, 0)
    _check_semver_match(t, "Apple clang version 11.0.0 (clang-1100.0.33.12)", "11.0.0", 11, 0, 0)
    _check_semver_match(t, "curl 7.54.0 (x86_64-apple-darwin18.0) libcurl/7.54.0 LibreSSL/2.6.5 zlib/1.2.11 nghttp2/1.24.1", "7.54.0", 7, 54, 0)
end
