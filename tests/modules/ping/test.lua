-- imports
import("net.ping")

--
-- run tests:
--
-- $ xmake l ./tests/modules/ping.lua
--
function main()

    -- send ping
    print(ping("www.tboox.org", "www.xmake.io", "www.github.com", "www.google.com", "unknown.invalid"))
end
