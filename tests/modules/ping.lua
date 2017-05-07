-- imports
import("core.tool.ping")

--
-- run tests:
--
-- $ xmake l ./tests/modules/ping.lua
--
function main()

    -- send ping
    table.dump(ping.send("www.tboox.org", "www.xmake.io", "www.github.com", "www.google.com", "unknown.invalid"))
end
