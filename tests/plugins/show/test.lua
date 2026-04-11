import("core.base.json")

local function _create_project(tempdir)
    io.writefile(path.join(tempdir, "xmake.lua"), [[
add_rules("mode.debug", "mode.release")

target("core")
    set_kind("static")
    add_files("src/core.c")

target("ui")
    set_kind("static")
    add_deps("core")
    add_files("src/ui.c")

target("app")
    set_kind("binary")
    add_deps("core", "ui")
    add_files("src/main.c")
]])
    os.mkdir(path.join(tempdir, "src"))
    io.writefile(path.join(tempdir, "src", "core.c"), "int core(void) { return 0; }\n")
    io.writefile(path.join(tempdir, "src", "ui.c"), "int ui(void) { return 0; }\n")
    io.writefile(path.join(tempdir, "src", "main.c"), "int main(void) { return 0; }\n")
end

function test_target_graph_json(t)
    local tempdir = os.tmpfile()
    os.mkdir(tempdir)
    _create_project(tempdir)

    local homedir = path.join(tempdir, "home")
    os.setenv("HOME", homedir)
    os.mkdir(homedir)
    os.mkdir(path.join(homedir, ".xmake"))

    local outdata = os.iorunv("xmake", {"show", "-P", tempdir, "--info=depgraph", "--json"})
    local graph = json.decode(outdata)

    t:are_equal(graph.root_targets, {"app"})
    t:require(#graph.targets == 3)

    local entries = {}
    for _, target in ipairs(graph.targets) do
        entries[target.name] = target
    end
    t:are_equal(entries.core.deps, {})
    t:are_equal(entries.ui.deps, {"core"})
    t:are_equal(entries.app.deps, {"core", "ui"})
    t:are_equal(entries.app.orderdeps, {"core", "ui"})
    t:are_equal(entries.app.kind, "binary")
end

function test_target_graph_json_for_single_target(t)
    local tempdir = os.tmpfile()
    os.mkdir(tempdir)
    _create_project(tempdir)

    local homedir = path.join(tempdir, "home")
    os.setenv("HOME", homedir)
    os.mkdir(homedir)
    os.mkdir(path.join(homedir, ".xmake"))

    local outdata = os.iorunv("xmake", {"show", "-P", tempdir, "--info=depgraph", "--target=app", "--json"})
    local graph = json.decode(outdata)

    t:are_equal(graph.root_targets, {"app"})
    t:require(#graph.targets == 3)

    local names = {}
    for _, target in ipairs(graph.targets) do
        table.insert(names, target.name)
    end
    t:are_equal(names, {"core", "ui", "app"})
end
