import("core.tools.gcc.parse_deps")

function test_dollar_in_path(t)
    local header = path.join(os.projectdir(), "a$b", "header.h")
    local escaped = path.unix(header):replace("$", "$$", {plain = true})
    local results = parse_deps("main.o: main.c " .. escaped .. "\n")
    t:require(table.contains(results, path.join("a$b", "header.h")))
end
