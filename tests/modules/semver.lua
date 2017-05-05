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
function _check_semver( major, minor, patch, prerelease, build)

    local str = minor .. "." .. patch .. "." .. build
    if (prerelease) then
        str = str .. "-" .. prerelease
    end
    local strnbuild = str
    if (build) then
        strnbuild = strnbuild .. "+" .. build
    end

    -- create it
    local version = semver(major, minor .. "." .. patch .. "." .. build .. "-" .. prerelease .. "." .. build)
    print(version)
end

--
-- run tests:
--
-- $ xmake l ./tests/modules/semver.lua
--
function main()

    -- test semver
    _check_semver(1, 2, 3, "beta", "77")

    -- test select version
    -- _test_semver_select()
end
