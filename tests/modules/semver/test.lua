-- imports
import("core.base.semver")

-- select version
function _check_semver_select(results, required_ver, versions, tags, branches)

    -- select it
    local version, source = semver.select(required_ver, versions or {}, tags or {}, branches or {})
    if (version.version or version) ~= results[1] or source ~= results[2] then
        print("semver.select(\"%s\", {\"%s\"}, {\"%s\"}, {\"%s\"})"
            , required_ver
            , table.concat(versions or {}, "\", \"")
            , table.concat(tags     or {}, "\", \"")
            , table.concat(branches or {}, "\", \""))
        raise("{\"%s\", \"%s\"} != {\"%s\", \"%s\"}", version.version or version, source or "", results[1] or "", results[2] or "")
    end
end

-- test select version
function _test_semver_select()

    _check_semver_select({"1.5.1", "versions"}
                        , ">=1.5.0 <1.6.0"
                        , {"1.4.0", "1.5.0", "1.5.1"})

    _check_semver_select({"1.5.1", "versions"}
                        , "^1.5.0"
                        ,{"1.4.0", "1.5.0", "1.5.1"})

    _check_semver_select({"master", "branches"}
                        , "master"
                        , {"1.4.0", "1.5.0", "1.5.1"}
                        , {"v1.2.0", "v1.6.0"}
                        , {"master", "dev"})

    _check_semver_select({"1.5.1", "versions"}
                        , "lastest"
                        , {"1.4.0", "1.5.0", "1.5.1"})

    print("semver.select: ok!")
end

-- select version
function _check_semver_satisfies(expected, version, range)

    -- select it
    local result = semver.satisfies(version, range)
    if expected ~= result then
        print("semver.satisfies(\"%s\", \"%s\")"
            , version
            , range)
        raise("\"%s\" != \"%s\"", expected, result)
    end
end

-- test satisfies version
function _test_semver_satisfies()

    _check_semver_satisfies(true, "1.5.1", ">=1.5.0 <1.6.0")
    _check_semver_satisfies(true, "1.5.1", "^1.5.0")

    print("semver.satisfies: ok!")
end

-- parse version
function _check_semver_parse(version_str, major, minor, patch, prerelease, build)

    -- create it
    local version = semver.parse(version_str)

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
end

-- test parse version
function _test_semver_parse()

    _check_semver_parse("1.2.3", 1, 2, 3)
    _check_semver_parse("1.2.3-beta", 1, 2, 3, {"beta"})
    _check_semver_parse("1.2.3-beta+77", 1, 2, 3, {"beta"}, {"77"})
    _check_semver_parse("v1.2.3-alpha.1+77", 1, 2, 3, {"alpha", "1"}, {"77"})
    _check_semver_parse("v3.2.1-alpha.1+77.foo", 3, 2, 1, {"alpha", "1"}, {"77", "foo"})

    print("semver.parse: ok!")
end

--
-- run tests:
--
-- $ make test name=semver
--
function main()

    -- test semver
    _test_semver_parse()

    -- test semver satisfies
    _test_semver_satisfies()

    -- test select version
    _test_semver_select()
end
