import("core.base.global")

-- write a minimal plugin that prints its name when run
function _write_plugin(dir, name)
    io.writefile(path.join(dir, "xmake.lua"), string.format([[
task("%s")
    set_category("plugin")
    on_run("main")
    set_menu {usage = "xmake %s", description = "say hello from %s"}
]], name, name, name))
    io.writefile(path.join(dir, "main.lua"), string.format([[function main() print("%s") end]], name))
end

-- create a temporary plugin repository (packages layout: plugins/<first-letter>/<name>) and register it
--
-- @return reponame, names, cleanup
function _mock_repo(basenames)
    local suffix = path.filename(os.tmpfile()):gsub("[^%w]", "")
    local reponame = "plugin-test-repo-" .. suffix
    local repodir = os.tmpfile() .. ".plugin-repo"
    local names = {}
    for _, base in ipairs(basenames) do
        local name = base .. "-" .. suffix
        _write_plugin(path.join(repodir, "plugins", name:sub(1, 1), name), name)
        table.insert(names, name)
    end

    -- register the repository into the cache
    local cachefile = path.join(global.cachedir(), "repository")
    local cache = os.isfile(cachefile) and io.load(cachefile) or {}
    cache.repositories = cache.repositories or {}
    cache.repositories[reponame] = {repodir}
    io.save(cachefile, cache)

    local function cleanup()
        for _, name in ipairs(names) do
            os.tryrm(path.join(global.directory(), "plugins", name))
        end
        local cache = os.isfile(cachefile) and io.load(cachefile) or {}
        if cache.repositories then
            cache.repositories[reponame] = nil
        end
        io.save(cachefile, cache)
        os.tryrm(repodir)
    end
    return reponame, names, cleanup
end

-- install a plugin from a repository, by plain name and by repo@name
function test_install_from_repo(t)
    local reponame, names, cleanup = _mock_repo({"hello"})
    local name = names[1]

    -- install by plain name (searched across all repositories)
    os.runv("xmake", {"plugin", "--install", name})
    t:require(os.iorunv("xmake", {name}):find(name, 1, true))

    -- reinstall by repo@name
    os.runv("xmake", {"plugin", "--remove", name})
    os.runv("xmake", {"plugin", "--install", reponame .. "@" .. name})
    t:require(os.iorunv("xmake", {name}):find(name, 1, true))

    os.runv("xmake", {"plugin", "--remove", name})
    cleanup()
end

-- install a plugin from a local directory, then remove it
function test_install_from_local(t)
    local suffix = path.filename(os.tmpfile()):gsub("[^%w]", "")
    local name = "hello-local-" .. suffix
    local dir = path.join(os.tmpfile() .. ".plugin-local", name)
    _write_plugin(dir, name)

    os.runv("xmake", {"plugin", "--install", dir})
    t:require(os.iorunv("xmake", {name}):find(name, 1, true))

    -- the removed plugin should no longer be runnable
    os.runv("xmake", {"plugin", "--remove", name})
    t:require_not(try { function () os.runv("xmake", {name}); return true end })

    os.tryrm(path.directory(dir))
end

-- --list shows the built-in, installed and available plugins
function test_list(t)
    local reponame, names, cleanup = _mock_repo({"hello", "world"})

    -- install the first plugin, leave the second only available
    os.runv("xmake", {"plugin", "--install", names[1]})
    local out = os.iorunv("xmake", {"plugin", "--list"})
    t:require(out:find("the built-in plugins:", 1, true))
    t:require(out:find("project", 1, true))
    t:require(out:find(names[1], 1, true))
    t:require(out:find(names[2], 1, true))
    t:require(out:find("xmake plugin --install " .. names[2], 1, true))

    os.runv("xmake", {"plugin", "--remove", names[1]})
    cleanup()
end

-- invalid installs should fail
function test_install_invalid(t)
    t:require_not(try { function () os.runv("xmake", {"plugin", "--install", "plugin-test-missing"}); return true end })
    t:require_not(try { function () os.runv("xmake", {"plugin", "--install", "somerepo@.."}); return true end })
end
