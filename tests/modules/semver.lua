-- imports
import("core.base.semver")

--
-- run tests:
--
-- $ xmake l ./tests/modules/semver.lua
--
function main()

    -- test semver
    local sv = semver.parse("1.2.3")
    print(string.format("v%d.%d.%d", sv.major, sv.minor, sv.patch))
end
