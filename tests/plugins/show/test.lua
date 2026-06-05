import("core.base.json")

function test_list_targets_json_format(t)
    local outdata = os.iorunv("xmake", {"show", "-l", "targets", "--format=json"})
    local targets = json.decode(outdata)

    t:require(table.contains(targets, "app"))
    t:require(table.contains(targets, "core"))
    t:require(table.contains(targets, "ui"))
end

function test_list_targets_plain_format(t)
    local outdata = os.iorunv("xmake", {"show", "-l", "targets", "--format=plain"})
    t:require(outdata:find("app", 1, true))
    t:require(outdata:find("core", 1, true))
    t:require(outdata:find("ui", 1, true))
end

function test_list_targets_unsupported_format(t)
    local ok = try { function () os.execv("xmake", {"show", "-l", "targets", "--format=dot"}) end }
    t:require(not ok)
end

function test_depgraph_json(t)
    local outdata = os.iorunv("xmake", {"show", "--info=depgraph", "--json"})
    local graph = json.decode(outdata)

    t:are_equal(graph.root_targets, {"app"})
    t:require(#graph.targets == 4)

    local entries = {}
    for _, target in ipairs(graph.targets) do
        entries[target.name] = target
    end
    t:are_equal(entries.core.deps, {})
    t:are_equal(entries.ui.deps, {"core"})
    t:are_equal(entries["ext::net"].deps, {"core"})
    t:are_equal(entries.app.deps, {"core", "ui", "ext::net"})
end

function test_depgraph_json_for_single_target(t)
    local outdata = os.iorunv("xmake", {"show", "--info=depgraph", "--target=app", "--json"})
    local graph = json.decode(outdata)

    t:are_equal(graph.root_targets, {"app"})
    t:require(#graph.targets == 4)

    local names = {}
    for _, target in ipairs(graph.targets) do
        table.insert(names, target.name)
    end
    t:require(table.contains(names, "core"))
    t:require(table.contains(names, "ui"))
    t:require(table.contains(names, "ext::net"))
    t:require(table.contains(names, "app"))
end

function test_depgraph_json_namespace(t)
    local outdata = os.iorunv("xmake", {"show", "--info=depgraph", "--target=ext::net", "--json"})
    local graph = json.decode(outdata)

    t:are_equal(graph.root_targets, {"ext::net"})
    t:require(#graph.targets == 2)

    local entries = {}
    for _, target in ipairs(graph.targets) do
        entries[target.name] = target
    end
    t:require(entries["ext::net"])
    t:are_equal(entries["ext::net"].deps, {"core"})
    t:are_equal(entries.core.deps, {})
end

function test_depgraph_tree(t)
    local outdata = os.iorunv("xmake", {"show", "--info=depgraph"})
    t:require(outdata:find("app", 1, true))
    t:require(outdata:find("core", 1, true))
    t:require(outdata:find("ui", 1, true))
    t:require(outdata:find("ext::net", 1, true))
    t:require(outdata:find("|-- ", 1, true))
    t:require(outdata:find("\\-- ", 1, true))
end

function test_depgraph_dot(t)
    local outdata = os.iorunv("xmake", {"show", "--info=depgraph", "--format=dot"})
    t:require(outdata:find("digraph {", 1, true))
    t:require(outdata:find('"core"', 1, true))
    t:require(outdata:find('"ui" -> "core"', 1, true))
    t:require(outdata:find('"app" -> "core"', 1, true))
    t:require(outdata:find('"app" -> "ui"', 1, true))
    t:require(outdata:find('"ext::net" -> "core"', 1, true))
    t:require(outdata:find('"app" -> "ext::net"', 1, true))
    t:require(outdata:find("}", 1, true))
end

function test_depgraph_dot_for_single_target(t)
    local outdata = os.iorunv("xmake", {"show", "--info=depgraph", "--target=ui", "--format=dot"})
    t:require(outdata:find("digraph {", 1, true))
    t:require(outdata:find('"core"', 1, true))
    t:require(outdata:find('"ui" -> "core"', 1, true))
    t:require(not outdata:find('"app"', 1, true))
end
