-- imports
import("core.base.semver")

--
-- run tests:
--
-- $ xmake l ./tests/modules/semver.lua
--
function main()

    -- test semver
    local sv = semver.parse("v1.2.3-alpha.25+77.2")

    local buffer = { ("%d.%d.%d"):format(sv.major, sv.minor, sv.patch) }
    local a = table.concat(sv.prerelease, ".")
    if a and a:len() > 0 then table.insert(buffer, "-" .. a) end
    local b = table.concat(sv.build, ".")
    if b and b:len() > 0 then table.insert(buffer, "+" .. b) end

    print(table.concat(buffer))
end
