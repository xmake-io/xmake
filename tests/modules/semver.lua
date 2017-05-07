-- imports
import("core.base.semver")

-- select version
function _check_semver_select(results, required_ver, versions, tags, branches)

    -- select it
    local version, source = semver.select(required_ver, versions, tags, branches)
    if version ~= results[1] or source ~= results[2] then
        print("semver.select(\"%s\", {\"%s\"}, {\"%s\"}, {\"%s\"})"
            , required_ver
            , table.concat(versions or {}, "\", \"")
            , table.concat(tags     or {}, "\", \"")
            , table.concat(branches or {}, "\", \""))
        raise("{\"%s\", \"%s\"} != {\"%s\", \"%s\"}", version or "", source or "", results[1] or "", results[2] or "")
    end
end

-- test select version
function _test_semver_select()

    _check_semver_select({"1.5.0", "versions"}
                        , ">=1.5.0 <1.6.0"
                        , {"1.4.0", "1.5.0", "1.5.1"})

    _check_semver_select({"1.5.0", "versions"}
                        , "^1.5.0"
                        ,{"1.4.0", "1.5.0", "1.5.1"})

    _check_semver_select({"master", "branches"}
                        , "master || >=1.5.0 <1.6.0"
                        , {"1.4.0", "1.5.0", "1.5.1"}
                        , {"v1.2.0", "v1.6.0"}
                        , {"master", "dev"})

    print("semver.select: ok!")
end

-- select version
function _check_semver(version_str, major, minor, patch, prerelease, build)

    -- create it
    local version = semver(version_str)

    if version.major ~= major then
        raise("major: \"%s\" != \"%s\"", version.major or "", major or "")
    end

    if version.minor ~= minor then
        raise("minor: \"%s\" != \"%s\"", version.minor or "", minor or "")
    end

    if version.patch ~= patch then
        raise("patch: \"%s\" != \"%s\"", version.patch or "", patch or "")
    end

    if table.concat(version.prerelease or {}, ".") ~= table.concat(prerelease or {}, ".") then
        raise("prerelease: \"%s\" != \"%s\""
            , table.concat(version.prerelease or {}, ".") or ""
            , table.concat(prerelease or {}, ".") or "")
    end

    if table.concat(version.build or {}, ".") ~= table.concat(build or {}, ".") then
        raise("build: \"%s\" != \"%s\""
            , table.concat(version.build or {}, ".") or ""
            , table.concat(build or {}, ".") or "")
    end

    local expected_str = major.."."..minor.."."..patch
    if prerelease then
        expected_str = expected_str.."-"..table.concat(prerelease or {}, ".")
    end

    if version.version ~= expected_str then
        raise("version: \"%s\" != \"%s\"", version.version or "", expected_str or "")
    end

    if tostring(version) ~= expected_str then
        raise("str: \"%s\" != \"%s\"", tostring(version) or "", expected_str or "")
    end
end

-- test version
function _test_semver()

    _check_semver("1.2.3", 1, 2, 3)
    _check_semver("1.2.3-beta", 1, 2, 3, {"beta"})
    _check_semver("1.2.3-beta+77", 1, 2, 3, {"beta"}, {"77"})
    _check_semver("v1.2.3-alpha.1+77", 1, 2, 3, {"alpha", "1"}, {"77"})
    _check_semver("v3.2.1-alpha.1+77.foo", 3, 2, 1, {"alpha", "1"}, {"77", "foo"})

    print("semver: ok!")
end

-- compare version
function _check_semver_compare(v1, v2, result)

    local comparison = semver.compare(v1, v2)
    if comparison ~= result then
        raise("\"%s\" ^ \"%s\" != %s got %s", v1 or "", v2 or "", result, comparison)
    end
end

-- test compare version
function _test_semver_compare()

    _check_semver_compare("1.2.3", "1.2.2", 1)
    _check_semver_compare("1.2.3", "1.2.3", 0)
    _check_semver_compare("1.2.2", "1.2.3", -1)

    print("semver.compare: ok!")
end

--
-- run tests:
--
-- $ xmake l ./tests/modules/semver.lua
--
function main()

    -- test semver
    _test_semver()

    -- test semver compare
    _test_semver_compare()

    -- test select version
    _test_semver_select()
end
