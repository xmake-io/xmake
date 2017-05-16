-- imports
import("core.base.semver")

--
-- run tests:
--
-- $ xmake l ./tests/modules/semver.lua
--
function main()
    -- print(semver.satisfies('1.2.3', '1.x || >=2.5.0 || 5.0.0 - 7.2.3'))

    local version, source = semver.select(">=1.5.0 <1.6", {"1.7.0"}, {"v1.5.0", "v1.5.9"}, {"master", "dev"});
    print(string.format("%d.%d.%d", version.major, version.minor, version.patch))
    print(source)

    version, source = semver.select(">=1.5.0 <1.6", {"1.5.0", "1.5.1"}, {}, {"master", "dev"});
    print(string.format("%d.%d.%d", version.major, version.minor, version.patch))
    print(source)

    version, source = semver.select("master", {"1.7.0"}, {"v1.5.0", "v1.5.9"}, {"master", "dev"});
    print(version)
    print(source)
end
