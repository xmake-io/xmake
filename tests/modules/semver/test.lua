import("core.base.semver")

-- select version
function _check_semver_select(t, results, required_ver, versions, tags, branches)
    local version, source = semver.select(required_ver, versions or {}, tags or {}, branches or {})
    t:are_equal((version.version or version), results[1])
    t:are_equal(source, results[2])
end

function _check_semver_select_failed(t, required_ver, versions, tags, branches)
    t:will_raise(function()
        semver.select(required_ver, versions or {}, tags or {}, branches or {})
    end, "unable to select version")
end

-- test select version
function test_semver_select(t)

    _check_semver_select(t, {"1.5.1", "version"}
                        , ">=1.5.0 <1.6.0"
                        , {"1.4.0", "1.5.0", "1.5.1"})

    _check_semver_select(t, {"1.5.1", "version"}
                        , "^1.5.0"
                        ,{"1.4.0", "1.5.0", "1.5.1"})

    _check_semver_select(t, {"3.53.0+200", "version"}
                        , "3.53.0+200"
                        , {"3.53.0+0", "3.53.0+100", "3.53.0+200"})

    _check_semver_select_failed(t, "3.53.0+999", {"3.53.0+100"})

    _check_semver_select(t, {"3.53.0+200", "version"}
                        , "3.53.0"
                        , {"3.53.0+0", "3.53.0+100", "3.53.0+200"})

    _check_semver_select(t, {"3.53.0+200", "version"}
                        , "3.53.0"
                        , {"3.53.0+200", "3.53.0+100", "3.53.0+0"})

    _check_semver_select(t, {"3.53.0+beta", "version"}
                        , "3.53.0"
                        , {"3.53.0+alpha", "3.53.0+beta"})

    _check_semver_select(t, {"3.53.0+beta", "version"}
                        , "3.53.0"
                        , {"3.53.0+beta", "3.53.0+alpha"})

    _check_semver_select(t, {"1.2.3", "version"}
                        , "1.2.3"
                        , {"1.2.3+1", "1.2.3"})

    _check_semver_select(t, {"1.2.3", "version"}
                        , "=1.2.3"
                        , {"1.2.3+7", "1.2.3"})

    _check_semver_select(t, {"1.2.9", "version"}
                        , "1.2"
                        , {"1.2", "1.2.9"})

    _check_semver_select(t, {"1.9.0", "version"}
                        , "^1.2.3"
                        , {"^1.2.3", "1.2.3", "1.9.0"})

    _check_semver_select(t, {"1.2.3", "tag"}
                        , "1.2.3"
                        , {"v1.2.3+7"}
                        , {"1.2.3"})

    _check_semver_select(t, {"v1.2.3+7", "version"}
                        , "1.2.3+7"
                        , {"v1.2.3+8", "v1.2.3+7"})

    _check_semver_select(t, {"1.2.3+7", "version"}
                        , "v1.2.3+7"
                        , {"1.2.3+8", "1.2.3+7"})

    _check_semver_select(t, {"3.53.0+200", "tag"}
                        , "3.53.0+200"
                        , nil
                        , {"3.53.0+0", "3.53.0+200"})

    _check_semver_select_failed(t, "3.53.0+999", nil, {"3.53.0+100"})

    _check_semver_select(t, {"v1.2.3+7", "tag"}
                        , "=1.2.3+7"
                        , nil
                        , {"v1.2.3+7", "v1.2.3+8"})

    _check_semver_select(t, {"v1.2.3+7", "tag"}
                        , "1.2.3+7"
                        , {"1.2.3+8"}
                        , {"v1.2.3+7"})

    _check_semver_select(t, {"master", "branch"}
                        , "master"
                        , {"1.4.0", "1.5.0", "1.5.1"}
                        , {"v1.2.0", "v1.6.0"}
                        , {"master", "dev"})

    _check_semver_select(t, {"next", "branch"}
                        , "next"
                        , nil
                        , {"vnext"}
                        , {"next"})

    _check_semver_select(t, {"1.5.1", "version"}
                        , "latest"
                        , {"1.4.0", "1.5.0", "1.5.1"})

    _check_semver_select(t, {"1.0.0+10", "version"}
                        , "latest"
                        , {"1.0.0+9", "1.0.0+10"})

    _check_semver_select(t, {"1.0.0+rev.10", "version"}
                        , "latest"
                        , {"1.0.0+rev.9", "1.0.0+rev.10"})

    _check_semver_select(t, {"3.53.0+200", "version"}
                        , "latest"
                        , {"3.53.0+0", "3.53.0+200", "3.53.0+100"})
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
    _check_semver_satisfies(t, true, "1.6.0", "v1.6.0")

    _check_semver_satisfies(t, false, "1.6.1", "~1.5.0")
    _check_semver_satisfies(t, false, "2.5.1", "^1.5.0")
    _check_semver_satisfies(t, false, "1.4.1", ">=1.5.0 <1.6.0")
    _check_semver_satisfies(t, false, "1.6.0", "v1.6.1")
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
