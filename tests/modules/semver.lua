-- imports
import("core.base.semver")

--
-- run tests:
--
-- $ xmake l ./tests/modules/semver.lua
--
function main()
    print(semver.satisfies('1.2.3', '1.x || >=2.5.0 || 5.0.0 - 7.2.3'))
end
