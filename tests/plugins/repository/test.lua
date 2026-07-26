function main()
    -- backup existing env vars
    local prev_globaldir = os.getenv("XMAKE_GLOBALDIR")
    local prev_main_repo = os.getenv("XMAKE_MAIN_REPO")

    local gd = os.tmpfile() .. ".gd"
    io.writefile(gd .. "/.xmake/repositories/xmake-repo/plugins/hello-world/xmake.lua", [[
task("hello-world")
    set_category("plugin")
    on_run("main")
    set_menu {usage = "xmake hello-world"}
]])
    io.writefile(gd .. "/.xmake/repositories/xmake-repo/plugins/hello-world/main.lua", [[
function main() print("repo-ok") end
]])

    os.setenv("XMAKE_GLOBALDIR", gd)
    os.exec("xmake hello-world")

    os.exec("xmake plugin --install hello-world")

    local md = os.tmpfile() .. ".md"
    io.writefile(md .. "/.xmake/plugins/manual-plugin/xmake.lua", [[
task("manual-plugin")
    set_category("plugin")
    on_run("main")
    set_menu {usage = "xmake manual-plugin"}
]])
    io.writefile(md .. "/.xmake/plugins/manual-plugin/main.lua", [[
function main() print("manual") end
]])

    os.setenv("XMAKE_GLOBALDIR", md)
    os.exec("xmake plugin --list")
    os.exec("xmake plugin --remove manual-plugin")

    local ld = os.tmpfile() .. ".ld"
    io.writefile(ld .. "/plugins/hello-world/xmake.lua", [[
task("hello-world")
    set_category("plugin")
    on_run("main")
    set_menu {usage = "xmake hello-world"}
]])
    io.writefile(ld .. "/plugins/hello-world/main.lua", [[
function main() print("local-ok") end
]])

    os.setenv("XMAKE_GLOBALDIR", gd)
    os.setenv("XMAKE_MAIN_REPO", ld)
    os.exec("xmake hello-world")

    os.setenv("XMAKE_MAIN_REPO", "")
    os.exec("xmake hello-world")

    -- restore env vars
    if prev_globaldir then
        os.setenv("XMAKE_GLOBALDIR", prev_globaldir)
    else
        os.setenv("XMAKE_GLOBALDIR", "")
    end
    if prev_main_repo then
        os.setenv("XMAKE_MAIN_REPO", prev_main_repo)
    else
        os.setenv("XMAKE_MAIN_REPO", "")
    end

    os.tryrm(gd)
    os.tryrm(md)
    os.tryrm(ld)
end
