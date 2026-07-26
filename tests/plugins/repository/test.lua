function main()
    local prog = os.programfile()
    local gd = os.tmpfile() .. ".gd"
    io.writefile(path.join(gd, ".xmake", "repositories", "xmake-repo", "plugins", "hello-world", "xmake.lua"), [[
task("hello-world")
    set_category("plugin")
    on_run("main")
    set_menu {usage = "xmake hello-world"}
]])
    io.writefile(path.join(gd, ".xmake", "repositories", "xmake-repo", "plugins", "hello-world", "main.lua"), [[
function main() print("repo-ok") end
]])
    local out = os.iorunv(prog, {"hello-world"}, {envs = {XMAKE_GLOBALDIR = gd}})
    assert(out:find("repo%-ok", 1, true))
    local out = os.iorunv(prog, {"hello-world"}, {envs = {XMAKE_PROGRAM_DIR = os.programdir(), XMAKE_GLOBALDIR = gd}})
    assert(out:find("xrepo", 1, true))

    local md = os.tmpfile() .. ".md"
    io.writefile(path.join(md, ".xmake", "plugins", "manual-plugin", "xmake.lua"), [[
task("manual-plugin")
    set_category("plugin")
    on_run("main")
    set_menu {usage = "xmake manual-plugin"}
]])
    io.writefile(path.join(md, ".xmake", "plugins", "manual-plugin", "main.lua"), [[
function main() print("manual") end
]])
    out = os.iorunv(prog, {"plugin", "--list"}, {envs = {XMAKE_GLOBALDIR = md}})
    assert(out:find("manual%-plugin", 1, true))
    out = os.iorunv(prog, {"plugin", "--list"}, {envs = {XMAKE_GLOBALDIR = gd}})
    assert(out:find("hello%-world", 1, true))

    out = os.iorunv(prog, {"plugin", "--remove", "manual-plugin"}, {envs = {XMAKE_GLOBALDIR = md}})
    assert(out:find("remove plugin", 1, true))
    out = os.iorunv(prog, {"plugin", "--list"}, {envs = {XMAKE_GLOBALDIR = md}})
    assert(not out:find("manual%-plugin", 1, true))

    local ld = os.tmpfile() .. ".ld"
    io.writefile(path.join(ld, "plugins", "hello-world", "xmake.lua"), [[
task("hello-world")
    set_category("plugin")
    on_run("main")
    set_menu {usage = "xmake hello-world"}
]])
    io.writefile(path.join(ld, "plugins", "hello-world", "main.lua"), [[
function main() print("local-ok") end
]])
    out = os.iorunv(prog, {"hello-world"}, {envs = {XMAKE_GLOBALDIR = gd, XMAKE_MAIN_REPO = ld}})
    assert(out:find("local%-ok", 1, true))
    out = os.iorunv(prog, {"hello-world"}, {envs = {XMAKE_GLOBALDIR = gd}})
    assert(out:find("repo%-ok", 1, true))

    os.tryrm(gd)
    os.tryrm(md)
    os.tryrm(ld)
end
