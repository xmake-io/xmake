import("core.base.global")

-- the addon fixtures, @see tests/actions/addon/demo-addon
--
-- demo-addon:     the `src` layout, it provides all the payload kinds
-- demo-addon-dep: the plain layout (payloads at the root), it depends on demo-addon
local ADDON     = "demo-addon"
local ADDON_DEP = "demo-addon-dep"

function _addondir(name)
    return path.join(os.scriptdir(), name)
end

function _installdir(name)
    return path.join(global.directory(), "addons", name, "latest")
end

function _remove(name)
    try { function () os.runv("xmake", {"addon", "--remove", "--force", name}) end }
end

-- install the given addon fixture from its local directory
function _install(name)
    _remove(name)
    os.runv("xmake", {"addon", "--install", _addondir(name)})
end

-- run the given function with the addons installed, we always remove them again
function _with_addons(names, func)
    for _, name in ipairs(names) do
        _install(name)
    end
    try
    {
        func,
        finally
        {
            function ()
                for _, name in ipairs(names) do
                    _remove(name)
                end
            end
        }
    }
end

-- create a temporary repository which indexes the addon fixtures, and register it
--
-- @note the recipes only point at the fixtures with `set_sourcedir`, we need not generate any payload
function _with_repo(func)
    local suffix = path.filename(os.tmpfile()):gsub("[^%w]", "")
    local reponame = "addon-test-repo-" .. suffix
    local repodir = os.tmpfile() .. ".addon-repo"
    local recipes = {
        -- the addon itself, its manifest sets the payload root directory, e.g. set_sourcedir("src")
        [ADDON] = ("set_sourcedir(%q)"):format(_addondir(ADDON)),
        -- the addon which depends on the addon above
        [ADDON_DEP] = ("set_sourcedir(%q)\n    add_deps(%q, {kind = \"addon\"})"):format(_addondir(ADDON_DEP), ADDON),
        -- the addon which provides the same plugin and template names as demo-addon
        --
        -- @note it points at the payloads directly, so it has no manifest and no name conflict
        ["demo-addon-clone"] = ("set_sourcedir(%q)"):format(path.join(_addondir(ADDON), "src")),
        -- the addon whose package name does not match the name in its manifest
        ["demo-addon-badname"] = ("set_sourcedir(%q)"):format(_addondir(ADDON))
    }
    for name, body in pairs(recipes) do
        io.writefile(path.join(repodir, "addons", name:sub(1, 1), name, "xmake.lua"),
            ("package(%q)\n    set_kind(\"addon\")\n    set_description(\"the addon fixture of the tests\")\n    %s\n"):format(name, body))
    end

    -- register the repository and clear the quick search cache, it will be rebuilt on the next search
    local cachefile = path.join(global.cachedir(), "repository")
    local cache = os.isfile(cachefile) and io.load(cachefile) or {}
    cache.repositories = cache.repositories or {}
    cache.repositories[reponame] = {repodir}
    io.save(cachefile, cache)
    os.tryrm(path.join(global.cachedir(), "quick_search"))

    try
    {
        function ()
            func(reponame)
        end,
        finally
        {
            function ()
                for name, _ in pairs(recipes) do
                    _remove(name)
                end
                local cache = os.isfile(cachefile) and io.load(cachefile) or {}
                if cache.repositories then
                    cache.repositories[reponame] = nil
                end
                io.save(cachefile, cache)
                os.tryrm(path.join(global.cachedir(), "quick_search"))
                os.tryrm(repodir)
            end
        }
    }
end

-- run `xmake config` in a temporary project and return its output
function _config_project(content)
    local projectdir = os.tmpfile() .. ".addon-project"
    os.tryrm(projectdir)
    io.writefile(path.join(projectdir, "xmake.lua"), content)
    local oldir = os.cd(projectdir)
    local out, errors
    try
    {
        function () out = os.iorunv("xmake", {"config", "-y"}) end,
        catch { function (e) errors = e end },
        finally
        {
            function ()
                os.cd(oldir)
                os.tryrm(projectdir)
            end
        }
    }
    if errors then
        raise(errors)
    end
    return out
end

-- only the payloads should be installed, our own files should not
function test_install(t)
    _with_addons({ADDON}, function ()
        local installdir = _installdir(ADDON)
        for _, payloaddir in ipairs({"plugins", "rules", "toolchains", "modules", "includes", "templates"}) do
            t:require(os.isdir(path.join(installdir, payloaddir)))
        end
        for _, ourfile in ipairs({"src", "tests"}) do
            t:require_not(os.exists(path.join(installdir, ourfile)))
        end
        -- the addon describes itself, we should get its description from the manifest
        t:require(os.iorunv("xmake", {"addon", "--list"}):find("the demo addon of the tests", 1, true))
    end)

    -- it should not be runnable after removing it
    t:require_not(try { function () os.runv("xmake", {"demo_hello"}); return true end })
end

