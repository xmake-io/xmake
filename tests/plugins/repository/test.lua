import("core.base.global")

function _write_plugin(dir, name, text)
    io.writefile(path.join(dir, "xmake.lua"), string.format([[
task("%s")
    set_category("plugin")
    on_run("main")
    set_menu {usage = "xmake %s"}
]], name, name))
    io.writefile(path.join(dir, "main.lua"), string.format([[function main() print("%s") end]], text))
end

function main(t)
    local suffix = path.filename(os.tmpfile()):gsub("[^%w]", "")
    local reponame = "plugin-test-repository-" .. suffix
    local hello_name = "plugin-test-hello-" .. suffix
    local formatter_name = "plugin-test-formatter-" .. suffix
    local available_name = "plugin-test-available-" .. suffix
    local local_name = "plugin-test-local-" .. suffix
    local repodir = os.tmpfile() .. ".plugins-repository"
    local localdir = path.join(os.tmpfile() .. ".local-plugin", local_name)
    local plugindir = path.join(global.directory(), "plugins")
    local cachefile = path.join(global.cachedir(), "repository")

    -- reset test state
    local function cleanup()
        for _, name in ipairs({hello_name, formatter_name, available_name, local_name}) do
            os.tryrm(path.join(plugindir, name))
        end
        local cache = os.isfile(cachefile) and io.load(cachefile) or {}
        cache.repositories = cache.repositories or {}
        cache.repositories[reponame] = nil
        io.save(cachefile, cache)
        os.tryrm(repodir)
        os.tryrm(path.directory(localdir))
    end
    cleanup()

    -- mock repository with installed and available plugins
    _write_plugin(path.join(repodir, "plugins", hello_name), hello_name, "repo-ok")
    _write_plugin(path.join(repodir, "plugins", formatter_name), formatter_name, "format-ok")
    _write_plugin(path.join(repodir, "plugins", available_name), available_name, "available-ok")
    os.mkdir(path.directory(cachefile))
    local cache = os.isfile(cachefile) and io.load(cachefile) or {}
    cache.repositories = cache.repositories or {}
    cache.repositories[reponame] = {repodir}
    io.save(cachefile, cache)

    -- Feature: install by plain name from repository
    os.runv("xmake", {"plugin", "--install", hello_name})
    os.runv("xmake", {hello_name})

    -- Feature: install by repo@name format
    os.runv("xmake", {"plugin", "--install", reponame .. "@" .. formatter_name})
    os.runv("xmake", {formatter_name})

    -- Feature: --list shows installed and available repository plugins
    local out = os.iorun("xmake plugin --list")
    t:require(out:find("the built-in plugins:", 1, true))
    t:require(out:find("project", 1, true))
    t:require(out:find(hello_name, 1, true))
    t:require(out:find(formatter_name, 1, true))
    t:require(out:find(available_name, 1, true))
    t:require(out:find("xmake plugin --install " .. available_name, 1, true))

    -- Feature: install from local directory
    _write_plugin(localdir, local_name, "local-ok")
    os.runv("xmake", {"plugin", "--install", localdir})
    os.runv("xmake", {local_name})

    out = os.iorun("xmake plugin --list")
    t:require(out:find(local_name, 1, true))

    -- Feature: remove plugin
    os.runv("xmake", {"plugin", "--remove", local_name})
    out = os.iorun("xmake plugin --list")
    t:require_not(out:find(local_name, 1, true))

    -- Feature: install non-existent plugin fails gracefully
    local ok = try { function () os.runv("xmake", {"plugin", "--install", "plugin-test-missing-" .. suffix}) return true end }
    t:require_not(ok)

    -- Feature: reject plugin name traversal
    ok = try { function () os.runv("xmake", {"plugin", "--install", reponame .. "@.."}) return true end }
    t:require_not(ok)

    cleanup()
end
