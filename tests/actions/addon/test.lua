import("core.base.global")

-- write a minimal plugin that prints its name when run
--
-- the plugins of an addon are placed in its `plugins` payload directory,
-- e.g. <addondir>/plugins/<name>/xmake.lua
function _write_plugin(dir, name)
    io.writefile(path.join(dir, "xmake.lua"), string.format([[
task("%s")
    set_category("plugin")
    on_run("main")
    set_menu {usage = "xmake %s", description = "say hello from %s"}
]], name, name, name))
    io.writefile(path.join(dir, "main.lua"), string.format([[function main() print("%s") end]], name))
end

-- write a minimal template into the `templates` payload directory of an addon,
-- e.g. <addondir>/templates/<language>/<templateid>/xmake.lua
function _write_template(dir, lang, templateid)
    local templatedir = path.join(dir, "templates", lang, templateid)
    io.writefile(path.join(templatedir, "xmake.lua"), [[
target("${TARGET_NAME}")
    set_kind("binary")
    add_files("src/*.c")
]])
    io.writefile(path.join(templatedir, "src", "main.c"), [[
int main(int argc, char** argv) { return 0; }
]])
end

-- write an addon payload directory, it provides a plugin and a template
function _write_addon(dir, name)
    _write_plugin(path.join(dir, "plugins", name), name)
    _write_template(dir, "c", name)
end

-- write an addon package description, its payloads are placed in the `src` directory
--
-- addons in a repository are described as packages, e.g. <repodir>/addons/<first-letter>/<name>/xmake.lua
function _write_addon_package(dir, name)
    io.writefile(path.join(dir, "xmake.lua"), string.format([[
package("%s")
    set_kind("addon")
    set_description("say hello from %s")
    set_sourcedir(path.join(os.scriptdir(), "src"))
]], name, name))
    _write_addon(path.join(dir, "src"), name)
end

-- create a temporary addon repository (packages layout: addons/<first-letter>/<name>) and register it
--
-- @return reponame, names, cleanup
function _mock_repo(basenames)
    local suffix = path.filename(os.tmpfile()):gsub("[^%w]", "")
    local reponame = "addon-test-repo-" .. suffix
    local repodir = os.tmpfile() .. ".addon-repo"
    local names = {}
    for _, base in ipairs(basenames) do
        local name = base .. "-" .. suffix
        _write_addon_package(path.join(repodir, "addons", name:sub(1, 1), name), name)
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
            os.tryrm(path.join(global.directory(), "addons", name))
            try { function () os.runv("xmake", {"addon", "--remove", name}) end }
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

-- install an addon from a repository, by plain name and by repo@name
function test_install_from_repo(t)
    local reponame, names, cleanup = _mock_repo({"hello"})
    local name = names[1]

    -- install by plain name (searched across all repositories)
    os.runv("xmake", {"addon", "--install", "-y", name})
    t:require(os.iorunv("xmake", {name}):find(name, 1, true))

    -- reinstall by repo@name
    os.runv("xmake", {"addon", "--remove", name})
    os.runv("xmake", {"addon", "--install", "-y", reponame .. "@" .. name})
    t:require(os.iorunv("xmake", {name}):find(name, 1, true))

    os.runv("xmake", {"addon", "--remove", name})
    cleanup()
end

-- the templates of an installed addon can be used by `xmake create`
function test_install_templates(t)
    local _, names, cleanup = _mock_repo({"hello"})
    local name = names[1]
    os.runv("xmake", {"addon", "--install", "-y", name})

    -- this template should be listed and grouped by its addon name
    local out = os.iorunv("xmake", {"create", "--list"})
    t:require(out:find(name, 1, true))

    -- we can create a new project from it
    local projectdir = os.tmpfile() .. ".addon-project"
    os.tryrm(projectdir)
    os.runv("xmake", {"create", "-l", "c", "-t", name, "-P", projectdir})
    t:require(os.isfile(path.join(projectdir, "xmake.lua")))
    t:require(os.isfile(path.join(projectdir, "src", "main.c")))

    os.tryrm(projectdir)
    os.runv("xmake", {"addon", "--remove", name})
    cleanup()
end

-- install an addon from a local directory, then remove it
function test_install_from_local(t)
    local suffix = path.filename(os.tmpfile()):gsub("[^%w]", "")
    local name = "hello-local-" .. suffix
    local dir = path.join(os.tmpfile() .. ".addon-local", name)
    _write_addon(dir, name)

    os.runv("xmake", {"addon", "--install", dir})
    t:require(os.iorunv("xmake", {name}):find(name, 1, true))

    -- the removed addon should no longer be runnable
    os.runv("xmake", {"addon", "--remove", name})
    t:require_not(try { function () os.runv("xmake", {name}); return true end })

    os.tryrm(path.directory(dir))
end

-- --list shows the installed and available addons
function test_list(t)
    local _, names, cleanup = _mock_repo({"hello", "world"})

    -- install the first addon, leave the second only available
    os.runv("xmake", {"addon", "--install", "-y", names[1]})
    local out = os.iorunv("xmake", {"addon", "--list"})
    t:require(out:find("the installed addons:", 1, true))
    t:require(out:find(names[1], 1, true))
    t:require(out:find(names[2], 1, true))
    t:require(out:find("xmake addon --install " .. names[2], 1, true))

    -- the payloads of the installed addon should be shown, e.g. (latest, plugins, templates)
    t:require(out:find("plugins", 1, true))
    t:require(out:find("templates", 1, true))

    os.runv("xmake", {"addon", "--remove", names[1]})
    cleanup()
end

-- invalid installs should fail
function test_install_invalid(t)
    t:require_not(try { function () os.runv("xmake", {"addon", "--install", "-y", "addon-test-missing"}); return true end })
    t:require_not(try { function () os.runv("xmake", {"addon", "--install", "-y", "somerepo@.."}); return true end })
end