-- all the payload kinds should be activated
function test_payloads(t)
    _with_addons({ADDON}, function ()

        -- the plugin imports a module of its own addon with `@self`
        t:require(os.iorunv("xmake", {"demo_hello", "-n", "xmake"}):find("hello from demo-addon: xmake", 1, true))

        -- the module can be imported with the addon name
        local script = "import(\"@addon.demo-addon.greeting\"); print(greeting(\"module\"))"
        t:require(os.iorunv("xmake", {"lua", "-c", script}):find("hello from demo-addon: module", 1, true))

        -- the toolchain can be loaded with the addon name
        local script2 = "import(\"core.tool.toolchain\"); print(toolchain.load(\"@addon/demo-addon/demo\"):get(\"description\"))"
        t:require(os.iorunv("xmake", {"lua", "-c", script2}):find("the demo toolchain", 1, true))

        -- the template should be listed and can create a project
        t:require(os.iorunv("xmake", {"create", "--list", "-l", "c"}):find("demoaddon.hello", 1, true))
        local projectdir = os.tmpfile() .. ".addon-project"
        os.tryrm(projectdir)
        os.runv("xmake", {"create", "-l", "c", "-t", "demoaddon.hello", "-P", projectdir})
        t:require(os.isfile(path.join(projectdir, "src", "main.c")))
        os.tryrm(projectdir)

        -- the includes and the rules should work in a project, the app rule depends on
        -- the other rule of the same addon with `add_deps("@self/base")`
        local out = _config_project([[
includes("@addon/demo-addon/check")
target("test")
    set_kind("phony")
    add_rules("@addon/demo-addon/app")
]])
        t:require(out:find("demo-addon: includes check is loaded", 1, true))
        t:require(out:find("demo-addon: rule base is loaded", 1, true))
        t:require(out:find("demo-addon: rule app is loaded by the addon(demo-addon), hello from demo-addon: test", 1, true))
    end)
end

-- install the addons from a repository, by plain name and by repo@name
function test_install_from_repo(t)
    _with_repo(function (reponame)
        os.runv("xmake", {"addon", "--install", "-y", ADDON})
        t:require(os.iorunv("xmake", {"demo_hello"}):find("hello from demo-addon", 1, true))

        os.runv("xmake", {"addon", "--remove", ADDON})
        os.runv("xmake", {"addon", "--install", "-y", reponame .. "@" .. ADDON})
        t:require(os.iorunv("xmake", {"demo_hello"}):find("hello from demo-addon", 1, true))

        -- it should be searchable, and the addons should not be found by the package search
        t:require(os.iorunv("xmake", {"addon", "--search", ADDON}):find(ADDON, 1, true))
        t:require_not(os.iorunv("xrepo", {"search", ADDON}):find(ADDON, 1, true))
    end)
end

-- an addon can depend on the other addons, and use their rules and modules
function test_addon_deps(t)
    _with_repo(function ()

        -- installing it should install and activate its addon dependency
        os.runv("xmake", {"addon", "--install", "-y", ADDON_DEP})
        t:require(os.iorunv("xmake", {"addon", "--list"}):find(ADDON, 1, true))

        -- we cannot remove the dependency, it's depended on by the other addon
        t:require_not(try { function () os.runv("xmake", {"addon", "--remove", ADDON}); return true end })

        -- its rule depends on the rule of the other addon and imports its module
        local out = _config_project([[
target("test")
    set_kind("phony")
    add_rules("@addon/demo-addon-dep/dep")
]])
        t:require(out:find("demo-addon: rule base is loaded", 1, true))
        t:require(out:find("demo-addon-dep: hello from demo-addon: dep", 1, true))
    end)
end

-- the plugins and the templates are not namespaced, the conflicts should be rejected when installing
function test_install_conflicts(t)
    _with_repo(function ()
        os.runv("xmake", {"addon", "--install", "-y", ADDON})

        -- this addon provides the same plugin and template names
        t:require_not(try { function () os.runv("xmake", {"addon", "--install", "-y", "demo-addon-clone"}); return true end })

        -- and the other commands should still work
        t:require(os.iorunv("xmake", {"addon", "--list"}):find(ADDON, 1, true))
        t:require(os.iorunv("xmake", {"demo_hello"}):find("hello from demo-addon", 1, true))
    end)
end

-- the invalid installs should fail, and the `addon` name is reserved for the addon references
function test_invalid(t)
    t:require_not(try { function () os.runv("xmake", {"addon", "--install", "-y", "addon-test-missing"}); return true end })

    -- the addon name in its manifest must match the package name which distributes it
    _with_repo(function ()
        t:require_not(try { function () os.runv("xmake", {"addon", "--install", "-y", "demo-addon-badname"}); return true end })
    end)

    t:require_not(try { function () os.runv("xmake", {"addon", "--install", "-y", "somerepo@.."}); return true end })
    t:require_not(try { function () _config_project([[
add_requires("addon")
target("test")
    set_kind("phony")
]]); return true end })
end
